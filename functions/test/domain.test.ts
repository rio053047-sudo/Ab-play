import assert from 'node:assert/strict';
import test from 'node:test';
import {
  computeGiftRewards,
  MAX_ROOM_PARTICIPANTS,
  normalizeRequestId,
  normalizeRoomId,
  validateRoomInput,
} from '../src/domain.js';

test('public and private room input is normalized and bounded', () => {
  assert.deepEqual(validateRoomInput({ name: '  Friends  ', visibility: 'public' }), {
    name: 'Friends', description: '', isPrivate: false,
  });
  assert.equal(validateRoomInput({ name: 'Private', visibility: 'private', password: 'secret1' }).isPrivate, true);
  assert.throws(() => validateRoomInput({ name: 'x', visibility: 'public' }));
  assert.throws(() => validateRoomInput({ name: 'Private', visibility: 'private', password: '1234' }));
  assert.equal(MAX_ROOM_PARTICIPANTS, 8);
});

test('gift thresholds and recipient coin-back policy are server owned', () => {
  assert.deepEqual(computeGiftRewards(10, 9999), {
    senderDeduction: 10, recipientCoinBack: 0, jackpotAmount: 0,
  });
  assert.deepEqual(computeGiftRewards(100, 9999), {
    senderDeduction: 100, recipientCoinBack: 25, jackpotAmount: 0,
  });
  assert.equal(computeGiftRewards(500, 0).jackpotAmount, 1000);
  assert.throws(() => computeGiftRewards(9, 9999));
});

test('room and request IDs reject unsafe values', () => {
  assert.equal(normalizeRoomId('room_abc123'), 'room_abc123');
  assert.throws(() => normalizeRoomId('../secret'));
  assert.equal(normalizeRequestId('request_id_0000001'), 'request_id_0000001');
  assert.throws(() => normalizeRequestId('gift/../balance'));
});
