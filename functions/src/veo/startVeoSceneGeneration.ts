import { FieldValue } from "firebase-admin/firestore";
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
import { startVertexSceneGeneration } from "./vertexClient";

export const startVeoSceneGeneration = onCall({ secrets: [VEO_API_KEY] }, async (req) => {
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
  if (!config.useMock && !apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "Le secret VEO_API_KEY est requis quand VEO_USE_MOCK=false."
    );
  }
  const startResult = await startVertexSceneGeneration({
    sceneId,
    prompt,
    durationSeconds,
    aspectRatio,
  }, apiKey);

  await db().doc(`scenes/${sceneId}`).set(
    {
      id: sceneId,
      createdBy: uid,
      veoPrompt: prompt,
      veoStatus: "queued",
      veoOperationId: startResult.operationId,
      veoError: FieldValue.delete(),
      durationSeconds,
      aspectRatio,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    ok: true,
    sceneId,
    operationId: startResult.operationId,
    status: startResult.status,
    prompt,
    durationSeconds,
    aspectRatio,
    vertexLocation: config.location || "TODO_VERTEX_LOCATION",
    modelId: config.modelId || "TODO_VEO_MODEL_ID",
    provider: startResult.provider,
  };
});