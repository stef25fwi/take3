import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp, getFirestore, QueryDocumentSnapshot, DocumentData } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";

import {
  battleConstants,
  incrementActiveBattleStats,
  isBattleEligible,
  pairKey,
  ratingDeltaPercent,
  readBattleStats,
} from "./battleStats";
import { isAdminUid } from "./veo/shared";
import {
  createBattleNotification,
  notifyBattleFollowers,
  notifyCandidateFollowers,
} from "./battleNotifications";
import { buildBattleScorePatch } from "./battleScoring";

const activeStatuses = [
  "challenge_sent",
  "accepted",
  "scene_assigned",
  "in_preparation",
  "waiting_challenger_submission",
  "waiting_opponent_submission",
  "ready_to_publish",
  "published",
  "voting_open",
];

function requireUid(authUid?: string): string {
  if (!authUid) throw new HttpsError("unauthenticated", "Connexion requise pour cette action.");
  return authUid;
}

function requireString(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${name} requis.`);
  }
  return value.trim();
}

function readPositiveInt(value: unknown, fallback: number): number {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return fallback;
  }
  return Math.floor(parsed);
}

async function getUserLabel(uid: string): Promise<{ name: string; photoUrl: string }> {
  const snap = await getFirestore().doc(`users/${uid}`).get();
  const data = snap.data() ?? {};
  return {
    name: (data.displayName as string) || (data.username as string) || "Candidat",
    photoUrl: (data.avatarUrl as string) || "",
  };
}

async function assertNoActiveBattleBetween(userA: string, userB: string): Promise<void> {
  const key = pairKey(userA, userB);
  const snap = await getFirestore()
    .collection("battles")
    .where("rivalryPairKey", "==", key)
    .where("status", "in", activeStatuses.slice(0, 10))
    .limit(1)
    .get();
  if (!snap.empty) {
    throw new HttpsError("failed-precondition", "Un duel actif existe déjà entre ces candidats.");
  }
}

async function pickBattleScene(): Promise<QueryDocumentSnapshot<DocumentData>> {
  const db = getFirestore();
  let snap = await db.collection("scenes")
    .where("adminWorkflow", "==", true)
    .where("status", "==", "published")
    .where("battleEnabled", "==", true)
    .limit(24)
    .get();
  if (snap.empty) {
    snap = await db.collection("scenes")
      .where("adminWorkflow", "==", true)
      .where("status", "==", "published")
      .limit(24)
      .get();
  }
  const eligible = snap.docs.filter((doc) => {
    const data = doc.data();
    const duration = Number(data.durationSeconds ?? 60);
    return duration <= 90 && (data.videoUrl || data.aiIntroVideo || data.directorInstructions || data.dialogueText);
  });
  if (eligible.length === 0) {
    throw new HttpsError("failed-precondition", "La scène Battle n’a pas pu être attribuée.");
  }
  return eligible[Math.floor(Math.random() * eligible.length)];
}

export const createBattleChallenge = onCall<{ opponentId: string; sourceTakeId?: string }>(async (req) => {
  const challengerId = requireUid(req.auth?.uid);
  const opponentId = requireString(req.data?.opponentId, "opponentId");
  if (challengerId === opponentId) {
    throw new HttpsError("invalid-argument", "Tu ne peux pas te défier toi-même.");
  }

  await assertNoActiveBattleBetween(challengerId, opponentId);
  const [challengerStats, opponentStats, challenger, opponent] = await Promise.all([
    readBattleStats(challengerId),
    readBattleStats(opponentId),
    getUserLabel(challengerId),
    getUserLabel(opponentId),
  ]);
  const eligible = isBattleEligible(challengerStats, opponentStats);
  if (!eligible) {
    throw new HttpsError("failed-precondition", "Ce candidat n’est pas dans ton niveau Battle.");
  }

  const db = getFirestore();
  const battleRef = db.collection("battles").doc();
  const key = pairKey(challengerId, opponentId);
  const now = FieldValue.serverTimestamp();
  const nowDate = new Date();
  await db.runTransaction(async (tx) => {
    const battle = {
      id: battleRef.id,
      status: "challenge_sent",
      challengerId,
      opponentId,
      challengerName: challenger.name,
      opponentName: opponent.name,
      challengerPhotoUrl: challenger.photoUrl,
      opponentPhotoUrl: opponent.photoUrl,
      challengerRatingAvgAtChallenge: challengerStats.ratingAvg,
      opponentRatingAvgAtChallenge: opponentStats.ratingAvg,
      ratingDeltaPercent: ratingDeltaPercent(challengerStats.ratingAvg, opponentStats.ratingAvg),
      isRatingEligible: true,
      createdAt: now,
      followersCount: 0,
      predictionsCount: 0,
      commentsCount: 0,
      votesChallenger: 0,
      votesOpponent: 0,
      totalVotes: 0,
      watchersCount: 0,
      isRevengeAvailable: false,
      parentBattleId: req.data?.sourceTakeId ?? null,
      rivalryPairKey: key,
      isFeatured: false,
      featuredUntil: null,
      battleScore: 0,
      trendingScore: 0,
      visibilityScope: "public",
      regionCode: null,
      countryCode: null,
      shareTitle: `${challenger.name} vs ${opponent.name}`,
      shareSubtitle: "Même scène. Même délai. Deux interprétations. Un seul gagnant.",
      deepLink: `take60://battle/${battleRef.id}`,
      createdBy: challengerId,
      updatedAt: now,
      version: 1,
    };
    tx.set(battleRef, {
      ...battle,
      ...buildBattleScorePatch({ ...battle, createdAt: nowDate, updatedAt: nowDate }, nowDate),
    });
    tx.set(battleRef.collection("events").doc(), {
      type: "challenge_sent",
      actorUid: challengerId,
      createdAt: now,
      metadata: { opponentId },
    });
    incrementActiveBattleStats(tx, challengerId, opponentId);
  });

  await createBattleNotification({
    uid: opponentId,
    type: "battle_challenge_received",
    title: "Nouveau défi Battle",
    body: `${challenger.name} te provoque en duel d’interprétation.`,
    battleId: battleRef.id,
    actorUid: challengerId,
    challengerId,
    opponentId,
  });
  logger.info("battle.challenge.created", { battleId: battleRef.id, actorUid: challengerId });
  return { battleId: battleRef.id };
});

