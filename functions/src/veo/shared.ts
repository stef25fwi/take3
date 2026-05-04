import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

export const VEO_API_KEY = defineSecret("VEO_API_KEY");

export type VeoStatus = "none" | "queued" | "generating" | "completed" | "failed";

export interface VeoSceneState {
  createdBy?: string;
  veoStatus?: VeoStatus;
  veoPrompt?: string;
  veoOperationId?: string;
  veoError?: string;
  veoModel?: string;
  veoProvider?: string;
  videoUrl?: string;
  thumbnailUrl?: string;
  durationSeconds?: number;
  aspectRatio?: string;
  generationStartedAt?: Timestamp | Date | string;
  generationUpdatedAt?: Timestamp | Date | string;
  estimatedDurationSeconds?: number;
  elapsedSeconds?: number;
  progressPercent?: number;
  veoMockChecks?: number;
}

export const MOCK_VEO_VIDEO_URL = "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4";
export const MOCK_VEO_THUMBNAIL_URL =
  "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80";

export interface VertexVeoConfig {
  projectId: string;
  location: string;
  modelId: string;
  outputBucket: string;
  useMock: boolean;
}

export type VertexAuthMode = "service_account" | "api_key";

export function db() {
  return getFirestore();
}

export function getVertexVeoConfig(): VertexVeoConfig {
  const projectId =
    process.env.GOOGLE_CLOUD_PROJECT ?? process.env.GCLOUD_PROJECT ?? "";
  const location = process.env.VERTEX_LOCATION ?? "";
  const modelId = process.env.VEO_MODEL ?? process.env.VEO_MODEL_ID ?? "";
  const outputBucket =
    process.env.VEO_OUTPUT_BUCKET ??
    process.env.FIREBASE_STORAGE_BUCKET ??
    process.env.STORAGE_BUCKET ??
    "take30.firebasestorage.app";
  const useMock =
    process.env.VEO_USE_MOCK === "true" ||
    process.env.FUNCTIONS_EMULATOR === "true" ||
    !projectId ||
    !location ||
    !modelId;

  return {
    projectId,
    location,
    modelId,
    outputBucket,
    useMock,
  };
}

export function getVertexAuthMode(): VertexAuthMode {
  return process.env.VEO_AUTH_MODE === "api_key" ? "api_key" : "service_account";
}

export function buildFirebaseDownloadUrl(bucket: string, objectPath: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(objectPath)}?alt=media`;
}

export function isMockOperationId(operationId: string | undefined | null): boolean {
  return (operationId ?? "").startsWith("mock_");
}

export async function isAdminUid(uid: string): Promise<boolean> {
  const [adminSnap, userSnap] = await Promise.all([
    db().doc(`admins/${uid}`).get(),
    db().doc(`users/${uid}`).get(),
  ]);
  const userData = userSnap.data() as Record<string, unknown> | undefined;
  logger.info("isAdminUid", {
    uid,
    adminExists: adminSnap.exists,
    userIsAdmin: userData?.isAdmin,
    userRole: userData?.role,
  });
  if (adminSnap.exists) {
    return true;
  }
  return userData?.isAdmin === true || userData?.role === "admin";
}

export function parseSceneId(raw: unknown): string {
  const sceneId = typeof raw === "string" ? raw.trim() : "";
  if (!sceneId) {
    throw new HttpsError("invalid-argument", "sceneId est requis.");
  }
  return sceneId;
}

export function parsePrompt(raw: unknown): string {
  const prompt = typeof raw === "string" ? raw.trim() : "";
  if (!prompt) {
    throw new HttpsError("invalid-argument", "Le prompt VEO est requis.");
  }
  if (prompt.length > 4000) {
    throw new HttpsError("invalid-argument", "Le prompt VEO dépasse 4000 caractères.");
  }
  return prompt;
}

export function parseDurationSeconds(raw: unknown): 4 | 6 | 8 | 15 {
  const value = Number(raw ?? 15);
  if (value !== 4 && value !== 6 && value !== 8 && value !== 15) {
    throw new HttpsError("invalid-argument", "durationSeconds doit valoir 4, 6, 8 ou 15.");
  }
  return value as 4 | 6 | 8 | 15;
}

export function readSceneDate(raw: unknown): Date | null {
  if (raw instanceof Timestamp) {
    return raw.toDate();
  }
  if (raw instanceof Date) {
    return raw;
  }
  if (typeof raw === "string") {
    const parsed = new Date(raw);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  return null;
}

export function parseAspectRatio(raw: unknown): string {
  return typeof raw === "string" && raw.trim() ? raw.trim() : "16:9";
}