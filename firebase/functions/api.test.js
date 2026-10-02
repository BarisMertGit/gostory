const {test} = require('node:test');
const assert = require('node:assert/strict');
test('all Firebase v2 endpoints load with the installed SDK', () => {
  const endpoints = require('./index');
  for (const name of ['views','likes','comments','replyNotification','nearbyNotification','cleanupMemory']) {
    assert.equal(typeof endpoints[name], 'function');
  }
});