export const respondBattleChallenge = onCall<{ battleId: string; accept: boolean }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const accept = Boolean(req.data?.accept);
  const db = getFirestore();
  const battleRef = db.doc(`battles/${battleId}`);
  const battleSnap = await battleRef.get();
  if (!battleSnap.exists) throw new HttpsError("not-found", "Ce duel n’est plus disponible.");
  const battle = battleSnap.data() ?? {};
  if (battle.opponentId !== uid) throw new HttpsError("permission-denied", "Action non autorisée.");
  if (battle.status !== "challenge_sent") throw new HttpsError("failed-precondition", "Ce duel n’est plus disponible.");

  if (!accept) {
    const nowDate = new Date();
    await battleRef.update({
      status: "declined",
      declinedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      ...buildBattleScorePatch({ ...battle, status: "declined", declinedAt: nowDate, updatedAt: nowDate }, nowDate),
    });
    await createBattleNotification({
      uid: battle.challengerId as string,
      type: "battle_result",
      title: "Duel refusé",
      body: "Le candidat n’est pas disponible pour ce duel.",
      battleId,
      actorUid: uid,
    });
    return { status: "declined" };
  }

  const sceneDoc = await pickBattleScene();
  const scene = sceneDoc.data();
  const deadline = Timestamp.fromMillis(Date.now() + battleConstants.defaultSubmissionHours * 60 * 60 * 1000);
  const nowDate = new Date();
  await battleRef.update({
    status: "in_preparation",
    acceptedAt: FieldValue.serverTimestamp(),
    sceneAssignedAt: FieldValue.serverTimestamp(),
    submissionDeadline: deadline,
    themeTitle: ((scene.battleThemes as string[] | undefined)?.[0] ?? scene.category ?? scene.genre ?? "Interprétation"),
    sceneId: sceneDoc.id,
    sceneTitle: scene.title ?? "Scène Take60",
    sceneCategory: scene.battleCategory ?? scene.category ?? "",
    sceneGenre: scene.genre ?? scene.category ?? "",
    sceneDifficulty: scene.battleDifficultyTier ?? scene.difficulty ?? "",
    sceneDurationSec: Number(scene.durationSeconds ?? 60),
    sceneAdminWorkflow: Boolean(scene.adminWorkflow),
    updatedAt: FieldValue.serverTimestamp(),
    ...buildBattleScorePatch({
      ...battle,
      status: "in_preparation",
      acceptedAt: nowDate,
      sceneAssignedAt: nowDate,
      submissionDeadline: deadline.toDate(),
      sceneId: sceneDoc.id,
      sceneTitle: scene.title ?? "Scène Take60",
      sceneCategory: scene.battleCategory ?? scene.category ?? "",
      sceneGenre: scene.genre ?? scene.category ?? "",
      sceneDifficulty: scene.battleDifficultyTier ?? scene.difficulty ?? "",
      sceneDurationSec: Number(scene.durationSeconds ?? 60),
      sceneAdminWorkflow: Boolean(scene.adminWorkflow),
      updatedAt: nowDate,
    }, nowDate),
  });
  await Promise.all([
    createBattleNotification({ uid: battle.challengerId as string, type: "battle_challenge_accepted", title: "Duel accepté", body: `La scène est tombée : ${scene.title ?? "Scène Take60"}.`, battleId, actorUid: uid }),
    createBattleNotification({ uid, type: "battle_scene_assigned", title: "Ta scène Battle est prête", body: "Tu as 72h pour publier ta performance.", battleId, actorUid: uid }),
    notifyCandidateFollowers(battle.challengerId as string, { type: "battle_challenge_accepted", title: `${battle.challengerName} prépare une Battle`, body: "Les deux candidats préparent leur performance.", battleId, actorUid: uid }),
    notifyCandidateFollowers(battle.opponentId as string, { type: "battle_challenge_accepted", title: `${battle.opponentName} prépare une Battle`, body: "Les deux candidats préparent leur performance.", battleId, actorUid: uid }),
  ]);
  return { status: "in_preparation", sceneId: sceneDoc.id };
});

