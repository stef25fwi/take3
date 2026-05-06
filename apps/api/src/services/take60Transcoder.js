import { spawn } from 'node:child_process';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';

import ffmpegInstaller from '@ffmpeg-installer/ffmpeg';
import { Firestore, FieldValue } from '@google-cloud/firestore';
import { Storage } from '@google-cloud/storage';

import { env } from '../config/env.js';

const firestore = new Firestore();
const storage = new Storage();

const BASE_DESTINATION_PREFIX = 'take60/processed';
const HLS_PLAYLIST_CACHE_CONTROL = 'public, max-age=60';
const HLS_SEGMENT_CACHE_CONTROL = 'public, max-age=31536000, immutable';

function cdnUrlForDestination(destination) {
  if (!env.take60CdnBaseUrl) {
    return null;
  }

  return `${env.take60CdnBaseUrl.replace(/\/+$/, '')}/${destination.replace(/^\/+/, '')}`;
}

function ensureBucketName() {
  if (!env.take60StorageBucket) {
    throw new Error('TAKE60_STORAGE_BUCKET or FIREBASE_STORAGE_BUCKET is required');
  }
  return env.take60StorageBucket;
}

function runFfmpeg(args) {
  return new Promise((resolve, reject) => {
    const child = spawn(ffmpegInstaller.path, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stderr = '';

    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new Error(`ffmpeg exited with code ${code}: ${stderr.slice(-1200)}`));
    });
  });
}

async function transcodeVariant({ inputPath, outputDir, variant }) {
  await fs.mkdir(outputDir, { recursive: true });

  const is720 = variant === '720p';
  const playlistName = `${variant}.m3u8`;
  const segmentPattern = path.join(outputDir, `${variant}_%03d.ts`);
  const playlistPath = path.join(outputDir, playlistName);
  const scale = is720
    ? 'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2'
    : 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2';
  const videoBitrate = is720 ? '2800k' : '5200k';
  const maxRate = is720 ? '3200k' : '6000k';
  const bufferSize = is720 ? '5600k' : '10400k';
  const audioBitrate = is720 ? '128k' : '160k';

  await runFfmpeg([
    '-y',
    '-i', inputPath,
    '-vf', scale,
    '-map', '0:v:0',
    '-map', '0:a?',
    '-c:v', 'libx264',
    '-preset', 'veryfast',
    '-b:v', videoBitrate,
    '-maxrate', maxRate,
    '-bufsize', bufferSize,
    '-c:a', 'aac',
    '-b:a', audioBitrate,
    '-f', 'hls',
    '-hls_time', '4',
    '-hls_playlist_type', 'vod',
    '-hls_segment_filename', segmentPattern,
    playlistPath,
  ]);

  return { playlistName, playlistPath };
}

async function uploadWithFirebaseUrl(bucket, localPath, destination, contentType, cacheControl) {
  const downloadToken = crypto.randomUUID();
  await bucket.upload(localPath, {
    destination,
    metadata: {
      contentType,
      cacheControl,
      metadata: {
        firebaseStorageDownloadTokens: downloadToken,
      },
    },
  });

  const encoded = encodeURIComponent(destination);
  return cdnUrlForDestination(destination) ||
    `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encoded}?alt=media&token=${downloadToken}`;
}

async function saveStringWithFirebaseUrl(bucket, content, destination, contentType, cacheControl) {
  const tempPath = path.join(os.tmpdir(), `${crypto.randomUUID()}-${path.basename(destination)}`);
  await fs.writeFile(tempPath, content, 'utf8');
  try {
    return await uploadWithFirebaseUrl(bucket, tempPath, destination, contentType, cacheControl);
  } finally {
    await fs.rm(tempPath, { force: true });
  }
}

function rewritePlaylistContent(content, replacements) {
  return content
    .split('\n')
    .map((line) => {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) {
        return line;
      }
      return replacements.get(trimmed) || line;
    })
    .join('\n');
}

