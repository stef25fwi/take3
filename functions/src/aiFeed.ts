import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";

const feedEventTypes = new Set([
  "view",
  "complete",
  "rewatch",
  "like",
  "share",
  "comment",
  "skip",
  "follow",
  "vote",
]);

type StyleScores = Record<string, number>;

interface FeedCandidateDoc {
  postId: string;
  userId: string;
  videoUrl: string;
  actorStyles: string[];
  qualityScore: number;
  trendingScore: number;
  freshnessScore: number;
  regionScore: number;
  explorationScore: number;
  createdAt?: Timestamp;
  battleId?: string | null;
  isBattle?: boolean;
}

function requireUid(authUid?: string): string {
  if (!authUid) throw new HttpsError("unauthenticated", "Connexion requise.");
  return authUid;
}

function readEventType(value: unknown): string {
  const eventType = typeof value === "string" ? value : "";
  if (!feedEventTypes.has(eventType)) {
    throw new HttpsError("invalid-argument", "eventType invalide.");
  }
  return eventType;
}

function clamp01(value: unknown): number {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed)) return 0;
  return Math.max(0, Math.min(1, parsed));
}

function styleFromScene(scene: Record<string, unknown>): string[] {
  const tags = Array.isArray(scene.tags) ? scene.tags.map(String) : [];
  const category = String(scene.category ?? "").toLowerCase();
  const emotion = String(scene.dominantEmotion ?? "").toLowerCase();
  const styles = new Set<string>([category, emotion, ...tags.map((tag) => tag.toLowerCase())]);
  if (category.includes("comedy") || category.includes("fun")) styles.add("funny");
  if (category.includes("drama") || emotion.includes("colere") || emotion.includes("clash")) styles.add("drama");
  if (emotion.includes("intense") || category.includes("battle")) styles.add("intense");
  if (category.includes("romance") || emotion.includes("love")) styles.add("romance");
  return [...styles].filter(Boolean).slice(0, 8);
}

function styleAffinity(styles: string[], preferred: StyleScores): number {
  if (styles.length === 0) return 0.35;
  let score = 0;
  for (const raw of styles) {
    const style = raw.toLowerCase();
    if (style.includes("drama") || style.includes("clash")) score += preferred.drama ?? 0;
    if (style.includes("intense") || style.includes("battle")) score += preferred.intense ?? 0;
    if (style.includes("funny") || style.includes("comedy") || style.includes("humour")) score += preferred.funny ?? 0;
    if (style.includes("romance") || style.includes("love")) score += preferred.romance ?? 0;
  }
  return Math.max(0.05, Math.min(1, score));
}

function computeFeedScore(candidate: FeedCandidateDoc, preferredStyles: StyleScores): number {
  const userStyleAffinity = styleAffinity(candidate.actorStyles ?? [], preferredStyles);
  const completionPrediction = Math.min(1, candidate.qualityScore * 0.7 + candidate.regionScore * 0.3);
  const rewatchPrediction = Math.min(1, candidate.qualityScore * 0.6 + candidate.trendingScore * 0.4);
  return (userStyleAffinity * 30) +
    (completionPrediction * 25) +
    (rewatchPrediction * 15) +
    (candidate.trendingScore * 15) +
    (candidate.freshnessScore * 10) +
    (candidate.explorationScore * 5);
}

function eventWeight(eventType: string, watchTimeMs: number): number {
  switch (eventType) {
    case "complete": return 0.16;
    case "rewatch": return 0.2;
    case "like": return 0.14;
    case "share": return 0.18;
    case "comment": return 0.14;
    case "follow": return 0.16;
    case "vote": return 0.12;
    case "skip": return -0.12;
    case "view": return Math.min(0.08, Math.max(0.01, watchTimeMs / 60000));
    default: return 0;
  }
}

function bumpStyles(current: StyleScores, styles: string[], delta: number): StyleScores {
  const next = {
    drama: clamp01(current.drama ?? 0.25),
    intense: clamp01(current.intense ?? 0.25),
    funny: clamp01(current.funny ?? 0.25),
    romance: clamp01(current.romance ?? 0.25),
  };
  for (const raw of styles) {
    const style = raw.toLowerCase();
    if (style.includes("drama") || style.includes("clash")) next.drama = clamp01(next.drama + delta);
    if (style.includes("intense") || style.includes("battle")) next.intense = clamp01(next.intense + delta);
    if (style.includes("funny") || style.includes("comedy") || style.includes("humour")) next.funny = clamp01(next.funny + delta);
    if (style.includes("romance") || style.includes("love")) next.romance = clamp01(next.romance + delta);
  }
  return next;
}

