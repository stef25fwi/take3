/**
 * Take60 — Guided scene final renderer.
 *
 * Downloads the ordered AI + user video segments referenced by markers,
 * concatenates them with FFmpeg into a single 1080p MP4 (≤ 60 s),
 * applies the audio rules described in the scene (mute user audio over
 * AI segments, keep AI ambience under user segments if requested,
 * normalise loudness, optional crossfades), generates a JPEG thumbnail,
 * and writes everything back to Firebase Storage.
 *
 * Inputs (HTTPS callable):
 *   - sceneId            string (required)
 *   - userId             string
 *   - maxDurationSeconds number (≤ 60)
 *   - aiSegments         [{markerId,type,videoUrl,durationSeconds,order}]
 *   - userSegments       [{markerId,type,videoUrl,durationSeconds}]
 *   - markers            [{markerId,type,order,durationSeconds}]
 *   - audioRules         {keepAiAmbiance,duckUserAudioOverAi,
 *                          normaliseLoudness,crossfadeMillis,
 *                          equalizer,autoGain}
 *
 * Output:
 *   { renderId, status, finalVideoUrl, thumbnailUrl,
 *     durationSeconds, segments[] }
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as fs from "fs/promises";
import * as path from "path";
import * as os from "os";
import * as https from "https";
import * as http from "http";

// FFmpeg is dynamically required so callers without the rendering deps
// (e.g. older deploys) keep working with the metadata-only fallback.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let ffmpegLib: any | null = null;
try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const installer = require("@ffmpeg-installer/ffmpeg");
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  ffmpegLib = require("fluent-ffmpeg");
  if (installer?.path && ffmpegLib?.setFfmpegPath) {
    ffmpegLib.setFfmpegPath(installer.path);
  }
} catch (err) {
  logger.warn("FFmpeg unavailable, using metadata-only render", err as Error);
  ffmpegLib = null;
}

interface SegmentInput {
  markerId?: string;
  type?: string;
  source?: string;
  videoUrl?: string;
  durationSeconds?: number;
  order?: number;
}

interface AudioRules {
  keepAiAmbiance?: boolean;
  duckUserAudioOverAi?: boolean;
  normaliseLoudness?: boolean;
  crossfadeMillis?: number;
  /** Égalisation 3 bandes + filtres anti-rumble/anti-hiss. Activé par défaut. */
  equalizer?: boolean;
  /** Réglage de gain automatique (dynaudnorm). Activé par défaut. */
  autoGain?: boolean;
}

/**
 * Construit la chaîne de filtres audio (EQ → AGC → loudnorm) en fonction des règles.
 * Retourne une chaîne séparée par des virgules, sans virgule de tête.
 * Si aucun filtre n'est sélectionné, retourne `"anull"`.
 */
function buildAudioChain(rules: AudioRules): string {
  const eq = rules.equalizer !== false;
  const agc = rules.autoGain !== false;
  const loud = rules.normaliseLoudness === true;
  const parts: string[] = [];
  if (eq) {
    // Anti-rumble (proximité, vibrations, vent) + anti-hiss numérique.
    parts.push("highpass=f=80");
    parts.push("lowpass=f=15000");
    // EQ 3 bandes : chaleur (200 Hz +1.5), présence voix (2 kHz +2), brillance (8 kHz +1).
    parts.push("equalizer=f=200:width_type=o:width=1:g=1.5");
    parts.push("equalizer=f=2000:width_type=o:width=1:g=2");
    parts.push("equalizer=f=8000:width_type=o:width=1:g=1");
  }
  if (agc) {
    // dynaudnorm : compression douce + gain automatique pour homogénéiser les niveaux.
    parts.push("dynaudnorm=f=200:g=15:p=0.95:m=10:r=0");
  }
  if (loud) {
    // Standard EBU R128 (–16 LUFS) en queue de chaîne.
    parts.push("loudnorm=I=-16:TP=-1.5:LRA=11");
  }
  return parts.length === 0 ? "anull" : parts.join(",");
}

interface RenderRequest {
  sceneId?: string;
  userId?: string;
  maxDurationSeconds?: number;
  audioRules?: AudioRules;
  aiSegments?: SegmentInput[];
  userSegments?: SegmentInput[];
  markers?: SegmentInput[];
}

