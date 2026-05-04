import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  buildFirebaseDownloadUrl,
  db,
  getVertexVeoConfig,
  isAdminUid,
  isMockOperationId,
  MOCK_VEO_THUMBNAIL_URL,
  MOCK_VEO_VIDEO_URL,
  parseSceneId,
  readSceneDate,
  VeoSceneState,
  VEO_API_KEY,
} from "./shared";
import {
  checkVertexSceneOperation,
  copyVertexAssetToFirebaseStorage,
  VertexResponseError,
} from "./vertexClient";

function buildGenerationMetadata(
  scene: VeoSceneState,
  status: "queued" | "generating" | "completed" | "failed",
  fallbackUpdatedAt: Date,
  providerFallback: "mock" | "vertex"
) {
  const startedAt = readSceneDate(scene.generationStartedAt);
  const updatedAt = readSceneDate(scene.generationUpdatedAt) ?? fallbackUpdatedAt;
  const elapsedSeconds = startedAt == null
    ? scene.elapsedSeconds ?? null
    : Math.max(0, Math.floor((fallbackUpdatedAt.getTime() - startedAt.getTime()) / 1000));

  return {
    generationStatus: status,
    generationStartedAt: startedAt?.toISOString() ?? null,
    generationUpdatedAt: updatedAt.toISOString(),
    estimatedDurationSeconds: scene.estimatedDurationSeconds ?? null,
    elapsedSeconds,
    progressPercent: scene.progressPercent ?? (status === "completed" ? 100 : null),
    veoModel: scene.veoModel ?? null,
    provider: scene.veoProvider ?? providerFallback,
  };
}

