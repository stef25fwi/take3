/**
 * Take30 — Cloud Functions (v2)
 *
 * Triggers Firestore, callables HTTPS, scheduled tasks.
 * Toutes les mises à jour de compteurs transitent ici pour
 * respecter les règles strictes (`writesNoCounters` côté client).
 */

import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentDeleted, onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions, logger } from "firebase-functions/v2";

admin.initializeApp();

setGlobalOptions({ region: "europe-west1", maxInstances: 50 });

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ─── Helpers ───────────────────────────────────────────────────────────────

interface UserDenorm {
  id: string;
  username: string;
  avatarUrl: string;
  isVerified: boolean;
}

async function getUserDenorm(uid: string): Promise<UserDenorm | null> {
  const snap = await db.doc(`users/${uid}`).get();
  if (!snap.exists) return null;
  const d = snap.data() as Record<string, unknown>;
  return {
    id: uid,
    username: (d.username as string) ?? "",
    avatarUrl: (d.avatarUrl as string) ?? "",
    isVerified: Boolean(d.isVerified),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. onSceneCreate
//    - incr users/{authorId}.scenesCount
//    - incr categories/{category}.scenesCount
//    - fan-out vers feed/{followerUid}/items
// ═══════════════════════════════════════════════════════════════════════════

export const onSceneCreate = onDocumentCreated("scenes/{sceneId}", async (event) => {
  const scene = event.data?.data();
  if (!scene) return;
  const sceneId = event.params.sceneId;
  const authorId = scene.authorId as string;
  const category = (scene.category as string) ?? "all";

  await db.doc(`users/${authorId}`).update({
    scenesCount: FieldValue.increment(1),
  }).catch((e) => logger.error("user.scenesCount inc failed", e));

  const catRef = db.doc(`categories/${category}`);
  await catRef.set(
    { scenesCount: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );

  // Fan-out feed (followers)
  const followers = await db.collection(`users/${authorId}/followers`).limit(500).get();
  const batch = db.batch();
  const item = {
    sceneId,
    authorId,
    category,
    createdAt: scene.createdAt ?? FieldValue.serverTimestamp(),
    score: 0,
  };
  followers.forEach((doc) => {
    batch.set(db.doc(`feed/${doc.id}/items/${sceneId}`), item);
  });
  // L'auteur voit aussi ses scènes dans son feed
  batch.set(db.doc(`feed/${authorId}/items/${sceneId}`), item);
  await batch.commit();
});

export const onSceneDelete = onDocumentDeleted("scenes/{sceneId}", async (event) => {
  const scene = event.data?.data();
  if (!scene) return;
  const sceneId = event.params.sceneId;
  const authorId = scene.authorId as string;
  const category = (scene.category as string) ?? "all";

  await db.doc(`users/${authorId}`).update({
    scenesCount: FieldValue.increment(-1),
  }).catch(() => {});

  await db.doc(`categories/${category}`).set(
    { scenesCount: FieldValue.increment(-1) },
    { merge: true }
  ).catch(() => {});

  // Nettoyer feed items
  const feedItems = await db.collectionGroup("items").where("sceneId", "==", sceneId).get();
  const batch = db.batch();
  feedItems.forEach((d) => batch.delete(d.ref));
  await batch.commit();
});

// ═══════════════════════════════════════════════════════════════════════════
// 2. onLikeWrite (subcol: scenes/{sceneId}/likes/{uid})
// ═══════════════════════════════════════════════════════════════════════════

export const onLikeWrite = onDocumentWritten("scenes/{sceneId}/likes/{uid}", async (event) => {
  const before = event.data?.before.exists;
  const after = event.data?.after.exists;
  if (before === after) return;

  const sceneId = event.params.sceneId;
  const uid = event.params.uid;
  const delta = after ? 1 : -1;

  await db.doc(`scenes/${sceneId}`).update({
    likesCount: FieldValue.increment(delta),
  }).catch(() => {});

  if (!after) return;

  // Notification au créateur (évite auto-notif)
  const sceneSnap = await db.doc(`scenes/${sceneId}`).get();
  const scene = sceneSnap.data();
  if (!scene) return;
  const authorId = scene.authorId as string;
  if (authorId === uid) return;

  const actor = await getUserDenorm(uid);
  if (!actor) return;

  await db.collection(`notifications/${authorId}/items`).add({
    type: "like",
    time: FieldValue.serverTimestamp(),
    isRead: false,
    message: `${actor.username} a aimé ta scène`,
    subMessage: "Ouvre le take pour voir qui a réagi.",
    avatarUrl: actor.avatarUrl,
    userId: actor.id,
    sceneId,
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 3. onCommentCreate
// ═══════════════════════════════════════════════════════════════════════════

export const onCommentCreate = onDocumentCreated(
  "scenes/{sceneId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;
    const sceneId = event.params.sceneId;

    await db.doc(`scenes/${sceneId}`).update({
      commentsCount: FieldValue.increment(1),
    }).catch(() => {});

    const sceneSnap = await db.doc(`scenes/${sceneId}`).get();
    const scene = sceneSnap.data();
    if (!scene) return;
    const authorId = scene.authorId as string;
    const actorId = comment.authorId as string;
    if (authorId === actorId) return;

    const actor = (comment.authorDenorm as UserDenorm) ?? (await getUserDenorm(actorId));
    if (!actor) return;

    await db.collection(`notifications/${authorId}/items`).add({
      type: "comment",
      time: FieldValue.serverTimestamp(),
      isRead: false,
      message: `${actor.username} a commenté ta scène`,
      subMessage: "Lis le commentaire et réponds si besoin.",
      avatarUrl: actor.avatarUrl,
      userId: actor.id,
      sceneId,
      commentId: event.params.commentId,
    });
  }
);

// ═══════════════════════════════════════════════════════════════════════════
// 4. toggleFollow (callable)
// ═══════════════════════════════════════════════════════════════════════════

export const toggleFollow = onCall<{ targetUid: string }>(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Auth required");
  const targetUid = req.data?.targetUid;
  if (!targetUid || targetUid === uid) {
    throw new HttpsError("invalid-argument", "targetUid invalid");
  }

  const followingRef = db.doc(`users/${uid}/following/${targetUid}`);
  const followerRef = db.doc(`users/${targetUid}/followers/${uid}`);

  const existing = await followingRef.get();
  const now = FieldValue.serverTimestamp();
  const batch = db.batch();

  if (existing.exists) {
    batch.delete(followingRef);
    batch.delete(followerRef);
    batch.update(db.doc(`users/${uid}`), {
      followingCount: FieldValue.increment(-1),
    });
    batch.update(db.doc(`users/${targetUid}`), {
      followersCount: FieldValue.increment(-1),
    });
    await batch.commit();
    return { following: false };
  }

  const [actor, target] = await Promise.all([
    getUserDenorm(uid),
    getUserDenorm(targetUid),
  ]);

  batch.set(followingRef, {
    uid: targetUid,
    since: now,
    userDenorm: target,
  });
  batch.set(followerRef, {
    uid,
    since: now,
    userDenorm: actor,
  });
  batch.update(db.doc(`users/${uid}`), {
    followingCount: FieldValue.increment(1),
  });
  batch.update(db.doc(`users/${targetUid}`), {
    followersCount: FieldValue.increment(1),
  });
  batch.set(db.collection(`notifications/${targetUid}/items`).doc(), {
    type: "follow",
    time: now,
    isRead: false,
    message: `${actor?.username ?? "Quelqu'un"} te suit maintenant`,
    subMessage: "Découvre son profil ou rends-lui la pareille.",
    avatarUrl: actor?.avatarUrl ?? "",
    userId: actor?.id ?? uid,
  });
  await batch.commit();
  return { following: true };
});

// ═══════════════════════════════════════════════════════════════════════════
// 5. onDuelVote
// ═══════════════════════════════════════════════════════════════════════════

export const onDuelVote = onDocumentCreated("duels/{duelId}/votes/{uid}", async (event) => {
  const vote = event.data?.data();
  if (!vote) return;
  const choice = vote.choice as string;
  const field = choice === "A" ? "votesA" : "votesB";
  await db.doc(`duels/${event.params.duelId}`).update({
    [field]: FieldValue.increment(1),
  }).catch(() => {});
});

// ═══════════════════════════════════════════════════════════════════════════
// 6. pingSceneView (callable, throttled par user)
// ═══════════════════════════════════════════════════════════════════════════

export const pingSceneView = onCall<{ sceneId: string }>(async (req) => {
  const uid = req.auth?.uid ?? "anon";
  const sceneId = req.data?.sceneId;
  if (!sceneId) throw new HttpsError("invalid-argument", "sceneId required");

  const throttleRef = db.doc(`scenes/${sceneId}/views/${uid}`);
  const existing = await throttleRef.get();
  const now = Date.now();
  if (existing.exists) {
    const last = (existing.data()?.lastAt?.toMillis?.() ?? 0) as number;
    if (now - last < 5 * 60 * 1000) {
      return { counted: false };
    }
  }
  await throttleRef.set({ lastAt: FieldValue.serverTimestamp() });
  await db.doc(`scenes/${sceneId}`).update({
    viewsCount: FieldValue.increment(1),
  }).catch(() => {});
  return { counted: true };
});

// ═══════════════════════════════════════════════════════════════════════════
// 7. sendPushOnNotificationCreate
// ═══════════════════════════════════════════════════════════════════════════

export const sendPushOnNotificationCreate = onDocumentCreated(
  "notifications/{uid}/items/{itemId}",
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data();
    if (!data) return;
    const userSnap = await db.doc(`users/${uid}`).get();
    const tokens = (userSnap.data()?.fcmTokens as string[] | undefined) ?? [];
    if (tokens.length === 0) return;

    const res = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Take30",
        body: (data.message as string) ?? (data.text as string) ?? "Nouvelle activité",
      },
      data: {
        type: (data.type as string) ?? "",
        sceneId: (data.sceneId as string) ?? "",
      },
    });
    // Nettoyage des tokens invalides
    const invalid: string[] = [];
    res.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code ?? "";
        if (code.includes("registration-token-not-registered") || code.includes("invalid-argument")) {
          invalid.push(tokens[i]);
        }
      }
    });
    if (invalid.length > 0) {
      await db.doc(`users/${uid}`).update({
        fcmTokens: FieldValue.arrayRemove(...invalid),
      }).catch(() => {});
    }
  }
);

