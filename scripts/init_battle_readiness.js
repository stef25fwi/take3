#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * Initialise les données Battle sur des données réelles existantes.
 *
 * Ce script ne crée pas de faux workflow admin et n'injecte pas de Battle mockée :
 * - userBattleStats/{uid} est dérivé des documents users/{uid} existants.
 * - scenes/{sceneId}.battleEnabled est activé uniquement sur des scènes admin réelles publiées.
 *
 * Sécurité : dry-run par défaut. Ajouter --apply pour écrire.
 *
 * Usage :
 *   node scripts/init_battle_readiness.js
 *   node scripts/init_battle_readiness.js --apply
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 node scripts/init_battle_readiness.js --apply
 */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const APPLY = process.argv.includes("--apply");
const ONLY_USERS = process.argv.includes("--users-only");
const ONLY_SCENES = process.argv.includes("--scenes-only");
const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "take30";
const SEED_DIR = path.join(__dirname, "seed");

function initAdmin() {
  if (admin.apps.length > 0) return;
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    admin.initializeApp({ projectId: PROJECT_ID });
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
    });
    console.log(`☁️  Firestore prod @ project=${PROJECT_ID} via Application Default Credentials`);
    return;
  }
  const key = require(keyPath);
  admin.initializeApp({ credential: admin.credential.cert(key), projectId: key.project_id });
  console.log(`☁️  Firestore prod @ project=${key.project_id}`);
}

function readNumber(data, keys, fallback = 0) {
  for (const key of keys) {
    const value = data[key];
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string" && value.trim() !== "") {
      const parsed = Number(value);
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return fallback;
}

function battleTierFor(avg, count) {
  if (count < 3 || avg <= 0) return "Rookie";
  if (avg >= 85) return "Gold";
  if (avg >= 70) return "Silver";
  return "Bronze";
}

function deriveStats(uid, user) {
  const ratingAvg = readNumber(user, [
    "battleRatingAvg",
    "ratingAvg",
    "ratingAverage",
    "averageRating",
    "approvalRate",
  ]);
  const ratingCount = Math.max(
    0,
    Math.round(readNumber(user, [
      "battleRatingCount",
      "ratingCount",
      "ratingsCount",
      "takesRatedCount",
      "scenesCount",
    ]))
  );
  const existingBadges = Array.isArray(user.badges)
    ? user.badges.map((badge) => String(badge))
    : [];

  return {
    uid,
    ratingAvg,
    ratingCount,
    battleRatingTier: user.battleRatingTier || battleTierFor(ratingAvg, ratingCount),
    battlesPlayed: readNumber(user, ["battlesPlayed"], 0),
    battlesWon: readNumber(user, ["battlesWon"], 0),
    battlesLost: readNumber(user, ["battlesLost"], 0),
    battlesDraw: readNumber(user, ["battlesDraw"], 0),
    winStreak: readNumber(user, ["winStreak"], 0),
    bestWinStreak: readNumber(user, ["bestWinStreak", "winStreak"], 0),
    activeBattlesCount: readNumber(user, ["activeBattlesCount"], 0),
    pendingChallengesCount: readNumber(user, ["pendingChallengesCount"], 0),
    challengesSentThisWeek: readNumber(user, ["challengesSentThisWeek"], 0),
    battlesCreatedThisWeek: readNumber(user, ["battlesCreatedThisWeek"], 0),
    followersGainedFromBattles: readNumber(user, ["followersGainedFromBattles"], 0),
    badges: existingBadges,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function initialiseUserBattleStats(db) {
  const usersSnap = await db.collection("users").get();
  let created = 0;
  let merged = 0;
  let skipped = 0;
  const writes = [];

  for (const doc of usersSnap.docs) {
    const uid = doc.id;
    const user = doc.data() || {};
    if (user.deleted === true || user.disabled === true) {
      skipped++;
      continue;
    }
    const statsRef = db.doc(`userBattleStats/${uid}`);
    const statsSnap = await statsRef.get();
    const payload = deriveStats(uid, user);
    if (statsSnap.exists) merged++; else created++;
    writes.push({ ref: statsRef, payload });
  }

  if (APPLY) {
    await commitInChunks(db, writes);
  }
  console.log(`${APPLY ? "✅" : "🔎"} userBattleStats: ${created} à créer, ${merged} à fusionner, ${skipped} ignoré(s)`);
}

function sceneIsBattleReady(scene) {
  const status = scene.status || scene.publicationStatus;
  const duration = readNumber(scene, ["durationSeconds", "duration", "aiDurationSeconds"], 60);
  return scene.adminWorkflow === true &&
    status === "published" &&
    duration <= 90 &&
    Boolean(
      scene.videoUrl ||
        scene.aiIntroVideo?.videoUrl ||
        scene.directorInstructions ||
        scene.dialogueText ||
        scene.actorSheet?.actingTextOrInstructions
    );
}

function battleScenePayload(scene) {
  const category = scene.category || scene.genre || "Interprétation";
  const difficulty = scene.battleDifficultyTier || scene.difficulty || scene.level || "intermediaire";
  const themes = Array.isArray(scene.battleThemes) && scene.battleThemes.length > 0
    ? scene.battleThemes.map((theme) => String(theme))
    : [category, scene.genre].filter(Boolean).map((theme) => String(theme));
  return {
    battleEnabled: true,
    battleThemes: themes,
    battleDifficultyTier: difficulty,
    battleCategory: scene.battleCategory || category,
    isEligibleForRandomBattleDraw: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function activateBattleScenes(db) {
  const snap = await db.collection("scenes")
    .where("adminWorkflow", "==", true)
    .where("status", "==", "published")
    .get();
  const writes = [];
  let alreadyEnabled = 0;
  let activated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const scene = doc.data() || {};
    if (!sceneIsBattleReady(scene)) {
      skipped++;
      continue;
    }
    if (scene.battleEnabled === true && scene.isEligibleForRandomBattleDraw === true) {
      alreadyEnabled++;
      continue;
    }
    activated++;
    writes.push({ ref: doc.ref, payload: battleScenePayload(scene) });
  }

  if (APPLY) {
    await commitInChunks(db, writes);
  }
  console.log(`${APPLY ? "✅" : "🔎"} scènes battleEnabled: ${activated} à activer, ${alreadyEnabled} déjà prêtes, ${skipped} ignorée(s)`);
}

async function commitInChunks(db, writes) {
  for (let index = 0; index < writes.length; index += 450) {
    const batch = db.batch();
    for (const write of writes.slice(index, index + 450)) {
      batch.set(write.ref, write.payload, { merge: true });
    }
    await batch.commit();
  }
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  console.log(APPLY ? "⚠️  Mode écriture --apply" : "🔒 Dry-run. Ajoutez --apply pour écrire.");

  if (!ONLY_SCENES) {
    await initialiseUserBattleStats(db);
  }
  if (!ONLY_USERS) {
    await activateBattleScenes(db);
  }
  console.log("🎬 Préparation Battle terminée.");
}

main().catch((error) => {
  console.error(`💥 init_battle_readiness failed: ${error.message}`);
  process.exit(1);
});
