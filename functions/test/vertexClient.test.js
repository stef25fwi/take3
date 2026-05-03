const test = require('node:test');
const assert = require('node:assert/strict');

const {
  checkVertexSceneOperation,
  __vertexClientTestUtils,
  VertexResponseError,
} = require('../lib/veo/vertexClient');
const { parseDurationSeconds } = require('../lib/veo/shared');

function withEnv(values, fn) {
  const originals = Object.fromEntries(
    Object.keys(values).map((key) => [key, process.env[key]])
  );
  for (const [key, value] of Object.entries(values)) {
    if (value === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = value;
    }
  }
  return Promise.resolve()
    .then(fn)
    .finally(() => {
      for (const [key, value] of Object.entries(originals)) {
        if (value === undefined) {
          delete process.env[key];
        } else {
          process.env[key] = value;
        }
      }
    });
}

test('callVertexJson renvoie une erreur métier propre si Vertex retourne du HTML', async () => {
  const originalFetch = global.fetch;
  const originalProject = process.env.GOOGLE_CLOUD_PROJECT;
  const originalLocation = process.env.VERTEX_LOCATION;
  const originalModel = process.env.VEO_MODEL;
  const originalMock = process.env.VEO_USE_MOCK;
  const originalToken = process.env.GOOGLE_ACCESS_TOKEN;

  process.env.GOOGLE_CLOUD_PROJECT = 'take30';
  process.env.VERTEX_LOCATION = 'us-central1';
  process.env.VEO_MODEL = 'veo-3.1-fast-generate-001';
  process.env.VEO_USE_MOCK = 'false';
  process.env.GOOGLE_ACCESS_TOKEN = 'fake-oauth-token';

  global.fetch = async () => ({
    ok: false,
    status: 404,
    statusText: 'Not Found',
    headers: {
      get(name) {
        return name.toLowerCase() === 'content-type' ? 'text/html; charset=utf-8' : null;
      },
    },
    async text() {
      return '<!DOCTYPE html><html><body>Error 404</body></html>';
    },
  });

  try {
    await assert.rejects(
      () =>
        __vertexClientTestUtils.callVertexJson(
          'https://us-central1-aiplatform.googleapis.com/v1/projects/take30/locations/us-central1/publishers/google/models/veo-3.1-fast-generate-001:predictLongRunning',
          { method: 'POST', body: '{}' },
          'fake-api-key'
        ),
      (error) => {
        assert.ok(error instanceof VertexResponseError);
        assert.equal(error.details.httpStatus, 404);
        assert.equal(error.details.responseContentType, 'text/html; charset=utf-8');
        assert.equal(error.details.errorKind, 'non_json_response');
        assert.match(error.message, /page HTML au lieu d.un JSON|réponse non JSON/i);
        assert.doesNotMatch(error.message, /Unexpected token/i);
        assert.ok(error.details.responsePreview.length <= 600);
        return true;
      }
    );
  } finally {
    global.fetch = originalFetch;
    process.env.GOOGLE_CLOUD_PROJECT = originalProject;
    process.env.VERTEX_LOCATION = originalLocation;
    process.env.VEO_MODEL = originalModel;
    process.env.VEO_USE_MOCK = originalMock;
    process.env.GOOGLE_ACCESS_TOKEN = originalToken;
  }
});

test('checkVertexSceneOperation utilise fetchPredictOperation en POST', async () => {
  const originalFetch = global.fetch;
  let capturedUrl = '';
  let capturedInit = {};

  await withEnv({
    GOOGLE_CLOUD_PROJECT: 'take30',
    VERTEX_LOCATION: 'us-central1',
    VEO_MODEL: 'veo-3.1-fast-generate-001',
    VEO_USE_MOCK: 'false',
    GOOGLE_ACCESS_TOKEN: 'fake-oauth-token',
    VEO_AUTH_MODE: undefined,
  }, async () => {
    global.fetch = async (url, init) => {
      capturedUrl = String(url);
      capturedInit = init;
      return {
        ok: true,
        status: 200,
        statusText: 'OK',
        headers: { get: () => 'application/json' },
        async text() {
          return JSON.stringify({ done: false });
        },
      };
    };

    try {
      const result = await checkVertexSceneOperation(
        'projects/take30/locations/us-central1/publishers/google/models/veo-3.1-fast-generate-001/operations/op-123',
        'fake-api-key'
      );

      assert.equal(result.done, false);
      assert.equal(result.status, 'generating');
      assert.match(capturedUrl, /:fetchPredictOperation$/);
      assert.equal(capturedInit.method, 'POST');
      assert.deepEqual(JSON.parse(capturedInit.body), {
        operationName:
          'projects/take30/locations/us-central1/publishers/google/models/veo-3.1-fast-generate-001/operations/op-123',
      });
    } finally {
      global.fetch = originalFetch;
    }
  });
});

test('auth Vertex par défaut utilise Authorization Bearer et pas x-goog-api-key', async () => {
  const originalFetch = global.fetch;
  let capturedHeaders = {};

  await withEnv({
    GOOGLE_CLOUD_PROJECT: 'take30',
    VERTEX_LOCATION: 'us-central1',
    VEO_MODEL: 'veo-3.1-fast-generate-001',
    VEO_USE_MOCK: 'false',
    GOOGLE_ACCESS_TOKEN: 'fake-oauth-token',
    VEO_AUTH_MODE: undefined,
  }, async () => {
    global.fetch = async (_url, init) => {
      capturedHeaders = init.headers;
      return {
        ok: true,
        status: 200,
        statusText: 'OK',
        headers: { get: () => 'application/json' },
        async text() {
          return JSON.stringify({ ok: true });
        },
      };
    };

    try {
      await __vertexClientTestUtils.callVertexJson(
        'https://us-central1-aiplatform.googleapis.com/v1/test',
        { method: 'POST', body: '{}' },
        'fake-api-key'
      );

      assert.equal(capturedHeaders.Authorization, 'Bearer fake-oauth-token');
      assert.equal(capturedHeaders['x-goog-api-key'], undefined);
    } finally {
      global.fetch = originalFetch;
    }
  });
});

test('parseDurationSeconds accepte 4, 6, 8 et vaut 8 par défaut', () => {
  assert.equal(parseDurationSeconds(undefined), 8);
  assert.equal(parseDurationSeconds(4), 4);
  assert.equal(parseDurationSeconds(6), 6);
  assert.equal(parseDurationSeconds(8), 8);
  assert.throws(() => parseDurationSeconds(15), /durationSeconds doit valoir 4, 6 ou 8/);
});