async function readCandidate(postId: string): Promise<FeedCandidateDoc | null> {
  const snap = await getFirestore().doc(`feedCandidates/${postId}`).get();
  if (!snap.exists) return null;
  return snap.data() as FeedCandidateDoc;
}

export const recordFeedEvent = onCall(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const postId = typeof req.data?.postId === "string" ? req.data.postId.trim() : "";
  if (!postId) throw new HttpsError("invalid-argument", "postId requis.");
  const eventType = readEventType(req.data?.eventType);
  const watchTimeMs = Math.max(0, Math.floor(Number(req.data?.watchTimeMs ?? 0)));
  const db = getFirestore();

  const eventRef = db.collection("feedEvents").doc();
  await eventRef.set({
    userId: uid,
    postId,
    eventType,
    watchTimeMs,
    createdAt: FieldValue.serverTimestamp(),
  });

  const candidate = await readCandidate(postId);
  const profileRef = db.doc(`userFeedProfiles/${uid}`);
  await db.runTransaction(async (tx) => {
    const profileSnap = await tx.get(profileRef);
    const current = (profileSnap.data()?.preferredStyles ?? {}) as StyleScores;
    const delta = eventWeight(eventType, watchTimeMs);
    const preferredStyles = bumpStyles(current, candidate?.actorStyles ?? [], delta);
    tx.set(profileRef, {
      userId: uid,
      preferredStyles,
      preferredDurations: FieldValue.arrayUnion(Math.min(120, Math.max(15, Math.round(watchTimeMs / 1000) || 60))),
      creatorAffinity: candidate?.userId ? { [candidate.userId]: FieldValue.increment(delta) } : {},
      skipPatterns: eventType === "skip" ? { [postId]: FieldValue.increment(1) } : {},
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  if (["complete", "rewatch", "like", "share", "comment", "vote"].includes(eventType)) {
    await db.doc(`feedCandidates/${postId}`).set({
      trendingScore: FieldValue.increment(eventType === "share" ? 0.04 : 0.02),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  return { ok: true, eventId: eventRef.id };
});

export const computeFeedProfile = onCall(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const limit = Math.min(200, Math.max(20, Number(req.data?.limit ?? 100)));
  const db = getFirestore();
  const events = await db.collection("feedEvents")
    .where("userId", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();
  let styles: StyleScores = { drama: 0.25, intense: 0.25, funny: 0.25, romance: 0.25 };
  for (const event of events.docs.reverse()) {
    const data = event.data();
    const candidate = await readCandidate(String(data.postId ?? ""));
    styles = bumpStyles(styles, candidate?.actorStyles ?? [], eventWeight(String(data.eventType), Number(data.watchTimeMs ?? 0)));
  }
  await db.doc(`userFeedProfiles/${uid}`).set({
    userId: uid,
    preferredStyles: styles,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { preferredStyles: styles };
});

export const generateFeedCandidates = onCall(async (req) => {
  requireUid(req.auth?.uid);
  const limit = Math.min(100, Math.max(12, Number(req.data?.limit ?? 48)));
  const db = getFirestore();
  const scenes = await db.collection("scenes")
    .where("status", "==", "published")
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();
  const batch = db.batch();
  const now = Date.now();
  scenes.forEach((doc) => {
    const scene = doc.data();
    const createdAt = scene.createdAt instanceof Timestamp ? scene.createdAt.toMillis() : now;
    const ageHours = Math.max(1, (now - createdAt) / 36e5);
    const likes = Number(scene.likesCount ?? 0);
    const views = Math.max(1, Number(scene.viewsCount ?? 1));
    const comments = Number(scene.commentsCount ?? 0);
    const shares = Number(scene.sharesCount ?? 0);
    const qualityScore = Math.min(1, (likes * 2 + comments * 3 + shares * 4) / Math.max(20, views));
    const trendingScore = Math.min(1, (likes + comments * 2 + shares * 3) / Math.sqrt(ageHours + 2) / 100);
    const freshnessScore = Math.max(0, Math.min(1, 1 - ageHours / (24 * 14)));
    batch.set(db.doc(`feedCandidates/${doc.id}`), {
      postId: doc.id,
      userId: String(scene.authorId ?? scene.createdBy ?? ""),
      videoUrl: String(scene.videoUrl ?? ""),
      actorStyles: styleFromScene(scene),
      qualityScore,
      trendingScore,
      freshnessScore,
      regionScore: scene.regionCode ? 0.8 : 0.4,
      explorationScore: Math.random() * 0.8 + 0.1,
      createdAt: scene.createdAt ?? FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  await batch.commit();
  return { generated: scenes.size };
});

export const getPersonalizedFeed = onCall(async (req) => {
  const uid = requireUid(req.auth?.uid);
  const limit = Math.min(50, Math.max(5, Number(req.data?.limit ?? 24)));
  const db = getFirestore();
  const [profileSnap, seenSnap, candidatesSnap, battlesSnap] = await Promise.all([
    db.doc(`userFeedProfiles/${uid}`).get(),
    db.collection("feedEvents").where("userId", "==", uid).orderBy("createdAt", "desc").limit(80).get(),
    db.collection("feedCandidates").orderBy("createdAt", "desc").limit(120).get(),
    db.collection("battles").where("status", "in", ["published", "voting_open"]).orderBy("trendingScore", "desc").limit(12).get(),
  ]);
  const preferredStyles = ((profileSnap.data()?.preferredStyles ?? {}) as StyleScores);
  const seen = new Set(seenSnap.docs.map((doc) => String(doc.data().postId ?? "")));
  const candidates = candidatesSnap.docs
    .map((doc) => ({ ...(doc.data() as FeedCandidateDoc), postId: doc.id }))
    .filter((candidate) => candidate.videoUrl && !seen.has(candidate.postId));

  for (const battle of battlesSnap.docs) {
    const data = battle.data();
    for (const side of ["challenger", "opponent"]) {
      const videoUrl = String(data[`${side}VideoUrl`] ?? "");
      if (!videoUrl) continue;
      const postId = `${battle.id}_${side}`;
      candidates.push({
        postId,
        userId: String(data[`${side}Id`] ?? ""),
        videoUrl,
        actorStyles: ["battle", "intense", String(data.sceneCategory ?? "")],
        qualityScore: 0.7,
        trendingScore: clamp01(data.trendingScore),
        freshnessScore: 0.8,
        regionScore: data.regionCode ? 0.8 : 0.4,
        explorationScore: 0.35,
        createdAt: data.publishedAt,
        battleId: battle.id,
        isBattle: true,
      });
    }
  }

  const scored = candidates.map((candidate) => ({
    ...candidate,
    feedScore: computeFeedScore(candidate, preferredStyles),
  }));
  const personalized = scored
    .filter((candidate) => styleAffinity(candidate.actorStyles, preferredStyles) >= 0.25)
    .sort((a, b) => b.feedScore - a.feedScore);
  const trending = [...scored].sort((a, b) => b.trendingScore - a.trendingScore);
  const exploration = [...scored].sort((a, b) => b.explorationScore - a.explorationScore);
  const mix = [
    ...personalized.slice(0, Math.ceil(limit * 0.7)).map((item) => ({ ...item, reason: "taste" })),
    ...trending.slice(0, Math.ceil(limit * 0.2)).map((item) => ({ ...item, reason: "trending" })),
    ...exploration.slice(0, Math.ceil(limit * 0.1)).map((item) => ({ ...item, reason: "exploration" })),
  ];
  const deduped = new Map<string, typeof mix[number]>();
  for (const item of mix.sort((a, b) => b.feedScore - a.feedScore)) {
    deduped.set(item.postId, item);
  }
  return {
    items: [...deduped.values()].slice(0, limit).map((item) => ({
      postId: item.postId,
      feedScore: item.feedScore,
      reason: item.reason,
      isBattle: item.isBattle === true,
      battleId: item.battleId ?? null,
    })),
  };
});