// ═══════════════════════════════════════════════════════════════════════════
// 8. computeLeaderboard (planifié, toutes les heures)
//    Agrège les scènes selon la période et réécrit leaderboards/{period}/entries.
// ═══════════════════════════════════════════════════════════════════════════

interface LeaderboardPeriodCfg {
  period: "day" | "week" | "month" | "global";
  sinceMs: number;
}

function periodCutoffs(now: Date): LeaderboardPeriodCfg[] {
  const t = now.getTime();
  const day = 24 * 60 * 60 * 1000;
  return [
    { period: "day", sinceMs: t - day },
    { period: "week", sinceMs: t - 7 * day },
    { period: "month", sinceMs: t - 30 * day },
    { period: "global", sinceMs: 0 },
  ];
}

export const computeLeaderboard = onSchedule("every 60 minutes", async () => {
  const cfgs = periodCutoffs(new Date());
  for (const cfg of cfgs) {
    const since = admin.firestore.Timestamp.fromMillis(cfg.sinceMs);
    let q = db.collection("scenes")
      .where("status", "==", "published")
      .orderBy("likesCount", "desc")
      .limit(50);
    if (cfg.sinceMs > 0) {
      q = db.collection("scenes")
        .where("status", "==", "published")
        .where("createdAt", ">=", since)
        .orderBy("createdAt", "desc")
        .orderBy("likesCount", "desc")
        .limit(50);
    }
    const snap = await q.get();

    // Regroupe par auteur, somme likes
    const perUser = new Map<string, { score: number; scenes: number }>();
    snap.forEach((d) => {
      const data = d.data();
      const uid = data.authorId as string;
      const likes = (data.likesCount as number) ?? 0;
      const prev = perUser.get(uid) ?? { score: 0, scenes: 0 };
      perUser.set(uid, { score: prev.score + likes, scenes: prev.scenes + 1 });
    });

    const ranked = [...perUser.entries()]
      .sort((a, b) => b[1].score - a[1].score)
      .slice(0, 50);

    const colRef = db.collection(`leaderboards/${cfg.period}/entries`);
    // Purge avant réécriture
    const existing = await colRef.get();
    const batch = db.batch();
    existing.forEach((d) => batch.delete(d.ref));

    for (let i = 0; i < ranked.length; i++) {
      const [uid, stat] = ranked[i];
      const denorm = await getUserDenorm(uid);
      if (!denorm) continue;
      batch.set(colRef.doc(uid), {
        rank: i + 1,
        userDenorm: denorm,
        score: stat.score,
        scenesCount: stat.scenes,
        period: cfg.period,
        computedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    logger.info(`Leaderboard ${cfg.period}: ${ranked.length} entries`);
  }
});
