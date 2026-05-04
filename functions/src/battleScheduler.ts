import * as admin from "firebase-admin";
import { DocumentData, FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";

import { battleConstants, updateBattleEndStats } from "./battleStats";
import { createBattleNotification, notifyBattleFollowers } from "./battleNotifications";
import { buildBattleScorePatch } from "./battleScoring";

const battleReminderWindowMs = 2 * 60 * 60 * 1000;

function ensureAdminInitialized(): void {
  if (admin.apps.length === 0) {
    admin.initializeApp({
      projectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "take30",
    });
  }
}

export const expireBattleDeadlines = onSchedule("every 30 minutes", async () => {
  await expireBattleDeadlinesOnce();
});

export async function expireBattleDeadlinesOnce(): Promise<void> {
  ensureAdminInitialized();
  const db = getFirestore();
  const now = Timestamp.now();
  const snap = await db.collection("battles")
    .where("status", "in", ["in_preparation", "waiting_challenger_submission", "waiting_opponent_submission"])
    .where("submissionDeadline", "<", now)
    .limit(50)
    .get();

  for (const doc of snap.docs) {
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists) return;
      const battle = fresh.data() ?? {};
      const now = new Date();
      const challengerReady = Boolean(battle.challengerVideoUrl);
      const opponentReady = Boolean(battle.opponentVideoUrl);
      const patch: Record<string, unknown> = {
        endedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (challengerReady && !opponentReady) {
        patch.status = "forfeit";
        patch.winnerId = battle.challengerId;
        patch.loserId = battle.opponentId;
        patch.resultReason = "forfeit";
      } else if (!challengerReady && opponentReady) {
        patch.status = "forfeit";
        patch.winnerId = battle.opponentId;
        patch.loserId = battle.challengerId;
        patch.resultReason = "forfeit";
      } else {
        patch.status = "cancelled";
        patch.resultReason = "cancelled";
        patch.cancelledAt = FieldValue.serverTimestamp();
      }
      const scoredBattle = {
        ...battle,
        ...patch,
        endedAt: now,
        cancelledAt: patch.cancelledAt ? now : battle.cancelledAt,
        updatedAt: now,
      };
      tx.update(doc.ref, {
        ...patch,
        ...buildBattleScorePatch(scoredBattle, now),
      });
      updateBattleEndStats(tx, { ...scoredBattle, id: doc.id });
    });
    logger.info("battle.deadline.expired", { battleId: doc.id });
  }
}

export const endVotingBattles = onSchedule("every 30 minutes", async () => {
  await endVotingBattlesOnce();
});

export async function endVotingBattlesOnce(): Promise<void> {
  ensureAdminInitialized();
  const db = getFirestore();
  const now = Timestamp.now();
  const snap = await db.collection("battles")
    .where("status", "==", "voting_open")
    .where("votingEndsAt", "<", now)
    .limit(50)
    .get();

  for (const doc of snap.docs) {
    let result: DocumentData | undefined;
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists) return;
      const battle = fresh.data() ?? {};
      const nowDate = new Date();
      const challengerVotes = Number(battle.votesChallenger ?? 0);
      const opponentVotes = Number(battle.votesOpponent ?? 0);
      const totalVotes = Number(battle.totalVotes ?? challengerVotes + opponentVotes);
      const deltaPercent = totalVotes <= 0 ? 0 : Math.abs(challengerVotes - opponentVotes) / totalVotes * 100;
        const close = deltaPercent <= battleConstants.closeResultThresholdPercent;
      const patch: Record<string, unknown> = {
        status: "ended",
        endedAt: FieldValue.serverTimestamp(),
        resultReason: challengerVotes === opponentVotes ? "tie" : "votes",
        isRevengeAvailable: close,
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (challengerVotes > opponentVotes) {
        patch.winnerId = battle.challengerId;
        patch.loserId = battle.opponentId;
      } else if (opponentVotes > challengerVotes) {
        patch.winnerId = battle.opponentId;
        patch.loserId = battle.challengerId;
      }
      const scoredBattle = {
        ...battle,
        ...patch,
        endedAt: nowDate,
        updatedAt: nowDate,
      };
      tx.update(doc.ref, {
        ...patch,
        ...buildBattleScorePatch(scoredBattle, nowDate),
      });
      result = { ...scoredBattle, id: doc.id };
      updateBattleEndStats(tx, result);
    });
    if (result) {
      await Promise.all([
        createBattleNotification({ uid: result.challengerId as string, type: "battle_result", title: "Le public a tranché", body: `Résultat disponible pour ${result.challengerName} vs ${result.opponentName}.`, battleId: doc.id }),
        createBattleNotification({ uid: result.opponentId as string, type: "battle_result", title: "Le public a tranché", body: `Résultat disponible pour ${result.challengerName} vs ${result.opponentName}.`, battleId: doc.id }),
        notifyBattleFollowers(doc.id, { type: "battle_result", title: "Le public a tranché", body: `Résultat disponible pour ${result.challengerName} vs ${result.opponentName}.`, battleId: doc.id }),
      ]);
    }
    logger.info("battle.voting.ended", { battleId: doc.id });
  }
}