export const followBattle = onCall<{ battleId: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const battleRef = db.doc(`battles/${battleId}`);
    const ref = db.doc(`battles/${battleId}/followers/${uid}`);
    const battle = (await tx.get(battleRef)).data() ?? {};
    if ((await tx.get(ref)).exists) return;
    const nowDate = new Date();
    const nextFollowersCount = Math.max(0, Number(battle.followersCount ?? 0) + 1);
    tx.set(ref, { uid, createdAt: FieldValue.serverTimestamp(), notifyOnPublish: true, notifyOnResult: true });
    tx.update(battleRef, {
      followersCount: nextFollowersCount,
      updatedAt: FieldValue.serverTimestamp(),
      ...buildBattleScorePatch({ ...battle, followersCount: nextFollowersCount, updatedAt: nowDate }, nowDate),
    });
  });
  return { following: true };
});

export const unfollowBattle = onCall<{ battleId: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const battleRef = db.doc(`battles/${battleId}`);
    const ref = db.doc(`battles/${battleId}/followers/${uid}`);
    const battle = (await tx.get(battleRef)).data() ?? {};
    if (!(await tx.get(ref)).exists) return;
    const nowDate = new Date();
    const nextFollowersCount = Math.max(0, Number(battle.followersCount ?? 0) - 1);
    tx.delete(ref);
    tx.update(battleRef, {
      followersCount: nextFollowersCount,
      updatedAt: FieldValue.serverTimestamp(),
      ...buildBattleScorePatch({ ...battle, followersCount: nextFollowersCount, updatedAt: nowDate }, nowDate),
    });
  });
  return { following: false };
});

export const followCandidate = onCall<{ candidateId: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const candidateId = requireString(req.data?.candidateId, "candidateId");
  if (uid === candidateId) throw new HttpsError("invalid-argument", "candidateId invalide.");
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const followingRef = db.doc(`users/${uid}/following/${candidateId}`);
    const followerRef = db.doc(`users/${candidateId}/followers/${uid}`);
    if ((await tx.get(followingRef)).exists) return;
    tx.set(followingRef, { targetUid: candidateId, createdAt: FieldValue.serverTimestamp(), notifyOnBattles: true });
    tx.set(followerRef, { followerUid: uid, createdAt: FieldValue.serverTimestamp(), notifyOnBattles: true, notifyOnNewVideos: true });
    tx.set(db.doc(`users/${candidateId}`), { followersCount: FieldValue.increment(1) }, { merge: true });
  });
  return { following: true };
});

