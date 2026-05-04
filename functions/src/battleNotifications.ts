import * as admin from "firebase-admin";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";

export type BattleNotificationType =
  | "battle_challenge_received"
  | "battle_challenge_accepted"
  | "battle_scene_assigned"
  | "battle_deadline_reminder"
  | "battle_published"
  | "followed_candidate_battle_published"
  | "battle_result"
  | "battle_revenge_available";

export interface BattleNotificationPayload {
  uid: string;
  type: BattleNotificationType;
  title: string;
  body: string;
  battleId: string;
  actorUid?: string;
  challengerId?: string;
  opponentId?: string;
}

export async function createBattleNotification(payload: BattleNotificationPayload): Promise<void> {
  await getFirestore().collection(`notifications/${payload.uid}/items`).add({
    type: payload.type,
    message: payload.title,
    subMessage: payload.body,
    body: payload.body,
    battleId: payload.battleId,
    actorUid: payload.actorUid ?? "",
    challengerId: payload.challengerId ?? "",
    opponentId: payload.opponentId ?? "",
    route: `/battle/${payload.battleId}`,
    isRead: false,
    read: false,
    time: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  });
}

export async function notifyBattleFollowers(
  battleId: string,
  payload: Omit<BattleNotificationPayload, "uid">,
): Promise<void> {
  const snap = await getFirestore().collection(`battles/${battleId}/followers`).limit(500).get();
  await Promise.all(
    snap.docs.map((doc) => createBattleNotification({ ...payload, uid: doc.id })),
  );
}

export async function notifyCandidateFollowers(
  candidateId: string,
  payload: Omit<BattleNotificationPayload, "uid">,
): Promise<void> {
  const snap = await getFirestore().collection(`users/${candidateId}/followers`).limit(500).get();
  await Promise.all(
    snap.docs.map((doc) => createBattleNotification({ ...payload, uid: doc.id })),
  );
}

export async function sendPushDataForBattleNotification(uid: string, data: Record<string, string>): Promise<void> {
  const userSnap = await getFirestore().doc(`users/${uid}`).get();
  const tokens = (userSnap.data()?.fcmTokens as string[] | undefined) ?? [];
  if (tokens.length === 0) return;
  const res = await admin.messaging().sendEachForMulticast({ tokens, data });
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
    await getFirestore().doc(`users/${uid}`).update({
      fcmTokens: FieldValue.arrayRemove(...invalid),
    }).catch((error) => logger.warn("battle.fcm.cleanup_failed", { uid, error }));
  }
}