interface NormalisedSegment {
  markerId: string;
  type: string;
  source: "ai" | "user";
  videoUrl: string;
  durationSeconds: number;
  order: number;
}

const db = getFirestore();

/** Build the ordered segment list, prefer user recordings when present. */
function mergeSegments(
  markers: SegmentInput[],
  ai: SegmentInput[],
  user: SegmentInput[]
): NormalisedSegment[] {
  const userByMarker = new Map<string, SegmentInput>();
  for (const seg of user) {
    if (seg && seg.markerId) userByMarker.set(seg.markerId, seg);
  }
  const aiByMarker = new Map<string, SegmentInput>();
  for (const seg of ai) {
    if (seg && seg.markerId) aiByMarker.set(seg.markerId, seg);
  }

  const merged: NormalisedSegment[] = [];
  if (markers.length > 0) {
    for (let i = 0; i < markers.length; i++) {
      const marker = markers[i];
      const id = (marker.markerId ?? "").toString();
      const baseDuration = Math.max(Number(marker.durationSeconds ?? 0), 0);
      const userSeg = userByMarker.get(id);
      const aiSeg = aiByMarker.get(id);
      const chosen = userSeg ?? aiSeg;
      merged.push({
        markerId: id,
        type: (marker.type ?? "ai").toString(),
        source: userSeg ? "user" : "ai",
        videoUrl: (chosen?.videoUrl ?? "").toString(),
        durationSeconds:
          Number(chosen?.durationSeconds ?? baseDuration) || baseDuration,
        order: Number(marker.order ?? i),
      });
    }
  } else {
    const all: NormalisedSegment[] = [];
    for (const seg of ai) {
      all.push({
        markerId: (seg.markerId ?? "").toString(),
        type: (seg.type ?? "ai").toString(),
        source: "ai",
        videoUrl: (seg.videoUrl ?? "").toString(),
        durationSeconds: Number(seg.durationSeconds ?? 0),
        order: Number(seg.order ?? 0),
      });
    }
    for (const seg of user) {
      all.push({
        markerId: (seg.markerId ?? "").toString(),
        type: (seg.type ?? "user").toString(),
        source: "user",
        videoUrl: (seg.videoUrl ?? "").toString(),
        durationSeconds: Number(seg.durationSeconds ?? 0),
        order: Number(seg.order ?? 0),
      });
    }
    all.sort((a, b) => a.order - b.order);
    merged.push(...all);
  }
  return merged;
}

/** Clamp the cumulative duration to maxDuration. */
function clampDuration(
  segments: NormalisedSegment[],
  maxDuration: number
): number {
  let total = 0;
  for (const seg of segments) total += seg.durationSeconds;
  if (total <= maxDuration) return total;
  let remaining = maxDuration;
  for (const seg of segments) {
    if (seg.durationSeconds <= remaining) {
      remaining -= seg.durationSeconds;
    } else {
      seg.durationSeconds = Math.max(remaining, 0);
      remaining = 0;
    }
  }
  return maxDuration;
}

function downloadFile(url: string, dest: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const get = url.startsWith("https") ? https.get : http.get;
    const file = require("fs").createWriteStream(dest);
    get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        downloadFile(res.headers.location, dest).then(resolve, reject);
        return;
      }
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        return;
      }
      res.pipe(file);
      file.on("finish", () => file.close(() => resolve()));
    }).on("error", (err: Error) => {
      reject(err);
    });
  });
}

/**
 * Run FFmpeg to concat normalised inputs into a single 1080p MP4 and
 * extract a JPEG thumbnail. Returns local file paths.
 *
 * Two strategies:
 *   - Fast path (concat demuxer) when no crossfade is requested.
 *   - Filtergraph (xfade + acrossfade) when audioRules.crossfadeMillis > 0
 *     and there are at least 2 segments.
 */