export const checkVeoSceneGeneration = onCall({
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
  const sceneRef = db().doc(`scenes/${sceneId}`);
  const snap = await sceneRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "La scène demandée est introuvable.");
  }

  const scene = (snap.data() ?? {}) as VeoSceneState;
  const operationId = scene.veoOperationId ?? null;
  const currentStatus = scene.veoStatus ?? "none";
  const config = getVertexVeoConfig();
  const now = new Date();
  if (currentStatus === "completed" || currentStatus === "failed") {
    return {
      ok: true,
      sceneId,
      status: currentStatus,
      operationId,
      prompt: scene.veoPrompt ?? "",
      videoUrl: scene.videoUrl ?? null,
      thumbnailUrl: scene.thumbnailUrl ?? null,
      errorMessage: scene.veoError ?? null,
      durationSeconds: scene.durationSeconds ?? 8,
      aspectRatio: scene.aspectRatio ?? "16:9",
      updatedAt: now.toISOString(),
      ...buildGenerationMetadata(
        scene,
        currentStatus,
        now,
        isMockOperationId(operationId) || config.useMock ? "mock" : "vertex"
      ),
    };
  }

  if (!operationId) {
    throw new HttpsError(
      "failed-precondition",
      "Aucune operation VEO n'est associee a cette scene."
    );
  }
  if (isMockOperationId(operationId) || config.useMock) {
    const checks = (scene.veoMockChecks ?? 0) + 1;
    if (checks < 2) {
      await sceneRef.set(
        {
          veoStatus: "generating",
          veoMockChecks: checks,
          generationUpdatedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return {
        ok: true,
        sceneId,
        status: "generating",
        operationId,
        prompt: scene.veoPrompt ?? "",
        durationSeconds: scene.durationSeconds ?? 8,
        aspectRatio: scene.aspectRatio ?? "16:9",
        updatedAt: now.toISOString(),
        ...buildGenerationMetadata(scene, "generating", now, "mock"),
      };
    }

    await sceneRef.set(
      {
        veoStatus: "completed",
        veoMockChecks: checks,
        videoUrl: scene.videoUrl ?? MOCK_VEO_VIDEO_URL,
        thumbnailUrl: scene.thumbnailUrl ?? MOCK_VEO_THUMBNAIL_URL,
        veoError: FieldValue.delete(),
        generationUpdatedAt: FieldValue.serverTimestamp(),
        elapsedSeconds: buildGenerationMetadata(scene, "completed", now, "mock").elapsedSeconds,
        progressPercent: 100,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      ok: true,
      sceneId,
      status: "completed",
      operationId,
      prompt: scene.veoPrompt ?? "",
      videoUrl: scene.videoUrl ?? MOCK_VEO_VIDEO_URL,
      thumbnailUrl: scene.thumbnailUrl ?? MOCK_VEO_THUMBNAIL_URL,
      durationSeconds: scene.durationSeconds ?? 8,
      aspectRatio: scene.aspectRatio ?? "16:9",
      updatedAt: now.toISOString(),
      ...buildGenerationMetadata(scene, "completed", now, "mock"),
      progressPercent: 100,
    };
  }

  try {
    const apiKey = VEO_API_KEY.value();
    if (process.env.VEO_AUTH_MODE === "api_key" && !apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Le secret VEO_API_KEY est requis quand VEO_AUTH_MODE=api_key."
      );
    }

    const vertexResult = await checkVertexSceneOperation(operationId, apiKey);
    if (!vertexResult.done) {
      await sceneRef.set(
        {
          veoStatus: "generating",
          generationUpdatedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return {
        ok: true,
        sceneId,
        status: "generating",
        operationId,
        prompt: scene.veoPrompt ?? "",
        durationSeconds: scene.durationSeconds ?? 8,
        aspectRatio: scene.aspectRatio ?? "16:9",
        updatedAt: now.toISOString(),
        ...buildGenerationMetadata(scene, "generating", now, "vertex"),
      };
    }

    if (vertexResult.status === "failed") {
      const failureMeta = buildGenerationMetadata(scene, "failed", now, "vertex");
      await sceneRef.set(
        {
          veoStatus: "failed",
          veoError: vertexResult.errorMessage ?? "Erreur Vertex AI inconnue.",
          generationUpdatedAt: FieldValue.serverTimestamp(),
          elapsedSeconds: failureMeta.elapsedSeconds,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return {
        ok: true,
        sceneId,
        status: "failed",
        operationId,
        prompt: scene.veoPrompt ?? "",
        errorMessage: vertexResult.errorMessage ?? "Erreur Vertex AI inconnue.",
        durationSeconds: scene.durationSeconds ?? 8,
        aspectRatio: scene.aspectRatio ?? "16:9",
        updatedAt: now.toISOString(),
        ...failureMeta,
      };
    }

    const ownerId = scene.createdBy ?? uid;
    const videoPath = `scenes/${ownerId}/${sceneId}.mp4`;
    const thumbnailPath = `thumbnails/${ownerId}/${sceneId}.jpg`;
    const videoUrl = await copyVertexAssetToFirebaseStorage(
      vertexResult.sourceVideoUri!,
      videoPath
    );
    const thumbnailUrl = vertexResult.sourceThumbnailUri
      ? await copyVertexAssetToFirebaseStorage(
          vertexResult.sourceThumbnailUri,
          thumbnailPath
        )
      : scene.thumbnailUrl ?? buildFirebaseDownloadUrl(config.outputBucket, thumbnailPath);

    const completedMeta = buildGenerationMetadata(scene, "completed", now, "vertex");

    await sceneRef.set(
      {
        veoStatus: "completed",
        videoUrl,
        thumbnailUrl,
        veoError: FieldValue.delete(),
        generationUpdatedAt: FieldValue.serverTimestamp(),
        elapsedSeconds: completedMeta.elapsedSeconds,
        progressPercent: 100,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      ok: true,
      sceneId,
      status: "completed",
      operationId,
      prompt: scene.veoPrompt ?? "",
      videoUrl,
      thumbnailUrl,
      durationSeconds: scene.durationSeconds ?? 8,
      aspectRatio: scene.aspectRatio ?? "16:9",
      updatedAt: now.toISOString(),
      ...completedMeta,
      progressPercent: 100,
    };
  } catch (error) {
    const errorMessage = error instanceof VertexResponseError
      ? "Génération VEO impossible : Vertex AI a retourné une réponse non JSON / endpoint ou modèle inaccessible."
      : error instanceof Error
        ? error.message
        : "Erreur inconnue pendant la verification Vertex AI.";

    if (error instanceof VertexResponseError) {
      logger.error("veoCheckFailed", {
        modelId: error.details.modelId,
        location: error.details.location,
        httpStatus: error.details.httpStatus,
        statusText: error.details.statusText,
        endpoint: error.details.endpoint,
        responseContentType: error.details.responseContentType,
        responsePreview: error.details.responsePreview,
        errorKind: error.details.errorKind,
      });
    }

    const failureMeta = buildGenerationMetadata(scene, "failed", now, isMockOperationId(operationId) || config.useMock ? "mock" : "vertex");

    await sceneRef.set(
      {
        veoStatus: "failed",
        veoError: errorMessage,
        generationUpdatedAt: FieldValue.serverTimestamp(),
        elapsedSeconds: failureMeta.elapsedSeconds,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return {
      ok: true,
      sceneId,
      status: "failed",
      operationId,
      prompt: scene.veoPrompt ?? "",
      errorMessage,
      durationSeconds: scene.durationSeconds ?? 8,
      aspectRatio: scene.aspectRatio ?? "16:9",
      updatedAt: now.toISOString(),
      ...failureMeta,
    };
  }
});