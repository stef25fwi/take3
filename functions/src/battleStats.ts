import { DocumentData, FieldValue, getFirestore, Transaction } from "firebase-admin/firestore";

export const battleConstants = {
  minRatedTakesForBattleEligibility: 3,
  maxActiveBattles: 2,
  maxWeeklyChallenges: 3,
  defaultSubmissionHours: 72,
  defaultVotingHours: 48,
  closeResultThresholdPercent: 5,
};

export interface BattleStats {
  uid: string;
  ratingAvg: number;
  ratingCount: number;
  activeBattlesCount: number;
  challengesSentThisWeek: number;
  battlesPlayed: number;
  battlesWon: number;
  battlesLost: number;
  battlesDraw: number;
  winStreak: number;
  bestWinStreak: number;
  battleRatingTier: string;
}

export function pairKey(userA: string, userB: string): string {
  return [userA, userB].sort().join("_");
}

export function defaultStats(uid: string): BattleStats {
  return {
    uid,
    ratingAvg: 0,
    ratingCount: 0,
    activeBattlesCount: 0,
    challengesSentThisWeek: 0,
    battlesPlayed: 0,
    battlesWon: 0,
    battlesLost: 0,
    battlesDraw: 0,
    winStreak: 0,
    bestWinStreak: 0,
    battleRatingTier: "Rookie",
  };
}

export function isBattleEligible(challenger: BattleStats, opponent: BattleStats): boolean {
  if (challenger.activeBattlesCount >= battleConstants.maxActiveBattles) return false;
  if (opponent.activeBattlesCount >= battleConstants.maxActiveBattles) return false;
  if (challenger.challengesSentThisWeek >= battleConstants.maxWeeklyChallenges) return false;
  if (challenger.ratingCount < battleConstants.minRatedTakesForBattleEligibility) return opponent.battleRatingTier === "Rookie";
  if (opponent.ratingCount < battleConstants.minRatedTakesForBattleEligibility) return challenger.battleRatingTier === "Rookie";
  const min = challenger.ratingAvg * 0.9;
  const max = challenger.ratingAvg * 1.1;
  return opponent.ratingAvg >= min && opponent.ratingAvg <= max;
}

export function ratingDeltaPercent(challengerAvg: number, opponentAvg: number): number {
  if (challengerAvg <= 0) return 0;
  return Math.abs(opponentAvg - challengerAvg) / challengerAvg * 100;
}

export async function readBattleStats(uid: string): Promise<BattleStats> {
  const snap = await getFirestore().doc(`userBattleStats/${uid}`).get();
  if (!snap.exists) return defaultStats(uid);
  const data = snap.data() ?? {};
  return {
    ...defaultStats(uid),
    ...data,
    uid,
    ratingAvg: Number(data.ratingAvg ?? 0),
    ratingCount: Number(data.ratingCount ?? 0),
    activeBattlesCount: Number(data.activeBattlesCount ?? 0),
    challengesSentThisWeek: Number(data.challengesSentThisWeek ?? 0),
  };
}

export function incrementActiveBattleStats(tx: Transaction, challengerId: string, opponentId: string): void {
  const db = getFirestore();
  tx.set(db.doc(`userBattleStats/${challengerId}`), {
    uid: challengerId,
    activeBattlesCount: FieldValue.increment(1),
    challengesSentThisWeek: FieldValue.increment(1),
    pendingChallengesCount: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  tx.set(db.doc(`userBattleStats/${opponentId}`), {
    uid: opponentId,
    pendingChallengesCount: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

export function updateBattleEndStats(tx: Transaction, battle: DocumentData): void {
  const db = getFirestore();
  const challengerId = battle.challengerId as string;
  const opponentId = battle.opponentId as string;
  const winnerId = battle.winnerId as string | undefined;
  const loserId = battle.loserId as string | undefined;
  const draw = !winnerId || !loserId;
  for (const uid of [challengerId, opponentId]) {
    tx.set(db.doc(`userBattleStats/${uid}`), {
      uid,
      battlesPlayed: FieldValue.increment(1),
      battlesDraw: draw ? FieldValue.increment(1) : FieldValue.increment(0),
      battlesWon: winnerId === uid ? FieldValue.increment(1) : FieldValue.increment(0),
      battlesLost: loserId === uid ? FieldValue.increment(1) : FieldValue.increment(0),
      winStreak: winnerId === uid ? FieldValue.increment(1) : 0,
      activeBattlesCount: FieldValue.increment(-1),
      lastBattleAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  const key = pairKey(challengerId, opponentId);
  tx.set(db.doc(`battleRivalries/${key}`), {
    pairKey: key,
    userAId: key.split("_")[0],
    userBId: key.split("_")[1],
    userAWins: winnerId === key.split("_")[0] ? FieldValue.increment(1) : FieldValue.increment(0),
    userBWins: winnerId === key.split("_")[1] ? FieldValue.increment(1) : FieldValue.increment(0),
    totalBattles: FieldValue.increment(1),
    closeBattlesCount: battle.isRevengeAvailable ? FieldValue.increment(1) : FieldValue.increment(0),
    lastBattleId: battle.id,
    lastBattleAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}