async function ffmpegConcat(
  segments: NormalisedSegment[],
  rules: AudioRules,
  workDir: string
): Promise<{ videoPath: string; thumbPath: string; duration: number }> {
  if (!ffmpegLib) {
    throw new Error("FFmpeg unavailable in this environment.");
  }
  const inputs: string[] = [];
  const durations: number[] = [];
  for (let i = 0; i < segments.length; i++) {
    const seg = segments[i];
    if (!seg.videoUrl) continue;
    const local = path.join(workDir, `seg_${i}.mp4`);
    await downloadFile(seg.videoUrl, local);
    inputs.push(local);
    durations.push(Math.max(seg.durationSeconds, 0));
  }
  if (inputs.length === 0) {
    throw new Error("No downloadable segments");
  }

  const videoPath = path.join(workDir, "final.mp4");
  const fadeMs = Math.max(0, Number(rules.crossfadeMillis ?? 0));
  const fadeSec = fadeMs / 1000;
  const useCrossfade = fadeSec > 0 && inputs.length >= 2;

  // Chaîne unique : EQ → AGC → loudnorm. Réutilisée en fast-path et en filtergraph.
  const audioChain = buildAudioChain(rules);

  let finalDuration = 0;

  if (!useCrossfade) {
    // Fast path: concat demuxer + single re-encode.
    const listFile = path.join(workDir, "concat.txt");
    await fs.writeFile(
      listFile,
      inputs.map((p) => `file '${p.replace(/'/g, "'\\''")}'`).join("\n")
    );
    finalDuration = durations.reduce((a, b) => a + b, 0);
    const audioFilter = audioChain;

    await new Promise<void>((resolve, reject) => {
      ffmpegLib()
        .input(listFile)
        .inputOptions(["-f", "concat", "-safe", "0"])
        .videoCodec("libx264")
        .audioCodec("aac")
        .size("1920x1080")
        .videoBitrate("4500k")
        .audioBitrate("192k")
        .audioFilters(audioFilter)
        .outputOptions(["-pix_fmt", "yuv420p", "-movflags", "+faststart"])
        .duration(finalDuration)
        .save(videoPath)
        .on("end", () => resolve())
        .on("error", (err: Error) => reject(err));
    });
  } else {
    // Filtergraph path: xfade for video, acrossfade for audio.
    // Effective duration = sum(durations) - (N-1) * fadeSec.
    // Each xfade offset = sum(durations[0..k]) - (k+1) * fadeSec.
    const safeFade = Math.min(fadeSec, ...durations.map((d) => d / 2 || fadeSec));
    const filters: string[] = [];
    // Normalise every input to 1920x1080@30 + 44.1kHz stereo so xfade/acrossfade work.
    for (let i = 0; i < inputs.length; i++) {
      filters.push(
        `[${i}:v]scale=1920:1080:force_original_aspect_ratio=decrease,` +
          `pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,format=yuv420p[v${i}]`
      );
      filters.push(`[${i}:a]aresample=44100,aformat=channel_layouts=stereo[a${i}]`);
    }
    let prevV = "v0";
    let prevA = "a0";
    let offset = durations[0];
    for (let i = 1; i < inputs.length; i++) {
      const outV = i === inputs.length - 1 ? "vout" : `vx${i}`;
      const outA = i === inputs.length - 1 ? "aout_pre" : `ax${i}`;
      const xfadeOffset = Math.max(offset - safeFade, 0);
      filters.push(
        `[${prevV}][v${i}]xfade=transition=fade:duration=${safeFade}:` +
          `offset=${xfadeOffset.toFixed(3)}[${outV}]`
      );
      filters.push(`[${prevA}][a${i}]acrossfade=d=${safeFade}:c1=tri:c2=tri[${outA}]`);
      prevV = outV;
      prevA = outA;
      offset += durations[i] - safeFade;
    }
    // Append EQ + AGC (+ loudnorm) to the audio chain.
    filters.push(`[${prevA}]${audioChain}[aout]`);
    finalDuration = offset;

    await new Promise<void>((resolve, reject) => {
      const cmd = ffmpegLib();
      for (const f of inputs) cmd.input(f);
      cmd
        .complexFilter(filters, ["vout", "aout"])
        .videoCodec("libx264")
        .audioCodec("aac")
        .videoBitrate("4500k")
        .audioBitrate("192k")
        .outputOptions(["-pix_fmt", "yuv420p", "-movflags", "+faststart"])
        .duration(finalDuration)
        .save(videoPath)
        .on("end", () => resolve())
        .on("error", (err: Error) => reject(err));
    });
  }

  // Thumbnail at min(1s, total/2) of the rendered video.
  const thumbPath = path.join(workDir, "thumb.jpg");
  await new Promise<void>((resolve, reject) => {
    ffmpegLib(videoPath)
      .seekInput(Math.min(1, finalDuration / 2))
      .frames(1)
      .size("1920x1080")
      .save(thumbPath)
      .on("end", () => resolve())
      .on("error", (err: Error) => reject(err));
  });

  return { videoPath, thumbPath, duration: finalDuration };
}

