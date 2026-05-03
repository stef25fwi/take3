const test = require('node:test');
const assert = require('node:assert/strict');

const {
  __vertexClientTestUtils,
  VertexResponseError,
} = require('../lib/veo/vertexClient');

test('callVertexJson renvoie une erreur métier propre si Vertex retourne du HTML', async () => {
  const originalFetch = global.fetch;
  const originalProject = process.env.GOOGLE_CLOUD_PROJECT;
  const originalLocation = process.env.VERTEX_LOCATION;
  const originalModel = process.env.VEO_MODEL;
  const originalMock = process.env.VEO_USE_MOCK;

  process.env.GOOGLE_CLOUD_PROJECT = 'take30';
  process.env.VERTEX_LOCATION = 'us-central1';
  process.env.VEO_MODEL = 'veo-3.1-fast-generate-001';
  process.env.VEO_USE_MOCK = 'false';

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
  }
});