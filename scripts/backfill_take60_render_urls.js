#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * Répare les documents Take60 déjà publiés à partir de take60_renders.
 *
 * Ajoute/rafraîchit :
 * - renderId
 * - videoStoragePath / thumbnailStoragePath
 * - finalVideoStoragePath côté projet
 * - URLs Firebase durables basées sur firebaseStorageDownloadTokens
 *
 * Dry-run par défaut. Ajouter --apply pour écrire.
 */

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const APPLY = process.argv.includes("--apply");
const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "take30";
const SEED_DIR = path.join(__dirname, "seed");

function initAdmin() {
  if (admin.apps.length > 0) return;
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    admin.initializeApp({
      projectId: PROJECT_ID,
      storageBucket: `${PROJECT_ID}.firebasestorage.app`,
    });
    console.log(`🧪 Emulator Firestore @ ${process.env.FIRESTORE_EMULATOR_HOST}`);
    return;
  }

  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localPath = path.join(SEED_DIR, "serviceAccountKey.json");
  const keyPath = envPath && fs.existsSync(envPath) ? envPath : localPath;
  if (!fs.existsSync(keyPath)) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
      storageBucket: `${PROJECT_ID}.firebasestorage.app`,
    });
    console.log(`☁️  Firestore prod @ project=${PROJECT_ID} via Application Default Credentials`);
    return;
  }

  const key = require(keyPath);
  admin.initializeApp({
    credential: admin.credential.cert(key),
    projectId: key.project_id,
    storageBucket: `${key.project_id}.firebasestorage.app`,
  });
  console.log(`☁️  Firestore prod @ project=${key.project_id}`);
}

function asString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function shouldRepairTake(data) {
  return !asString(data.renderId) ||
    !asString(data.videoStoragePath) ||
    !asString(data.thumbnailStoragePath) ||
    !asString(data.videoUrl).startsWith("https://firebasestorage.googleapis.com/") ||
    !asString(data.thumbnailUrl).startsWith("https://firebasestorage.googleapis.com/");
}

function shouldRepairProject(data) {
  return !asString(data.renderId) ||
    !asString(data.finalVideoStoragePath) ||
    !asString(data.thumbnailStoragePath) ||
    !asString(data.finalVideoUrl).startsWith("https://firebasestorage.googleapis.com/") ||
    !asString(data.thumbnailUrl).startsWith("https://firebasestorage.googleapis.com/");
}

async function ensureFirebaseDownloadUrl(bucket, storagePath) {
  const file = bucket.file(storagePath);
  const [exists] = await file.exists();
  if (!exists) {
    return { exists: false, url: "", tokenCreated: false };
  }

  const [metadata] = await file.getMetadata();
  const existingToken = asString(metadata?.metadata?.firebaseStorageDownloadTokens);
  let token = existingToken;
  let tokenCreated = false;

  if (!token) {
    token = crypto.randomUUID();
    tokenCreated = true;
    if (APPLY) {
      await file.setMetadata({
        metadata: {
          ...(metadata?.metadata || {}),
          firebaseStorageDownloadTokens: token,
        },
      });
    }
  }

  const encodedPath = encodeURIComponent(storagePath);
  return {
    exists: true,
    tokenCreated,
    url: `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${token}`,
  };
}

async function repairRenderDocuments() {
  const db = admin.firestore();
  const bucket = admin.storage().bucket();
  const rendersSnap = await db.collection("take60_renders").get();

  let inspected = 0;
  let repairedTakes = 0;
  let repairedProjects = 0;
  let repairedRenders = 0;
  let missingFiles = 0;
  let missingProjectId = 0;
  let createdTokens = 0;

  for (const renderDoc of rendersSnap.docs) {
    inspected += 1;
    const render = renderDoc.data() || {};
    const projectId = asString(render.projectId);
    const userId = asString(render.userId);
    if (!projectId || !userId) {
      missingProjectId += 1;
      continue;
    }

    const renderId = renderDoc.id;
    const videoStoragePath = asString(render.videoStoragePath) || `take60_renders/${userId}/${renderId}.mp4`;
    const thumbnailStoragePath = asString(render.thumbnailStoragePath) || `take60_renders/${userId}/${renderId}.jpg`;

    const videoAsset = await ensureFirebaseDownloadUrl(bucket, videoStoragePath);
    const thumbnailAsset = await ensureFirebaseDownloadUrl(bucket, thumbnailStoragePath);
    if (!videoAsset.exists || !thumbnailAsset.exists) {
      missingFiles += 1;
      continue;
    }
    if (videoAsset.tokenCreated) createdTokens += 1;
    if (thumbnailAsset.tokenCreated) createdTokens += 1;

    const takeRef = db.doc(`takes/${projectId}`);
    const takeSnap = await takeRef.get();
    if (takeSnap.exists && shouldRepairTake(takeSnap.data() || {})) {
      repairedTakes += 1;
      if (APPLY) {
        await takeRef.set({
          renderId,
          videoStoragePath,
          thumbnailStoragePath,
          videoUrl: videoAsset.url,
          thumbnailUrl: thumbnailAsset.url,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }

    const projectRef = db.doc(`take60_guided_projects/${projectId}`);
    const projectSnap = await projectRef.get();
    if (projectSnap.exists && shouldRepairProject(projectSnap.data() || {})) {
      repairedProjects += 1;
      if (APPLY) {
        const existingRenderResult = projectSnap.data()?.renderResult || {};
        await projectRef.set({
          renderId,
          finalVideoStoragePath: videoStoragePath,
          thumbnailStoragePath,
          finalVideoUrl: videoAsset.url,
          thumbnailUrl: thumbnailAsset.url,
          renderResult: {
            ...existingRenderResult,
            renderId,
            videoStoragePath,
            thumbnailStoragePath,
            finalVideoUrl: videoAsset.url,
            thumbnailUrl: thumbnailAsset.url,
          },
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }

    if (APPLY && (!asString(render.videoStoragePath) || !asString(render.thumbnailStoragePath))) {
      repairedRenders += 1;
      await renderDoc.ref.set({
        videoStoragePath,
        thumbnailStoragePath,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }

  console.log(`${APPLY ? "✅" : "🔎"} take60_renders inspectés: ${inspected}`);
  console.log(`${APPLY ? "✅" : "🔎"} takes à réparer: ${repairedTakes}`);
  console.log(`${APPLY ? "✅" : "🔎"} projets guidés à réparer: ${repairedProjects}`);
  console.log(`${APPLY ? "✅" : "🔎"} renders complétés à enrichir: ${repairedRenders}`);
  console.log(`${APPLY ? "✅" : "🔎"} tokens Firebase créés: ${createdTokens}`);
  console.log(`${APPLY ? "✅" : "🔎"} renders ignorés sans projectId/userId: ${missingProjectId}`);
  console.log(`${APPLY ? "✅" : "🔎"} renders ignorés faute de fichiers Storage: ${missingFiles}`);
}

async function main() {
  initAdmin();
  console.log(APPLY ? "⚠️  Mode écriture --apply" : "🔒 Dry-run. Ajoutez --apply pour écrire.");
  await repairRenderDocuments();
}

main().catch((error) => {
  console.error("❌ Backfill Take60 render URLs échoué:", error);
  process.exitCode = 1;
});