import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  db,
  getVertexVeoConfig,
  isAdminUid,
  parseAspectRatio,
  parseDurationSeconds,
  parsePrompt,
  parseSceneId,
  VEO_API_KEY,
} from "./shared";
import { startVertexSceneGeneration, VertexResponseError } from "./vertexClient";

export const startVeoSceneGeneration = onCall({
  secrets: [VEO_API_KEY],
  cors: true,
  region: "europe-west1",
}, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  if (!(await isAdminUid(uid))) {
    throw new HttpsError("permission-denied", "Le rôle admin est requis.");
  }

  const sceneId = parseSceneId(req.data?.sceneId);
  const prompt = parsePrompt(req.data?.prompt);
  const durationSeconds = parseDurationSeconds(req.data?.durationSeconds);
  const aspectRatio = parseAspectRatio(req.data?.aspectRatio);
  const config = getVertexVeoConfig();
  const apiKey = config.useMock ? "" : VEO_API_KEY.value();
  if (!config.useMock && process.env.VEO_AUTH_MODE === "api_key" && !apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "Le secret VEO_API_KEY est requis quand VEO_AUTH_MODE=api_key."
    );
  }
  let startResult;
  try {
    startResult = await startVertexSceneGeneration({
      sceneId,
      prompt,
      durationSeconds,
      aspectRatio,
    }, apiKey);
  } catch (error) {
    if (error instanceof VertexResponseError) {
      logger.error("veoStartFailed", {
        modelId: error.details.modelId,
        location: error.details.location,
        httpStatus: error.details.httpStatus,
        statusText: error.details.statusText,
        endpoint: error.details.endpoint,
        responseContentType: error.details.responseContentType,
        responsePreview: error.details.responsePreview,
        errorKind: error.details.errorKind,
      });
      throw new HttpsError(
        "unavailable",
        "Génération VEO impossible : Vertex AI a retourné une réponse non JSON / endpoint ou modèle inaccessible.",
        error.details
      );
    }

    logger.error("veoStartFailed", {
      modelId: config.modelId,
      location: config.location,
      error: error instanceof Error ? error.message : String(error),
    });
    throw new HttpsError(
      "unavailable",
      "Génération VEO impossible : Vertex AI est inaccessible ou mal configuré."
    );
  }

  const nowIso = new Date().toISOString();

  await db().doc(`scenes/${sceneId}`).set(
    {
      id: sceneId,
      createdBy: uid,
      veoPrompt: prompt,
      veoStatus: "queued",
      veoOperationId: startResult.operationId,
      veoModel: config.modelId || null,
      veoProvider: startResult.provider,
      veoError: FieldValue.delete(),
      durationSeconds,
      aspectRatio,
      generationStartedAt: FieldValue.serverTimestamp(),
      generationUpdatedAt: FieldValue.serverTimestamp(),
      estimatedDurationSeconds: FieldValue.delete(),
      elapsedSeconds: 0,
      progressPercent: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    ok: true,
    sceneId,
    operationId: startResult.operationId,
    status: startResult.status,
    generationStatus: startResult.status,
    prompt,
    durationSeconds,
    aspectRatio,
    generationStartedAt: nowIso,
    generationUpdatedAt: nowIso,
    elapsedSeconds: 0,
    estimatedDurationSeconds: null,
    progressPercent: null,
    vertexLocation: config.location || "TODO_VERTEX_LOCATION",
    modelId: config.modelId || "TODO_VEO_MODEL_ID",
    veoModel: config.modelId || null,
    provider: startResult.provider,
  };
});