async function uploadVariantOutputs(bucket, { videoId, variant, outputDir, playlistPath }) {
  const files = await fs.readdir(outputDir);
  const segmentFiles = files.filter((fileName) => fileName.endsWith('.ts')).sort();
  const replacements = new Map();

  for (const segmentFile of segmentFiles) {
    const segmentUrl = await uploadWithFirebaseUrl(
      bucket,
      path.join(outputDir, segmentFile),
      `${BASE_DESTINATION_PREFIX}/${videoId}/${variant}/${segmentFile}`,
      'video/mp2t',
      HLS_SEGMENT_CACHE_CONTROL
    );
    replacements.set(segmentFile, segmentUrl);
  }

  const playlistContent = await fs.readFile(playlistPath, 'utf8');
  const rewrittenPlaylist = rewritePlaylistContent(playlistContent, replacements);
  const playlistUrl = await saveStringWithFirebaseUrl(
    bucket,
    rewrittenPlaylist,
    `${BASE_DESTINATION_PREFIX}/${videoId}/${variant}/${variant}.m3u8`,
    'application/vnd.apple.mpegurl',
    HLS_PLAYLIST_CACHE_CONTROL
  );

  return playlistUrl;
}

function buildMasterPlaylist({ playlist720Url, playlist1080Url }) {
  return [
    '#EXTM3U',
    '#EXT-X-VERSION:3',
    '#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720',
    playlist720Url,
    '#EXT-X-STREAM-INF:BANDWIDTH=5200000,RESOLUTION=1920x1080',
    playlist1080Url,
    '',
  ].join('\n');
}

export async function transcodeTake60Video(videoId) {
  const videoRef = firestore.collection('take60_videos').doc(videoId);
  const videoSnap = await videoRef.get();
  if (!videoSnap.exists) {
    throw new Error(`take60_videos/${videoId} not found`);
  }

  const video = videoSnap.data() || {};
  const rawStoragePath = String(video.rawStoragePath || '').trim();
  if (!rawStoragePath) {
    throw new Error(`take60_videos/${videoId} has no rawStoragePath`);
  }

  const bucket = storage.bucket(ensureBucketName());
  const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'take60-hls-'));
  const inputPath = path.join(tempRoot, 'input.mp4');
  const output720Dir = path.join(tempRoot, '720p');
  const output1080Dir = path.join(tempRoot, '1080p');

  await videoRef.set(
    {
      status: 'processing',
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  try {
    await bucket.file(rawStoragePath).download({ destination: inputPath });

    const [variant720, variant1080] = await Promise.all([
      transcodeVariant({ inputPath, outputDir: output720Dir, variant: '720p' }),
      transcodeVariant({ inputPath, outputDir: output1080Dir, variant: '1080p' }),
    ]);

    const playlist720Url = await uploadVariantOutputs(bucket, {
      videoId,
      variant: '720p',
      outputDir: output720Dir,
      playlistPath: variant720.playlistPath,
    });
    const playlist1080Url = await uploadVariantOutputs(bucket, {
      videoId,
      variant: '1080p',
      outputDir: output1080Dir,
      playlistPath: variant1080.playlistPath,
    });

    const masterUrl = await saveStringWithFirebaseUrl(
      bucket,
      buildMasterPlaylist({ playlist720Url, playlist1080Url }),
      `${BASE_DESTINATION_PREFIX}/${videoId}/master.m3u8`,
      'application/vnd.apple.mpegurl',
      HLS_PLAYLIST_CACHE_CONTROL
    );

    await videoRef.set(
      {
        status: 'ready',
        hlsBaseUrl: playlist720Url,
        hlsPremiumUrl: playlist1080Url,
        hlsMasterUrl: masterUrl,
        qualityBase: '720p',
        premiumQuality: '1080p',
        isPremiumLocked: true,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const sceneId = String(video.sceneId || '').trim();
    if (sceneId) {
      await firestore.collection('scenes').doc(sceneId).set(
        {
          take60VideoId: videoId,
          videoUrl: playlist720Url,
          hlsBaseUrl: playlist720Url,
          hlsPremiumUrl: playlist1080Url,
          hlsMasterUrl: masterUrl,
          videoProcessingStatus: 'ready',
          isPremiumLocked: true,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    return {
      videoId,
      hlsBaseUrl: playlist720Url,
      hlsPremiumUrl: playlist1080Url,
      hlsMasterUrl: masterUrl,
      status: 'ready',
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown transcode error';
    await videoRef.set(
      {
        status: 'failed',
        errorMessage: message,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const sceneId = String(video.sceneId || '').trim();
    if (sceneId) {
      await firestore.collection('scenes').doc(sceneId).set(
        {
          videoProcessingStatus: 'failed',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
    throw error;
  } finally {
    await fs.rm(tempRoot, { recursive: true, force: true });
  }
}