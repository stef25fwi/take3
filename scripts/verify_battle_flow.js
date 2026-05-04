#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * Vérifie un parcours Battle complet contre les émulateurs Firebase.
 *
 * Pré-requis : lancer les émulateurs Auth, Firestore et Functions.
 * Exemple : npx firebase-tools emulators:start --only firestore,auth,functions,storage
 *
 * Ce script crée uniquement des données de test en émulateur.
 */

const admin = require("firebase-admin");

const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "take30";
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "localhost:9099";
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST || "localhost:8080";
const FUNCTIONS_ORIGIN = process.env.FUNCTIONS_EMULATOR_ORIGIN || `http://localhost:5001/${PROJECT_ID}/europe-west1`;

const challenger = {
  uid: "battle_flow_challenger",
  email: "battle.challenger@take60.local",
  password: "BattleFlow2026!",
  displayName: "Alex Battle",
};
const opponent = {
  uid: "battle_flow_opponent",
  email: "battle.opponent@take60.local",
  password: "BattleFlow2026!",
  displayName: "Clara Battle",
};
const voter = {
  uid: "battle_flow_voter",
  email: "battle.voter@take60.local",
  password: "BattleFlow2026!",
  displayName: "Sam Voter",
};

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || payload.error) {
    throw new Error(`HTTP ${response.status} ${url}: ${JSON.stringify(payload)}`);
  }
  return payload;
}

async function ensureAuthUser(user) {
  try {
    await admin.auth().updateUser(user.uid, {
      email: user.email,
      password: user.password,
      displayName: user.displayName,
      emailVerified: true,
      disabled: false,
    });
  } catch (error) {
    if (error?.code !== "auth/user-not-found") throw error;
    await admin.auth().createUser({
      uid: user.uid,
      email: user.email,
      password: user.password,
      displayName: user.displayName,
      emailVerified: true,
      disabled: false,
    });
  }
}

async function signIn(user) {
  const url = `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`;
  const payload = await fetchJson(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: user.email, password: user.password, returnSecureToken: true }),
  });
  assert(payload.localId === user.uid, `uid inattendu pour ${user.email}`);
  return payload.idToken;
}

async function callFunction(name, token, data) {
  const payload = await fetchJson(`${FUNCTIONS_ORIGIN}/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ data }),
  });
  return payload.result;
}

async function seedEmulatorData(db) {
  const rivalryPairKey = [challenger.uid, opponent.uid].sort().join("_");
  const previousBattles = await db.collection("battles")
    .where("rivalryPairKey", "==", rivalryPairKey)
    .get();
  for (const doc of previousBattles.docs) {
    await doc.ref.delete();
  }

  for (const user of [challenger, opponent, voter]) {
    await ensureAuthUser(user);
    await db.doc(`users/${user.uid}`).set({
      username: user.displayName.toLowerCase().replace(/\s+/g, "_"),
      displayName: user.displayName,
      avatarUrl: "",
      email: user.email,
      scenesCount: 5,
      followersCount: 0,
      likesCount: 0,
      totalViews: 0,
      approvalRate: user.uid === voter.uid ? 65 : 82,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await db.doc(`userBattleStats/${challenger.uid}`).set({ uid: challenger.uid, ratingAvg: 82, ratingCount: 5, battleRatingTier: "Silver", activeBattlesCount: 0, challengesSentThisWeek: 0 }, { merge: true });
  await db.doc(`userBattleStats/${opponent.uid}`).set({ uid: opponent.uid, ratingAvg: 86, ratingCount: 5, battleRatingTier: "Silver", activeBattlesCount: 0, challengesSentThisWeek: 0 }, { merge: true });
  await db.doc(`userBattleStats/${voter.uid}`).set({ uid: voter.uid, ratingAvg: 65, ratingCount: 5, battleRatingTier: "Bronze", activeBattlesCount: 0, challengesSentThisWeek: 0 }, { merge: true });

  await db.doc("scenes/battle_flow_scene_admin").set({
    id: "battle_flow_scene_admin",
    title: "La scène Battle émulateur",
    category: "Drame",
    genre: "Face-à-face",
    difficulty: "intermediaire",
    level: "intermediaire",
    status: "published",
    adminWorkflow: true,
    battleEnabled: true,
    battleThemes: ["Duel serré", "Drame"],
    battleDifficultyTier: "intermediaire",
    battleCategory: "Drame",
    isEligibleForRandomBattleDraw: true,
    videoUrl: "https://example.com/ai-intro.mp4",
    dialogueText: "Même scène. Même délai. Deux interprétations. Un seul gagnant.",
    durationSeconds: 60,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function forceVotingEnded(db, battleId) {
  await db.doc(`battles/${battleId}`).update({
    votingEndsAt: admin.firestore.Timestamp.fromMillis(Date.now() - 60_000),
  });
}

async function runEndVotingMaintenance() {
  const schedulerPath = "../functions/lib/battleScheduler.js";
  try {
    const { endVotingBattlesOnce } = require(schedulerPath);
    await endVotingBattlesOnce();
  } catch (error) {
    throw new Error(
      `Impossible de déclencher endVotingBattlesOnce. Lancez d'abord cd functions && npm run build. ${error.message}`
    );
  }
}