export const unfollowCandidate = onCall<{ candidateId: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const candidateId = requireString(req.data?.candidateId, "candidateId");
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const followingRef = db.doc(`users/${uid}/following/${candidateId}`);
    if (!(await tx.get(followingRef)).exists) return;
    tx.delete(followingRef);
    tx.delete(db.doc(`users/${candidateId}/followers/${uid}`));
    tx.set(db.doc(`users/${candidateId}`), { followersCount: FieldValue.increment(-1) }, { merge: true });
  });
  return { following: false };
});

export const submitBattlePerformance = onCall<{ battleId: string; recordingId: string; videoUrl: string; storagePath: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const recordingId = requireString(req.data?.recordingId, "recordingId");
  const videoUrl = requireString(req.data?.videoUrl, "videoUrl");
  const storagePath = requireString(req.data?.storagePath, "storagePath");
  const db = getFirestore();
  const battleRef = db.doc(`battles/${battleId}`);
  let shouldNotifyPublished = false;
  let updatedBattle: DocumentData | undefined;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(battleRef);
    if (!snap.exists) throw new HttpsError("not-found", "Ce duel n’est plus disponible.");
    const battle = snap.data() ?? {};
    if (uid !== battle.challengerId && uid !== battle.opponentId) throw new HttpsError("permission-denied", "Action non autorisée.");
    if (!["in_preparation", "waiting_challenger_submission", "waiting_opponent_submission", "ready_to_publish"].includes(battle.status as string)) {
      throw new HttpsError("failed-precondition", "Ce duel n’est plus disponible.");
    }
    const isChallenger = uid === battle.challengerId;
    const nowDate = new Date();
    const patch: Record<string, unknown> = {
      updatedAt: FieldValue.serverTimestamp(),
      [isChallenger ? "challengerVideoUrl" : "opponentVideoUrl"]: videoUrl,
      [isChallenger ? "challengerRecordingId" : "opponentRecordingId"]: recordingId,
      [isChallenger ? "challengerStoragePath" : "opponentStoragePath"]: storagePath,
      [isChallenger ? "challengerSubmittedAt" : "opponentSubmittedAt"]: FieldValue.serverTimestamp(),
    };
    const otherVideo = isChallenger ? battle.opponentVideoUrl : battle.challengerVideoUrl;
    if (otherVideo) {
      patch.status = "voting_open";
      patch.publishedAt = FieldValue.serverTimestamp();
      patch.votingStartsAt = FieldValue.serverTimestamp();
      patch.votingEndsAt = Timestamp.fromMillis(Date.now() + battleConstants.defaultVotingHours * 60 * 60 * 1000);
      shouldNotifyPublished = true;
    } else {
      patch.status = isChallenger ? "waiting_opponent_submission" : "waiting_challenger_submission";
    }
    const scoredBattle = {
      ...battle,
      ...patch,
      updatedAt: nowDate,
      publishedAt: patch.status === "voting_open" ? nowDate : battle.publishedAt,
      votingStartsAt: patch.status === "voting_open" ? nowDate : battle.votingStartsAt,
      votingEndsAt: patch.status === "voting_open" ? Timestamp.fromMillis(Date.now() + battleConstants.defaultVotingHours * 60 * 60 * 1000).toDate() : battle.votingEndsAt,
    };
    tx.update(battleRef, {
      ...patch,
      ...buildBattleScorePatch(scoredBattle, nowDate),
    });
    updatedBattle = { ...scoredBattle, id: battleId };
  });
  if (shouldNotifyPublished && updatedBattle) {
    await Promise.all([
      notifyBattleFollowers(battleId, { type: "battle_published", title: "La Battle est en ligne", body: `${updatedBattle.challengerName} vs ${updatedBattle.opponentName} : regarde les deux performances et vote.`, battleId }),
      notifyCandidateFollowers(updatedBattle.challengerId as string, { type: "followed_candidate_battle_published", title: `${updatedBattle.challengerName} est en Battle`, body: "Sa nouvelle performance est disponible.", battleId }),
      notifyCandidateFollowers(updatedBattle.opponentId as string, { type: "followed_candidate_battle_published", title: `${updatedBattle.opponentName} est en Battle`, body: "Sa nouvelle performance est disponible.", battleId }),
    ]);
  }
  return { published: shouldNotifyPublished };
});

