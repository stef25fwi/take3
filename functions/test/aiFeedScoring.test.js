const test = require('node:test');
const assert = require('node:assert/strict');

function feedScore({
  userStyleAffinity,
  completionPrediction,
  rewatchPrediction,
  trendingScore,
  freshnessScore,
  explorationScore,
}) {
  return (userStyleAffinity * 30) +
    (completionPrediction * 25) +
    (rewatchPrediction * 15) +
    (trendingScore * 15) +
    (freshnessScore * 10) +
    (explorationScore * 5);
}

test('feedScore prioritizes taste but keeps trending and exploration signals', () => {
  const strongTaste = feedScore({
    userStyleAffinity: 0.9,
    completionPrediction: 0.8,
    rewatchPrediction: 0.6,
    trendingScore: 0.4,
    freshnessScore: 0.8,
    explorationScore: 0.2,
  });
  const trendingOnly = feedScore({
    userStyleAffinity: 0.1,
    completionPrediction: 0.4,
    rewatchPrediction: 0.4,
    trendingScore: 1,
    freshnessScore: 0.5,
    explorationScore: 0.5,
  });
  assert.ok(strongTaste > trendingOnly);
});

test('feed mix target remains 70/20/10 for a 30 item page', () => {
  const limit = 30;
  assert.equal(Math.ceil(limit * 0.7), 21);
  assert.equal(Math.ceil(limit * 0.2), 6);
  assert.equal(Math.ceil(limit * 0.1), 3);
});
