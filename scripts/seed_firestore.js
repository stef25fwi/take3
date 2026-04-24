#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * Seed Firestore pour Take30.
 *
 * Pré-requis :
 *   1. `npm install` dans le dossier scripts/ (ou à la racine).
 *   2. Placer le `serviceAccountKey.json` (Firebase Admin) dans scripts/seed/.
 *   3. Optionnel : variables d'env FIRESTORE_EMULATOR_HOST=localhost:8080 pour cibler l'émulateur.
 *
 * Usage :
 *   node scripts/seed_firestore.js          # idempotent (ne recrée pas si doc existe)
 *   node scripts/seed_firestore.js --force  # efface puis réécrit toutes les collections seed
 */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const SEED_DIR = path.join(__dirname, "seed");
const FORCE = process.argv.includes("--force");
const AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST;

function loadJson(name) {
  const file = path.join(SEED_DIR, `${name}.json`);
  if (!fs.existsSync(file)) return [];
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function initAdmin() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || "take30" });
    console.log(`🧪 Emulator mode @ ${process.env.FIRESTORE_EMULATOR_HOST}`);
    return;
  }

  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localPath = path.join(SEED_DIR, "serviceAccountKey.json");
  const keyPath = envPath && fs.existsSync(envPath) ? envPath : localPath;

  if (!fs.existsSync(keyPath)) {
    console.error(
      "❌ Service account introuvable. Déposez le JSON dans scripts/seed/serviceAccountKey.json " +
        "ou exposez GOOGLE_APPLICATION_CREDENTIALS."
    );
    process.exit(1);
  }
  const key = require(keyPath);
  admin.initializeApp({
    credential: admin.credential.cert(key),
    projectId: key.project_id,
  });
  console.log(`☁️  Prod mode @ project=${key.project_id} (key=${path.basename(keyPath)})`);
}

async function clearCollection(db, colPath) {
  const snap = await db.collection(colPath).get();
  const batch = db.batch();
  snap.forEach((d) => batch.delete(d.ref));
  if (!snap.empty) await batch.commit();
  console.log(`🧹 cleared ${colPath} (${snap.size} docs)`);
}

async function upsert(db, colPath, items, idField = "id") {
  const col = db.collection(colPath);
  let written = 0;
  for (const item of items) {
    const id = item[idField];
    if (!id) continue;
    const ref = col.doc(id);
    if (!FORCE) {
      const existing = await ref.get();
      if (existing.exists) continue;
    }
    const { [idField]: _, authPassword: __, ...payload } = item;
    await ref.set(payload);
    written++;
  }
  console.log(`✅ ${colPath}: ${written} docs written`);
}

async function syncAuthUsers(users) {
  let written = 0;
  for (const user of users) {
    const email = typeof user.email === "string" ? user.email.trim() : "";
    const password = typeof user.authPassword === "string" ? user.authPassword : "";
    const uid = typeof user.id === "string" ? user.id : "";
    if (!email || !password || !uid) {
      continue;
    }

    const payload = {
      uid,
      email,
      password,
      displayName: user.displayName || user.username || uid,
      emailVerified: true,
      disabled: false,
    };

    try {
      await admin.auth().updateUser(uid, payload);
    } catch (error) {
      if (error?.code === "auth/user-not-found") {
        await admin.auth().createUser(payload);
      } else {
        throw error;
      }
    }

    if (user.isAdmin) {
      await admin.auth().setCustomUserClaims(uid, { admin: true });
    } else {
      await admin.auth().setCustomUserClaims(uid, null);
    }
    written++;
  }

  const target = AUTH_EMULATOR_HOST ? `auth emulator @ ${AUTH_EMULATOR_HOST}` : "Firebase Auth";
  console.log(`🔐 ${target}: ${written} user(s) synced`);
}

async function main() {
  initAdmin();
  const db = admin.firestore();

  const categories = loadJson("categories");
  const users = loadJson("users");
  const scenes = loadJson("scenes");
  const badges = loadJson("badges");
  const duel = loadJson("duel");
  const daily = loadJson("dailyChallenge");
  const leaderboard = loadJson("leaderboard");

  if (FORCE) {
    await clearCollection(db, "categories");
    await clearCollection(db, "scenes");
    await clearCollection(db, "duels");
    await clearCollection(db, "dailyChallenges");
    await clearCollection(db, "users");
  }

  await upsert(db, "categories", categories);
  await upsert(db, "users", users);
  await syncAuthUsers(users);
  await upsert(db, "scenes", scenes);

  // Badges sont imbriqués sous users/{uid}/badges
  for (const b of badges) {
    const uid = b.userId;
    if (!uid) continue;
    await db.doc(`users/${uid}/badges/${b.id}`).set(
      Object.fromEntries(Object.entries(b).filter(([k]) => k !== "userId" && k !== "id"))
    );
  }
  console.log(`🏅 badges: ${badges.length} imbriqués`);

  if (duel.length > 0) {
    await upsert(db, "duels", duel);
  }

  if (daily.length > 0) {
    const key = new Date().toISOString().slice(0, 10);
    await db.doc(`dailyChallenges/${key}`).set(daily[0]);
    console.log(`📅 dailyChallenges/${key} écrit`);
  }

  if (leaderboard.length > 0) {
    for (const period of ["day", "week", "month", "global"]) {
      const col = db.collection(`leaderboards/${period}/entries`);
      const existing = await col.get();
      const batch = db.batch();
      existing.forEach((d) => batch.delete(d.ref));
      leaderboard.forEach((e, i) => {
        batch.set(col.doc(e.id), {
          rank: i + 1,
          userDenorm: {
            id: e.id,
            username: e.username,
            avatarUrl: e.avatarUrl,
            isVerified: Boolean(e.isVerified),
          },
          score: e.score ?? 0,
          scenesCount: e.scenesCount ?? 0,
          period,
        });
      });
      await batch.commit();
    }
    console.log(`🏆 leaderboards initialisés pour day/week/month/global`);
  }

  console.log("🎉 Seed terminé.");
  process.exit(0);
}

main().catch((err) => {
  console.error("💥 Seed failed:", err);
  process.exit(1);
});
