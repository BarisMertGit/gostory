const {test} = require('node:test');
const assert = require('node:assert/strict');
const {distanceKm} = require('./distance');
test('nearby matching handles distance and the date line', () => {
  assert.equal(distanceKm({latitude:41,longitude:29}, {latitude:41,longitude:29}), 0);
  assert.ok(distanceKm({latitude:41,longitude:29}, {latitude:41.02,longitude:29}) > 1);
  assert.ok(distanceKm({latitude:0,longitude:179.999}, {latitude:0,longitude:-179.999}) < 1);
});
