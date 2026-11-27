export const MAX_ROOM_PARTICIPANTS = 8;
export const MIN_GIFT_COINS = 10;
export const MIN_COIN_BACK_GIFT = 100;
export const RECIPIENT_COIN_BACK_PERCENT = 25;
export const JACKPOT_MIN_GIFT = 500;
export const JACKPOT_PROBABILITY_BPS = 500;
export const JACKPOT_MULTIPLIER = 2;

export type GiftPolicyResult = {
  senderDeduction: number;
  recipientCoinBack: number;
  jackpotAmount: number;
};

export function validateRoomInput(input: {
  name: unknown;
  description?: unknown;
  visibility: unknown;
  password?: unknown;
}): { name: string; description: string; isPrivate: boolean; password?: string } {
  if (typeof input.name !== 'string') throw new Error('Enter a room name.');
  const name = input.name.trim();
  if (name.length < 3 || name.length > 60) {
    throw new Error('Room name must be between 3 and 60 characters.');
  }
  const description = typeof input.description === 'string' ? input.description.trim() : '';
  if (description.length > 500) throw new Error('Room description must be 500 characters or fewer.');
  if (input.visibility !== 'public' && input.visibility !== 'private') {
    throw new Error('Choose public or private visibility.');
  }
  const isPrivate = input.visibility === 'private';
  const password = typeof input.password === 'string' ? input.password : '';
  if (isPrivate && (password.length < 6 || password.length > 64)) {
    throw new Error('Private room passwords must be 6 to 64 characters.');
  }
  return { name, description, isPrivate, ...(isPrivate ? { password } : {}) };
}

export function computeGiftRewards(giftValue: number, jackpotRoll: number): GiftPolicyResult {
  if (!Number.isSafeInteger(giftValue) || giftValue < MIN_GIFT_COINS || giftValue > 500_000) {
    throw new Error('Gift value must be between 10 and 500,000 coins.');
  }
  const recipientCoinBack = giftValue >= MIN_COIN_BACK_GIFT
    ? Math.floor(giftValue * RECIPIENT_COIN_BACK_PERCENT / 100)
    : 0;
  const jackpotAmount = giftValue >= JACKPOT_MIN_GIFT && jackpotRoll < JACKPOT_PROBABILITY_BPS
    ? giftValue * JACKPOT_MULTIPLIER
    : 0;
  return { senderDeduction: giftValue, recipientCoinBack, jackpotAmount };
}

export function normalizeRoomId(value: unknown): string {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{8,32}$/.test(value)) throw new Error('Invalid room ID.');
  return value;
}

export function normalizeRequestId(value: unknown): string {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{16,80}$/.test(value)) {
    throw new Error('Invalid transaction request ID.');
  }
  return value;
}
