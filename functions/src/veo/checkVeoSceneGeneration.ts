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
  VeoSceneState,
  VEO_API_KEY,
} from "./shared";
import {
  checkVertexSceneOperation,
  copyVertexAssetToFirebaseStorage,
  VertexResponseError,
} from "./vertexClient";

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
      updatedAt: new Date().toISOString(),
    };
  }

  if (!operationId) {
    throw new HttpsError(
      "failed-precondition",
      "Aucune operation VEO n'est associee a cette scene."
    );
  }

  const config = getVertexVeoConfig();
  if (isMockOperationId(operationId) || config.useMock) {
    const checks = (scene.veoMockChecks ?? 0) + 1;
    if (checks < 2) {
      await sceneRef.set(
        {
          veoStatus: "generating",
          veoMockChecks: checks,
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
        updatedAt: new Date().toISOString(),
      };
    }

    await sceneRef.set(
      {
        veoStatus: "completed",
        veoMockChecks: checks,
        videoUrl: scene.videoUrl ?? MOCK_VEO_VIDEO_URL,
        thumbnailUrl: scene.thumbnailUrl ?? MOCK_VEO_THUMBNAIL_URL,
        veoError: FieldValue.delete(),
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
      updatedAt: new Date().toISOString(),
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
        updatedAt: new Date().toISOString(),
      };
    }

    if (vertexResult.status === "failed") {
      await sceneRef.set(
        {
          veoStatus: "failed",
          veoError: vertexResult.errorMessage ?? "Erreur Vertex AI inconnue.",
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
        updatedAt: new Date().toISOString(),
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

    await sceneRef.set(
      {
        veoStatus: "completed",
        videoUrl,
        thumbnailUrl,
        veoError: FieldValue.delete(),
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
      updatedAt: new Date().toISOString(),
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

    await sceneRef.set(
      {
        veoStatus: "failed",
        veoError: errorMessage,
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
      updatedAt: new Date().toISOString(),
    };
  }
});