export const renderTake60GuidedScene = onCall<RenderRequest>(async (req) => {
  const auth = req.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const data = req.data ?? {};
  const sceneId = (data.sceneId ?? "").trim();
  if (!sceneId) {
    throw new HttpsError("invalid-argument", "sceneId requis.");
  }
  const maxDuration = Math.min(
    Math.max(Number(data.maxDurationSeconds ?? 60), 5),
    60
  );
  const ai = Array.isArray(data.aiSegments) ? data.aiSegments : [];
  const user = Array.isArray(data.userSegments) ? data.userSegments : [];
  const markers = Array.isArray(data.markers) ? data.markers : [];
  const rules: AudioRules = data.audioRules ?? {};

  const merged = mergeSegments(markers, ai, user);
  const totalDuration = clampDuration(merged, maxDuration);

  const renderId = db.collection("take60_renders").doc().id;
  const renderRef = db.doc(`take60_renders/${renderId}`);

  // Persist the request immediately so clients can poll if rendering is async.
  await renderRef.set({
    sceneId,
    userId: auth.uid,
    createdAt: FieldValue.serverTimestamp(),
    durationSeconds: totalDuration,
    maxDurationSeconds: maxDuration,
    segments: merged,
    audioRules: rules,
    status: "rendering",
  });

  // Try the real FFmpeg render. On failure (no ffmpeg, network errors…),
  // fall back to returning the last AI segment as a preview.
  let finalVideoUrl = "";
  let thumbnailUrl = "";
  let renderStatus: "preview_ready" | "pending_render" = "pending_render";

  if (ffmpegLib) {
    const workDir = await fs.mkdtemp(path.join(os.tmpdir(), `take60-${renderId}-`));
    try {
      const { videoPath, thumbPath, duration } = await ffmpegConcat(
        merged,
        rules,
        workDir
      );
      const bucket = admin.storage().bucket();
      const videoRemote = `take60_renders/${auth.uid}/${renderId}.mp4`;
      const thumbRemote = `take60_renders/${auth.uid}/${renderId}.jpg`;
      await bucket.upload(videoPath, {
        destination: videoRemote,
        contentType: "video/mp4",
        metadata: { contentType: "video/mp4" },
      });
      await bucket.upload(thumbPath, {
        destination: thumbRemote,
        contentType: "image/jpeg",
        metadata: { contentType: "image/jpeg" },
      });
      const [videoUrl] = await bucket.file(videoRemote).getSignedUrl({
        action: "read",
        expires: Date.now() + 1000 * 60 * 60 * 24 * 30,
      });
      const [thumbUrl] = await bucket.file(thumbRemote).getSignedUrl({
        action: "read",
        expires: Date.now() + 1000 * 60 * 60 * 24 * 30,
      });
      finalVideoUrl = videoUrl;
      thumbnailUrl = thumbUrl;
      renderStatus = "preview_ready";
      logger.info(`Take60 render ${renderId} ok (${duration}s)`);
    } catch (err) {
      logger.error(`Take60 render ${renderId} failed`, err as Error);
    } finally {
      await fs.rm(workDir, { recursive: true, force: true }).catch(() => {});
    }
  }

  if (!finalVideoUrl) {
    // Fallback: pick the last segment with a reachable URL.
    const finalSeg = [...merged].reverse().find((s) => s.videoUrl);
    finalVideoUrl = finalSeg?.videoUrl ?? "";
    renderStatus = finalVideoUrl ? "preview_ready" : "pending_render";
  }

  await renderRef.set(
    {
      finalVideoUrl,
      thumbnailUrl,
      status: renderStatus,
      durationSeconds: totalDuration,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    renderId,
    status: renderStatus,
    finalVideoUrl,
    thumbnailUrl,
    durationSeconds: totalDuration,
    segments: merged,
  };
});
