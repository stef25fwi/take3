import * as admin from "firebase-admin";

import { buildFirebaseDownloadUrl, getVertexVeoConfig } from "./shared";

const METADATA_TOKEN_URL =
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token";

interface VertexStartInput {
  sceneId: string;
  prompt: string;
  durationSeconds: 15 | 30;
  aspectRatio: string;
}

interface VertexStartResult {
  operationId: string;
  status: "queued";
  provider: "vertex" | "mock";
}

interface VertexOperationResult {
  done: boolean;
  status: "generating" | "completed" | "failed";
  errorMessage?: string;
  sourceVideoUri?: string;
  sourceThumbnailUri?: string;
}

interface GcsUriParts {
  bucket: string;
  objectPath: string;
}

export async function startVertexSceneGeneration(
  input: VertexStartInput,
  apiKey: string
): Promise<VertexStartResult> {
  const config = getVertexVeoConfig();
  if (config.useMock) {
    return {
      operationId: `mock_${Date.now()}_${input.sceneId}`,
      status: "queued",
      provider: "mock",
    };
  }

  const endpoint =
    process.env.VEO_START_ENDPOINT_URL ??
    `https://${config.location}-aiplatform.googleapis.com/v1/projects/${config.projectId}/locations/${config.location}/publishers/google/models/${config.modelId}:predictLongRunning`;

  const response = await callVertexJson(endpoint, {
    method: "POST",
    body: JSON.stringify({
      instances: [
        {
          prompt: input.prompt,
        },
      ],
      parameters: {
        durationSeconds: input.durationSeconds,
        aspectRatio: input.aspectRatio,
      },
    }),
  }, apiKey);

  const operationId = typeof response.name === "string" ? response.name : "";
  if (!operationId) {
    throw new Error(
      "Vertex AI n'a pas retourne de nom d'operation. Verifie le contrat du modele VEO configure."
    );
  }

  return {
    operationId,
    status: "queued",
    provider: "vertex",
  };
}

export async function checkVertexSceneOperation(
  operationId: string,
  apiKey: string
): Promise<VertexOperationResult> {
  const config = getVertexVeoConfig();
  if (config.useMock) {
    throw new Error(
      "Vertex AI n'est pas configure dans cet environnement. Definis GOOGLE_CLOUD_PROJECT, VERTEX_LOCATION, VEO_MODEL_ID et VEO_USE_MOCK=false."
    );
  }

  const operationPath = operationId.startsWith("projects/")
    ? operationId
    : operationId.replace(/^https?:\/\/[^/]+\/v1\//, "");
  const endpoint = `https://${config.location}-aiplatform.googleapis.com/v1/${operationPath}`;
  const payload = await callVertexJson(endpoint, { method: "GET" }, apiKey);

  if (payload.error) {
    return {
      done: true,
      status: "failed",
      errorMessage:
        payload.error.message ?? "L'operation Vertex AI a retourne une erreur.",
    };
  }

  if (!payload.done) {
    return {
      done: false,
      status: "generating",
    };
  }

  const sourceVideoUri = findBestUri(payload, [".mp4"], ["video", "uri", "url", "output"]);
  const sourceThumbnailUri = findBestUri(
    payload,
    [".jpg", ".jpeg", ".png", ".webp"],
    ["thumbnail", "poster", "image", "preview"]
  );

  if (!sourceVideoUri) {
    return {
      done: true,
      status: "failed",
      errorMessage:
        "L'operation Vertex AI est terminee mais aucun asset video n'a ete detecte dans la reponse. Verifie le schema du modele VEO configure.",
    };
  }

  return {
    done: true,
    status: "completed",
    sourceVideoUri,
    sourceThumbnailUri,
  };
}

export async function copyVertexAssetToFirebaseStorage(
  sourceUri: string,
  destinationPath: string
): Promise<string> {
  const config = getVertexVeoConfig();
  const destinationBucket = admin.storage().bucket(config.outputBucket);
  const source = parseGcsUri(sourceUri);
  if (!source) {
    throw new Error(
      "Le resultat Vertex AI ne contient pas de gs:// URI exploitable pour une copie vers Firebase Storage."
    );
  }

  if (source.bucket === config.outputBucket && source.objectPath === destinationPath) {
    return buildFirebaseDownloadUrl(config.outputBucket, destinationPath);
  }

  await admin
    .storage()
    .bucket(source.bucket)
    .file(source.objectPath)
    .copy(destinationBucket.file(destinationPath));

  return buildFirebaseDownloadUrl(config.outputBucket, destinationPath);
}

async function callVertexJson(
  url: string,
  init: { method: string; body?: string },
  apiKey: string
): Promise<Record<string, any>> {
  const token = await getAccessToken();
  const response = await fetch(url, {
    method: init.method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    },
    body: init.body,
  });

  const rawText = await response.text();
  const payload = rawText ? (JSON.parse(rawText) as Record<string, any>) : {};
  if (!response.ok) {
    const message =
      payload.error?.message ??
      payload.message ??
      `Vertex AI a repondu ${response.status}.`;
    throw new Error(message);
  }
  return payload;
}