export const sendBattleReminders = onSchedule("every 30 minutes", async () => {
  await sendBattleRemindersOnce();
});

export async function sendBattleRemindersOnce(): Promise<void> {
  ensureAdminInitialized();
  const db = getFirestore();
  const now = new Date();
  const nowTs = Timestamp.fromDate(now);
  const cutoff = Timestamp.fromMillis(now.getTime() + battleReminderWindowMs);

  const submissionSnap = await db.collection("battles")
    .where("status", "in", ["in_preparation", "waiting_challenger_submission", "waiting_opponent_submission"])
    .where("submissionDeadline", ">", nowTs)
    .where("submissionDeadline", "<=", cutoff)
    .limit(50)
    .get();

  for (const doc of submissionSnap.docs) {
    const battle = doc.data() ?? {};
    if (battle.submissionReminderSentAt) continue;
    const notifications: Array<Promise<void>> = [];
    if (!battle.challengerVideoUrl && battle.challengerId) {
      notifications.push(
        createBattleNotification({
          uid: battle.challengerId as string,
          type: "battle_deadline_reminder",
          title: "Plus beaucoup de temps pour publier",
          body: `Ta performance pour ${battle.challengerName} vs ${battle.opponentName} doit être envoyée bientôt.`,
          battleId: doc.id,
        }),
      );
    }
    if (!battle.opponentVideoUrl && battle.opponentId) {
      notifications.push(
        createBattleNotification({
          uid: battle.opponentId as string,
          type: "battle_deadline_reminder",
          title: "Plus beaucoup de temps pour publier",
          body: `Ta performance pour ${battle.challengerName} vs ${battle.opponentName} doit être envoyée bientôt.`,
          battleId: doc.id,
        }),
      );
    }
    if (notifications.length === 0) continue;
    await Promise.all(notifications);
    await doc.ref.update({ submissionReminderSentAt: FieldValue.serverTimestamp() });
    logger.info("battle.submission.reminder_sent", { battleId: doc.id });
  }

  const votingSnap = await db.collection("battles")
    .where("status", "==", "voting_open")
    .where("votingEndsAt", ">", nowTs)
    .where("votingEndsAt", "<=", cutoff)
    .limit(50)
    .get();

  for (const doc of votingSnap.docs) {
    const battle = doc.data() ?? {};
    if (battle.votingReminderSentAt) continue;
    await Promise.all([
      createBattleNotification({
        uid: battle.challengerId as string,
        type: "battle_vote_reminder",
        title: "Le vote se termine bientôt",
        body: `Le public va bientôt trancher pour ${battle.challengerName} vs ${battle.opponentName}.`,
        battleId: doc.id,
      }),
      createBattleNotification({
        uid: battle.opponentId as string,
        type: "battle_vote_reminder",
        title: "Le vote se termine bientôt",
        body: `Le public va bientôt trancher pour ${battle.challengerName} vs ${battle.opponentName}.`,
        battleId: doc.id,
      }),
      notifyBattleFollowers(doc.id, {
        type: "battle_vote_reminder",
        title: "Derniers votes pour cette Battle",
        body: `${battle.challengerName} vs ${battle.opponentName} arrive à sa fin.`,
        battleId: doc.id,
      }),
    ]);
    await doc.ref.update({ votingReminderSentAt: FieldValue.serverTimestamp() });
    logger.info("battle.voting.reminder_sent", { battleId: doc.id });
  }
}