async function main() {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_HOST;
  }
  if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_HOST;
  }
  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();
  console.log(`🧪 Battle flow emulators auth=${AUTH_HOST} firestore=${FIRESTORE_HOST} functions=${FUNCTIONS_ORIGIN}`);

  await seedEmulatorData(db);
  const challengerToken = await signIn(challenger);
  const opponentToken = await signIn(opponent);
  const voterToken = await signIn(voter);

  const challenge = await callFunction("createBattleChallenge", challengerToken, { opponentId: opponent.uid });
  const battleId = challenge.battleId;
  assert(battleId, "battleId manquant après challenge");
  console.log(`✅ challenge créé ${battleId}`);

  await callFunction("respondBattleChallenge", opponentToken, { battleId, accept: true });
  let battle = (await db.doc(`battles/${battleId}`).get()).data();
  assert(battle.status === "in_preparation", `status attendu in_preparation, reçu ${battle.status}`);
  assert(battle.sceneId, "sceneId non attribué");
  console.log(`✅ duel accepté avec scène ${battle.sceneId}`);

  await callFunction("followBattle", voterToken, { battleId });
  await callFunction("createBattlePrediction", voterToken, { battleId, predictedWinnerId: challenger.uid });
  console.log("✅ follow + pronostic");

  await callFunction("submitBattlePerformance", challengerToken, {
    battleId,
    recordingId: "recording_challenger",
    videoUrl: "https://example.com/challenger.mp4",
    storagePath: "test/challenger.mp4",
  });
  battle = (await db.doc(`battles/${battleId}`).get()).data();
  assert(battle.status === "waiting_opponent_submission", `status après première soumission: ${battle.status}`);

  await callFunction("submitBattlePerformance", opponentToken, {
    battleId,
    recordingId: "recording_opponent",
    videoUrl: "https://example.com/opponent.mp4",
    storagePath: "test/opponent.mp4",
  });
  battle = (await db.doc(`battles/${battleId}`).get()).data();
  assert(battle.status === "voting_open", `status attendu voting_open, reçu ${battle.status}`);
  console.log("✅ double soumission -> voting_open");

  await callFunction("castBattleVote", voterToken, {
    battleId,
    votedForUserId: challenger.uid,
    watchProgressChallenger: 1,
    watchProgressOpponent: 1,
  });
  battle = (await db.doc(`battles/${battleId}`).get()).data();
  assert(Number(battle.totalVotes) === 1, "vote non comptabilisé");
  console.log("✅ vote unique comptabilisé");

  await forceVotingEnded(db, battleId);
  await runEndVotingMaintenance();
  battle = (await db.doc(`battles/${battleId}`).get()).data();
  assert(battle.status === "ended", `status attendu ended, reçu ${battle.status}`);
  assert(battle.winnerId === challenger.uid, "winnerId inattendu après fin de vote");
  console.log("✅ fin de vote -> ended + winnerId");
  console.log(`SUCCESS parcours Battle complet: /battle/${battleId}`);
}

main().catch((error) => {
  console.error(`FAILED ${error.message}`);
  process.exit(1);
});