async function getAccessToken(): Promise<string> {
  if (process.env.GOOGLE_ACCESS_TOKEN) {
    return process.env.GOOGLE_ACCESS_TOKEN;
  }

  const response = await fetch(METADATA_TOKEN_URL, {
    headers: {
      "Metadata-Flavor": "Google",
    },
  });
  if (!response.ok) {
    throw new Error(
      "Impossible d'obtenir un access token ADC depuis le metadata server."
    );
  }
  const payload = (await response.json()) as { access_token?: string };
  if (!payload.access_token) {
    throw new Error("Le metadata server n'a pas retourne d'access_token.");
  }
  return payload.access_token;
}

function parseGcsUri(uri: string): GcsUriParts | null {
  if (!uri.startsWith("gs://")) {
    return null;
  }
  const withoutScheme = uri.slice(5);
  const slashIndex = withoutScheme.indexOf("/");
  if (slashIndex <= 0) {
    return null;
  }
  return {
    bucket: withoutScheme.slice(0, slashIndex),
    objectPath: withoutScheme.slice(slashIndex + 1),
  };
}

function findBestUri(
  value: unknown,
  extensions: string[],
  preferredKeys: string[]
): string | undefined {
  const candidates = collectStringCandidates(value);
  const normalizedExts = extensions.map((entry) => entry.toLowerCase());
  const normalizedKeys = preferredKeys.map((entry) => entry.toLowerCase());

  const exact = candidates.find((candidate) => {
    const pathKey = candidate.path.join(".").toLowerCase();
    const uri = candidate.value.toLowerCase();
    const matchesKey = normalizedKeys.some((key) => pathKey.includes(key));
    const matchesExt = normalizedExts.some((ext) => uri.includes(ext));
    return matchesKey && matchesExt;
  });
  if (exact) {
    return exact.value;
  }

  const byExtension = candidates.find((candidate) => {
    const uri = candidate.value.toLowerCase();
    return normalizedExts.some((ext) => uri.includes(ext));
  });
  if (byExtension) {
    return byExtension.value;
  }

  const byKey = candidates.find((candidate) => {
    const pathKey = candidate.path.join(".").toLowerCase();
    return normalizedKeys.some((key) => pathKey.includes(key));
  });
  return byKey?.value;
}

function collectStringCandidates(
  value: unknown,
  path: string[] = []
): Array<{ path: string[]; value: string }> {
  if (typeof value === "string") {
    if (value.startsWith("gs://") || value.startsWith("https://") || value.startsWith("http://")) {
      return [{ path, value }];
    }
    return [];
  }

  if (Array.isArray(value)) {
    return value.flatMap((entry, index) =>
      collectStringCandidates(entry, [...path, String(index)])
    );
  }

  if (value && typeof value === "object") {
    return Object.entries(value as Record<string, unknown>).flatMap(([key, entry]) =>
      collectStringCandidates(entry, [...path, key])
    );
  }

  return [];
}