export const castBattleVote = onCall<{ battleId: string; votedForUserId: string; watchProgressChallenger: number; watchProgressOpponent: number }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const votedForUserId = requireString(req.data?.votedForUserId, "votedForUserId");
  const watchProgressChallenger = Number(req.data?.watchProgressChallenger ?? 0);
  const watchProgressOpponent = Number(req.data?.watchProgressOpponent ?? 0);
  if (watchProgressChallenger < 0.5 || watchProgressOpponent < 0.5) {
    throw new HttpsError("failed-precondition", "Tu dois regarder les deux performances avant de voter.");
  }
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const battleRef = db.doc(`battles/${battleId}`);
    const battleSnap = await tx.get(battleRef);
    if (!battleSnap.exists) throw new HttpsError("not-found", "Ce duel n’est plus disponible.");
    const battle = battleSnap.data() ?? {};
    if (battle.status !== "voting_open") throw new HttpsError("failed-precondition", "Le vote n’est pas ouvert.");
    if (uid === battle.challengerId || uid === battle.opponentId) throw new HttpsError("permission-denied", "Les candidats ne peuvent pas voter.");
    if (votedForUserId !== battle.challengerId && votedForUserId !== battle.opponentId) throw new HttpsError("invalid-argument", "Vote invalide.");
    const voteRef = db.doc(`battles/${battleId}/votes/${uid}`);
    if ((await tx.get(voteRef)).exists) throw new HttpsError("already-exists", "Tu as déjà voté.");
    const votedAgainstUserId = votedForUserId === battle.challengerId ? battle.opponentId : battle.challengerId;
    const nowDate = new Date();
    const nextVotesChallenger = Number(battle.votesChallenger ?? 0) + (votedForUserId === battle.challengerId ? 1 : 0);
    const nextVotesOpponent = Number(battle.votesOpponent ?? 0) + (votedForUserId === battle.opponentId ? 1 : 0);
    const nextTotalVotes = Number(battle.totalVotes ?? 0) + 1;
    tx.set(voteRef, { uid, votedForUserId, votedAgainstUserId, createdAt: FieldValue.serverTimestamp(), watchedChallenger: true, watchedOpponent: true, watchProgressChallenger, watchProgressOpponent });
    tx.update(battleRef, {
      votesChallenger: nextVotesChallenger,
      votesOpponent: nextVotesOpponent,
      totalVotes: nextTotalVotes,
      updatedAt: FieldValue.serverTimestamp(),
      ...buildBattleScorePatch({
        ...battle,
        votesChallenger: nextVotesChallenger,
        votesOpponent: nextVotesOpponent,
        totalVotes: nextTotalVotes,
        updatedAt: nowDate,
      }, nowDate),
    });
  });
  return { voted: true };
});

export const createBattlePrediction = onCall<{ battleId: string; predictedWinnerId: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const predictedWinnerId = requireString(req.data?.predictedWinnerId, "predictedWinnerId");
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const battleRef = db.doc(`battles/${battleId}`);
    const battle = (await tx.get(battleRef)).data();
    if (!battle || ["ended", "cancelled", "forfeit"].includes(battle.status as string)) throw new HttpsError("failed-precondition", "Ce duel n’est plus disponible.");
    if (predictedWinnerId !== battle.challengerId && predictedWinnerId !== battle.opponentId) throw new HttpsError("invalid-argument", "Pronostic invalide.");
    const ref = db.doc(`battles/${battleId}/predictions/${uid}`);
    if ((await tx.get(ref)).exists) throw new HttpsError("already-exists", "Pronostic déjà enregistré.");
    const nowDate = new Date();
    const nextPredictionsCount = Number(battle.predictionsCount ?? 0) + 1;
    tx.set(ref, { uid, predictedWinnerId, createdAt: FieldValue.serverTimestamp() });
    tx.update(battleRef, {
      predictionsCount: nextPredictionsCount,
      updatedAt: FieldValue.serverTimestamp(),
      ...buildBattleScorePatch({ ...battle, predictionsCount: nextPredictionsCount, updatedAt: nowDate }, nowDate),
    });
  });
  return { predicted: true };
});

