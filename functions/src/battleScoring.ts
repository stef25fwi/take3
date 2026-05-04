import { Timestamp } from "firebase-admin/firestore";

const statusScoreMap: Record<string, number> = {
  challenge_sent: 6,
  accepted: 8,
  scene_assigned: 10,
  in_preparation: 12,
  waiting_challenger_submission: 14,
  waiting_opponent_submission: 14,
  ready_to_publish: 16,
  published: 18,
  voting_open: 24,
  ended: 8,
  forfeit: 4,
  cancelled: 2,
  declined: 1,
};

function readNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function readBattleDate(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value);
  }
  if (typeof value === "object" && value !== null && "toDate" in value && typeof (value as { toDate?: unknown }).toDate === "function") {
    return ((value as { toDate: () => Date }).toDate());
  }
  return null;
}

function roundScore(value: number): number {
  return Math.round(Math.max(0, value) * 10) / 10;
}

export function buildBattleScorePatch(
  battle: Record<string, unknown>,
  now: Date = new Date(),
): Record<string, number> {
  const status = String(battle.status ?? "challenge_sent");
  const followersCount = Math.max(0, readNumber(battle.followersCount));
  const predictionsCount = Math.max(0, readNumber(battle.predictionsCount));
  const commentsCount = Math.max(0, readNumber(battle.commentsCount));
  const totalVotes = Math.max(0, readNumber(battle.totalVotes));
  const rawWatchersCount = Math.max(0, readNumber(battle.watchersCount));
  const watchersCount = Math.max(rawWatchersCount, followersCount);
  const isFeatured = battle.isFeatured === true;
  const hasChallengerVideo = Boolean(battle.challengerVideoUrl);
  const hasOpponentVideo = Boolean(battle.opponentVideoUrl);
  const videoReadyBonus = (hasChallengerVideo ? 4 : 0) + (hasOpponentVideo ? 4 : 0);
  const statusBoost = statusScoreMap[status] ?? 0;
  const featuredBoost = isFeatured ? 12 : 0;

  const referenceDate =
    readBattleDate(battle.publishedAt) ??
    readBattleDate(battle.updatedAt) ??
    readBattleDate(battle.createdAt) ??
    now;
  const ageHours = Math.max(0, (now.getTime() - referenceDate.getTime()) / (60 * 60 * 1000));
  const freshnessBase =
    status === "voting_open" ? 18 :
    status === "published" ? 14 :
    status === "ready_to_publish" ? 10 :
    status === "in_preparation" || status === "waiting_challenger_submission" || status === "waiting_opponent_submission" ? 8 :
    status === "challenge_sent" ? 6 : 0;
  const freshnessBonus = Math.max(0, freshnessBase - ageHours * 0.5);

  const battleScore =
    followersCount * 2 +
    predictionsCount * 3 +
    commentsCount * 4 +
    totalVotes * 5 +
    videoReadyBonus +
    statusBoost +
    featuredBoost;

  const trendingScore =
    battleScore + freshnessBonus + (status === "voting_open" ? Math.min(12, totalVotes * 1.5) : 0);

  return {
    watchersCount,
    battleScore: roundScore(battleScore),
    trendingScore: roundScore(trendingScore),
  };
}