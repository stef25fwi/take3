import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onObjectFinalized } from "firebase-functions/v2/storage";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

const db = getFirestore();

function transcodeEndpoint(): string {
  return (process.env.TAKE60_TRANSCODER_URL ?? "").trim();
}

function transcodeToken(): string {
  return (process.env.TAKE60_TRANSCODER_TOKEN ?? "").trim();
}

async function dispatchTake60Transcode(videoId: string) {
  const endpoint = transcodeEndpoint();
  if (!endpoint) {
    throw new HttpsError(
      "failed-precondition",
      "TAKE60_TRANSCODER_URL n'est pas configuré."
    );
  }

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  const token = transcodeToken();
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers,
    body: JSON.stringify({ videoId }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new HttpsError(
      "internal",
      `Cloud Run transcoder error (${response.status}): ${text.slice(0, 400)}`
    );
  }
}

export const requestTake60VideoTranscode = onCall<{ videoId: string }>(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Auth required");
  }

  const videoId = (req.data?.videoId ?? "").trim();
  if (!videoId) {
    throw new HttpsError("invalid-argument", "videoId required");
  }

  const videoRef = db.doc(`take60_videos/${videoId}`);
  const videoSnap = await videoRef.get();
  if (!videoSnap.exists) {
    throw new HttpsError("not-found", "Take60 video not found");
  }
  const video = videoSnap.data() ?? {};
  const ownerId = String(video.ownerId ?? "");
  if (ownerId != uid) {
    throw new HttpsError("permission-denied", "Not owner of this video");
  }

  await videoRef.set(
    {
      status: "processing",
      processingRequestedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await dispatchTake60Transcode(videoId);
  return { accepted: true };
});

export const getTake60PlayableUrl = onCall<{ videoId: string }>(async (req) => {
  const videoId = (req.data?.videoId ?? "").trim();
  if (!videoId) {
    throw new HttpsError("invalid-argument", "videoId required");
  }

  const videoSnap = await db.doc(`take60_videos/${videoId}`).get();
  if (!videoSnap.exists) {
    throw new HttpsError("not-found", "Take60 video not found");
  }

  const video = videoSnap.data() ?? {};
  const userPlan = req.auth?.uid
    ? String((await db.doc(`users/${req.auth.uid}`).get()).data()?.plan ?? "free")
    : "free";
  const isPremium = userPlan === "premium";

  const playableUrl = isPremium
    ? String(video.hlsMasterUrl ?? video.hlsPremiumUrl ?? video.hlsBaseUrl ?? "")
    : String(video.hlsBaseUrl ?? video.hlsMasterUrl ?? video.hlsPremiumUrl ?? "");

  return {
    videoId,
    plan: userPlan,
    playableUrl,
    status: String(video.status ?? "processing"),
    isPremiumLocked: Boolean(video.isPremiumLocked ?? true),
  };
});

export const onTake60RawUploadCreated = onObjectFinalized(
  {
    bucket: getStorage().bucket().name,
    region: "europe-west1",
  },
  async (event) => {
    const objectName = event.data.name ?? "";
    const match = objectName.match(/^take60\/raw_uploads\/([^/]+)\/([^/]+)\.mp4$/);
    if (!match) {
      return;
    }

    const videoId = match[2];
    const videoRef = db.doc(`take60_videos/${videoId}`);
    const videoSnap = await videoRef.get();
    if (!videoSnap.exists) {
      return;
    }

    const data = videoSnap.data() ?? {};
    if (String(data.status ?? "") === "ready") {
      return;
    }

    await videoRef.set(
      {
        status: "processing",
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await dispatchTake60Transcode(videoId);
  }
);