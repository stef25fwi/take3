const test = require('node:test');
const assert = require('node:assert/strict');

const { isBattleEligible, defaultStats, pairKey } = require('../lib/battleStats.js');

test('isBattleEligible refuses rating outside +/- 10%', () => {
  const challenger = { ...defaultStats('u1'), ratingAvg: 80, ratingCount: 5 };
  const opponent = { ...defaultStats('u2'), ratingAvg: 60, ratingCount: 5 };
  assert.equal(isBattleEligible(challenger, opponent), false);
});

test('isBattleEligible accepts close ratings', () => {
  const challenger = { ...defaultStats('u1'), ratingAvg: 80, ratingCount: 5 };
  const opponent = { ...defaultStats('u2'), ratingAvg: 86, ratingCount: 5 };
  assert.equal(isBattleEligible(challenger, opponent), true);
});

test('pairKey is stable and sorted', () => {
  assert.equal(pairKey('z', 'a'), 'a_z');
});