export const requestBattleRevenge = onCall<{ battleId: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const db = getFirestore();
  const battleSnap = await db.doc(`battles/${battleId}`).get();
  const battle = battleSnap.data();
  if (!battle || battle.status !== "ended" || !battle.isRevengeAvailable) throw new HttpsError("failed-precondition", "Revanche indisponible.");
  if (uid !== battle.challengerId && uid !== battle.opponentId) throw new HttpsError("permission-denied", "Action non autorisée.");
  const opponentId = uid === battle.challengerId ? battle.opponentId as string : battle.challengerId as string;
  await assertNoActiveBattleBetween(uid, opponentId);
  const [challenger, opponent] = await Promise.all([getUserLabel(uid), getUserLabel(opponentId)]);
  const battleRef = db.collection("battles").doc();
  const nowDate = new Date();
  const battlePayload = {
    id: battleRef.id,
    status: "challenge_sent",
    challengerId: uid,
    opponentId,
    challengerName: challenger.name,
    opponentName: opponent.name,
    challengerPhotoUrl: challenger.photoUrl,
    opponentPhotoUrl: opponent.photoUrl,
    challengerRatingAvgAtChallenge: Number(battle.opponentRatingAvgAtChallenge ?? 0),
    opponentRatingAvgAtChallenge: Number(battle.challengerRatingAvgAtChallenge ?? 0),
    ratingDeltaPercent: Number(battle.ratingDeltaPercent ?? 0),
    isRatingEligible: true,
    parentBattleId: battleId,
    rivalryPairKey: pairKey(uid, opponentId),
    followersCount: 0,
    predictionsCount: 0,
    commentsCount: 0,
    votesChallenger: 0,
    votesOpponent: 0,
    totalVotes: 0,
    watchersCount: 0,
    isRevengeAvailable: false,
    isFeatured: false,
    featuredUntil: null,
    battleScore: 0,
    trendingScore: 0,
    visibilityScope: "public",
    regionCode: null,
    countryCode: null,
    shareTitle: `${challenger.name} vs ${opponent.name}`,
    shareSubtitle: "Même scène. Même délai. Deux interprétations. Un seul gagnant.",
    deepLink: `take60://battle/${battleRef.id}`,
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    version: 1,
  };
  await battleRef.set({
    ...battlePayload,
    ...buildBattleScorePatch({ ...battlePayload, createdAt: nowDate, updatedAt: nowDate }, nowDate),
  });
  await createBattleNotification({
    uid: opponentId,
    type: "battle_revenge_available",
    title: "Revanche possible",
    body: "Le duel était serré. Une revanche peut être lancée.",
    battleId: battleRef.id,
    actorUid: uid,
  });
  return { battleId: battleRef.id };
});

export const reportBattle = onCall<{ battleId: string; reason: string; details?: string }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const battleId = requireString(req.data?.battleId, "battleId");
  const reason = requireString(req.data?.reason, "reason");
  await getFirestore().collection(`battles/${battleId}/reports`).add({
    uid,
    reason,
    details: typeof req.data?.details === "string" ? req.data.details : "",
    createdAt: FieldValue.serverTimestamp(),
    status: "open",
  });
  return { reported: true };
});

export const setBattleFeatured = onCall<{ battleId: string; isFeatured: boolean; featuredHours?: number }>(async (req) => {
  const uid = requireUid(req.auth?.uid);
  if (!(await isAdminUid(uid))) {
    throw new HttpsError("permission-denied", "Réservé aux admins.");
  }

  const battleId = requireString(req.data?.battleId, "battleId");
  const isFeatured = req.data?.isFeatured === true;
  const featuredHours = readPositiveInt(req.data?.featuredHours, 72);
  const db = getFirestore();
  const battleRef = db.doc(`battles/${battleId}`);
  const battleSnap = await battleRef.get();
  if (!battleSnap.exists) {
    throw new HttpsError("not-found", "Cette battle est introuvable.");
  }

  const battle = battleSnap.data() ?? {};
  const nowDate = new Date();
  const featuredUntil = isFeatured
    ? new Date(nowDate.getTime() + featuredHours * 60 * 60 * 1000)
    : null;

  await battleRef.update({
    isFeatured,
    featuredUntil: isFeatured ? Timestamp.fromDate(featuredUntil!) : null,
    updatedAt: FieldValue.serverTimestamp(),
    ...buildBattleScorePatch({
      ...battle,
      isFeatured,
      featuredUntil,
      updatedAt: nowDate,
    }, nowDate),
  });

  return {
    battleId,
    isFeatured,
    featuredUntil: featuredUntil?.toISOString() ?? null,
  };
});
