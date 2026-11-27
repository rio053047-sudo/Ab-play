import { randomBytes, randomInt, scryptSync, timingSafeEqual } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getDatabase } from 'firebase-admin/database';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { RtcRole, RtcTokenBuilder } from 'agora-token';
import { onCall, HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { onValueDeleted } from 'firebase-functions/v2/database';
import { setGlobalOptions } from 'firebase-functions/v2';
import {
  computeGiftRewards,
  MAX_ROOM_PARTICIPANTS,
  normalizeRequestId,
  normalizeRoomId,
  validateRoomInput,
} from './domain.js';

initializeApp();
setGlobalOptions({ region: 'asia-south1', maxInstances: 40 });

const db = getFirestore();
const agoraAppId = defineSecret('AGORA_APP_ID');
const agoraCertificate = defineSecret('AGORA_APP_CERTIFICATE');
const roomPasswordPepper = defineSecret('ROOM_PASSWORD_PEPPER');
const APP_CHECK = true;
const RTC_TOKEN_LIFETIME_SECONDS = 300;
const RTC_PUBLISH_PRIVILEGE_SECONDS = RTC_TOKEN_LIFETIME_SECONDS;

const giftCatalog: Record<string, { name: string; icon: string; coins: number }> = {
  rose: { name: 'Rose', icon: '🌹', coins: 10 },
  coffee: { name: 'Coffee', icon: '☕', coins: 20 },
  heart: { name: 'Love Heart', icon: '💖', coins: 50 },
  party_popper: { name: 'Popper', icon: '🎉', coins: 100 },
  sports_car: { name: 'Supercar', icon: '🏎️', coins: 500 },
  diamond_ring: { name: 'Diamond Ring', icon: '💍', coins: 1_000 },
  rocket: { name: 'Rocket', icon: '🚀', coins: 2_000 },
  castle: { name: 'Magic Castle', icon: '🏰', coins: 5_000 },
};

function uidFrom(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to use Voice Rooms.');
  if (APP_CHECK && !request.app) throw new HttpsError('failed-precondition', 'App Check verification is required.');
  return uid;
}

function objectData(request: CallableRequest): Record<string, unknown> {
  if (!request.data || typeof request.data !== 'object' || Array.isArray(request.data)) {
    throw new HttpsError('invalid-argument', 'Invalid request data.');
  }
  return request.data as Record<string, unknown>;
}

function userSnapshot(request: CallableRequest): { name: string; photoUrl: string } {
  const claims: Record<string, unknown> = request.auth?.token ?? {};
  const name = typeof claims.name === 'string' ? claims.name.trim().slice(0, 80) : '';
  const photoUrl = typeof claims.picture === 'string' ? claims.picture : '';
  return { name: name || 'Ab-Play Player', photoUrl };
}

function hashRoomPassword(password: string, salt: string): Buffer {
  return scryptSync(`${roomPasswordPepper.value()}:${password}`, salt, 64);
}

function safeString(value: unknown, maxLength: number, label: string): string {
  if (typeof value !== 'string') throw new HttpsError('invalid-argument', `${label} is required.`);
  const normalized = value.trim();
  if (!normalized || normalized.length > maxLength) throw new HttpsError('invalid-argument', `${label} is invalid.`);
  return normalized;
}

function roomRef(roomId: string) {
  return db.collection('voiceRooms').doc(roomId);
}

function rtcCredentials(channel: string, uid: number, publisher: boolean) {
  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + RTC_TOKEN_LIFETIME_SECONDS;
  const appId = agoraAppId.value();
  const certificate = agoraCertificate.value();
  if (!/^[a-fA-F0-9]{32}$/.test(appId) || !certificate) {
    throw new HttpsError('failed-precondition', 'Agora token credentials are not configured on the server.');
  }
  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    certificate,
    channel,
    uid,
    publisher ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER,
    RTC_TOKEN_LIFETIME_SECONDS,
    RTC_PUBLISH_PRIVILEGE_SECONDS,
  );
  return { token, appId, uid, channel, expiresAt, publisher };
}

async function getRtcCredentials(roomId: string, uid: string) {
  const roomDocument = await roomRef(roomId).get();
  const memberDocument = await roomRef(roomId).collection('members').doc(uid).get();
  if (!roomDocument.exists || !memberDocument.exists || memberDocument.get('active') !== true) {
    throw new HttpsError('permission-denied', 'Join this room before requesting an audio token.');
  }
  const member = memberDocument.data()!;
  const publisher = Number.isInteger(member.seatIndex) && member.mutedByHost !== true;
  return rtcCredentials(String(roomDocument.get('channelName')), member.rtcUid as number, publisher);
}

function makeEvent(type: string, actorUid: string, payload: Record<string, unknown> = {}) {
  return {
    type,
    actorUid,
    payload,
    createdAt: FieldValue.serverTimestamp(),
  };
}

function passwordMatches(candidate: string, salt: string, expectedHex: string): boolean {
  const expected = Buffer.from(expectedHex, 'hex');
  const actual = hashRoomPassword(candidate, salt);
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

export const createVoiceRoom = onCall(
  { enforceAppCheck: true, secrets: [roomPasswordPepper, agoraAppId, agoraCertificate] },
  async (request) => {
    const uid = uidFrom(request);
    const data = objectData(request);
    let normalized: ReturnType<typeof validateRoomInput>;
    try {
      normalized = validateRoomInput(data as Parameters<typeof validateRoomInput>[0]);
    } catch (error) {
      throw new HttpsError('invalid-argument', error instanceof Error ? error.message : 'Invalid room details.');
    }
    const roomId = `room_${randomBytes(9).toString('base64url')}`;
    const profile = userSnapshot(request);
    const channelName = `ab_${roomId}`;
    const hostRtcUid = randomInt(1, 0x7fffffff);
    const rtc = rtcCredentials(channelName, hostRtcUid, true);
    const reference = roomRef(roomId);
    const member = reference.collection('members').doc(uid);
    const wallet = db.collection('wallets').doc(uid);
    const coverPath = typeof data.coverPath === 'string' ? data.coverPath : '';
    if (coverPath && !coverPath.startsWith(`voiceRoomCovers/${uid}/${roomId}/`)) {
      throw new HttpsError('invalid-argument', 'Room cover must be uploaded to your room cover path.');
    }

    const salt = randomBytes(16).toString('hex');
    await db.runTransaction(async (transaction) => {
      const walletSnapshot = await transaction.get(wallet);
      if (!walletSnapshot.exists) transaction.create(wallet, { uid, balance: 0, updatedAt: FieldValue.serverTimestamp() });
    });
    const batch = db.batch();
    batch.create(reference, {
      id: roomId,
      channelName,
      name: normalized.name,
      description: normalized.description,
      coverPath,
      hostUid: uid,
      hostName: profile.name,
      hostPhotoUrl: profile.photoUrl,
      visibility: normalized.isPrivate ? 'private' : 'public',
      locked: false,
      status: 'open',
      maxParticipants: MAX_ROOM_PARTICIPANTS,
      participantCount: 1,
      level: 1,
      experience: 0,
      nextLevelExperience: 1_000,
      announcement: 'Welcome to our room! Please be respectful and enjoy the party.',
      tag: typeof data.tag === 'string' ? data.tag.slice(0, 24) : 'party',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    batch.create(member, {
      uid,
      name: profile.name,
      photoUrl: profile.photoUrl,
      role: 'host',
      seatIndex: 0,
      mutedByHost: false,
      micMuted: true,
      active: true,
      connected: true,
      contributionCoins: 0,
      joinedAt: FieldValue.serverTimestamp(),
      lastSeenAt: FieldValue.serverTimestamp(),
      rtcUid: hostRtcUid,
    });
    for (let seatIndex = 0; seatIndex < 8; seatIndex++) {
      batch.create(reference.collection('seats').doc(String(seatIndex)), {
        seatIndex,
        uid: seatIndex === 0 ? uid : null,
        rtcUid: seatIndex === 0 ? hostRtcUid : null,
        name: seatIndex === 0 ? profile.name : null,
        photoUrl: seatIndex === 0 ? profile.photoUrl : null,
        role: seatIndex === 0 ? 'host' : 'listener',
        locked: false,
        mutedByHost: false,
        micMuted: true,
      });
    }
    batch.create(reference.collection('events').doc(), makeEvent('roomCreated', uid, { name: normalized.name }));
    if (normalized.isPrivate) {
      batch.create(db.collection('voiceRoomSecrets').doc(roomId), {
        salt,
        passwordHash: hashRoomPassword(normalized.password!, salt).toString('hex'),
      });
    }
    await batch.commit();
    return { roomId, rtc };
  },
);

export const joinVoiceRoom = onCall(
  { enforceAppCheck: true, secrets: [roomPasswordPepper, agoraAppId, agoraCertificate] },
  async (request) => {
    const uid = uidFrom(request);
    const data = objectData(request);
    let id: string;
    try { id = normalizeRoomId(data.roomId); } catch (error) {
      throw new HttpsError('invalid-argument', error instanceof Error ? error.message : 'Invalid room ID.');
    }
    const reference = roomRef(id);
    const memberRef = reference.collection('members').doc(uid);
    const secretRef = db.collection('voiceRoomSecrets').doc(id);
    const profile = userSnapshot(request);
    const memberCount = await db.runTransaction(async (transaction) => {
      const [roomSnapshot, memberSnapshot, secretSnapshot, membersSnapshot, walletSnapshot] = await Promise.all([
        transaction.get(reference),
        transaction.get(memberRef),
        transaction.get(secretRef),
        transaction.get(reference.collection('members')),
        transaction.get(walletRef(uid)),
      ]);
      if (!roomSnapshot.exists || roomSnapshot.get('status') !== 'open') {
        throw new HttpsError('not-found', 'This room is no longer available.');
      }
      const room = roomSnapshot.data()!;
      const isExistingActiveMember = memberSnapshot.exists && memberSnapshot.get('active') === true;
      if (room.visibility === 'private') {
        if (typeof data.password !== 'string' || !secretSnapshot.exists) {
          throw new HttpsError('permission-denied', 'A valid private room password is required.');
        }
        const secret = secretSnapshot.data()!;
        if (!passwordMatches(data.password, secret.salt, secret.passwordHash)) {
          throw new HttpsError('permission-denied', 'The private room password is incorrect.');
        }
      }
      const ban = await transaction.get(reference.collection('bans').doc(uid));
      if (ban.exists) throw new HttpsError('permission-denied', 'You cannot join this room.');
      const blockChecks = membersSnapshot.docs
        .filter((document) => document.id !== uid && document.get('active') === true)
        .flatMap((document) => [
          transaction.get(db.collection('userBlocks').doc(document.id).collection('blocked').doc(uid)),
          transaction.get(db.collection('userBlocks').doc(uid).collection('blocked').doc(document.id)),
        ]);
      const blockResults = await Promise.all(blockChecks);
      if (blockResults.some((result) => result.exists)) {
        throw new HttpsError('permission-denied', 'You cannot join this room.');
      }
      if (room.locked === true && !isExistingActiveMember) {
        throw new HttpsError('failed-precondition', 'This room is locked to new participants.');
      }
      const activeCount = membersSnapshot.docs.filter((document) => document.get('active') === true).length;
      if (!isExistingActiveMember && activeCount >= Number(room.maxParticipants ?? MAX_ROOM_PARTICIPANTS)) {
        throw new HttpsError('resource-exhausted', 'This room is full.');
      }
      const occupiedRtcUids = new Set(membersSnapshot.docs
        .filter((document) => document.id !== uid && document.get('active') === true)
        .map((document) => Number(document.get('rtcUid'))));
      let rtcUid = memberSnapshot.exists ? Number(memberSnapshot.get('rtcUid')) : 0;
      if (!rtcUid || occupiedRtcUids.has(rtcUid)) {
        do { rtcUid = randomInt(1, 0x7fffffff); } while (occupiedRtcUids.has(rtcUid));
      }
      const memberData = memberSnapshot.data() ?? {};
      const retainedSeatIndex = Number(memberData.seatIndex);
      const retainedSeat = isExistingActiveMember && Number.isInteger(retainedSeatIndex) && retainedSeatIndex >= 0 && retainedSeatIndex < 8
        ? await transaction.get(reference.collection('seats').doc(String(retainedSeatIndex))) : null;
      transaction.set(memberRef, {
        uid,
        name: profile.name,
        photoUrl: profile.photoUrl,
        role: isExistingActiveMember ? memberData.role : memberData.role === 'host' ? 'host' : 'listener',
        seatIndex: isExistingActiveMember ? memberData.seatIndex ?? null : memberData.role === 'host' ? 0 : null,
        mutedByHost: isExistingActiveMember && memberData.mutedByHost === true,
        micMuted: true,
        active: true,
        removedByModeration: false,
        connected: true,
        rtcUid,
        joinedAt: isExistingActiveMember ? memberData.joinedAt : FieldValue.serverTimestamp(),
        lastSeenAt: FieldValue.serverTimestamp(),
        contributionCoins: Number(memberData.contributionCoins ?? 0),
      }, { merge: true });
      if (retainedSeat?.exists) transaction.update(retainedSeat.ref, { micMuted: true });
      if (!isExistingActiveMember) {
        transaction.update(reference, {
          participantCount: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });
        transaction.create(reference.collection('events').doc(), makeEvent('memberJoined', uid, { name: profile.name }));
        if (!walletSnapshot.exists) transaction.create(walletRef(uid), { uid, balance: 0, updatedAt: FieldValue.serverTimestamp() });
      }
      return activeCount + (isExistingActiveMember ? 0 : 1);
    });
    await getDatabase().ref(`voiceRoomPresence/${id}/${uid}`).set({ connected: true, updatedAt: Date.now() });
    const rtc = await getRtcCredentials(id, uid);
    return { participantCount: memberCount, rtc };
  },
);

function walletRef(uid: string) { return db.collection('wallets').doc(uid); }

export const leaveVoiceRoom = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const id = normalizeRoomId(objectData(request).roomId);
  const member = await roomRef(id).collection('members').doc(uid).get();
  if (!member.exists || member.get('active') !== true) return { success: true };
  await getDatabase().ref(`voiceRoomPresence/${id}/${uid}`).remove();
  return { success: true };
});

export const getVoiceRtcToken = onCall(
  { enforceAppCheck: true, secrets: [agoraAppId, agoraCertificate] },
  async (request) => {
    const uid = uidFrom(request);
    const data = objectData(request);
    let id: string;
    try { id = normalizeRoomId(data.roomId); } catch (error) {
      throw new HttpsError('invalid-argument', error instanceof Error ? error.message : 'Invalid room ID.');
    }
    return { rtc: await getRtcCredentials(id, uid) };
  },
);

export const setVoiceSpeakerSeat = onCall({ enforceAppCheck: true, secrets: [agoraAppId, agoraCertificate] }, async (request) => {
  const uid = uidFrom(request);
  const data = objectData(request);
  const id = normalizeRoomId(data.roomId);
  const seatIndex = Number(data.seatIndex);
  const targetUid = safeString(data.targetUid ?? uid, 128, 'Target user ID');
  if (!Number.isInteger(seatIndex) || seatIndex < 0 || seatIndex > 7) {
    throw new HttpsError('invalid-argument', 'Choose one of the eight speaker seats.');
  }
  const reference = roomRef(id);
  const callerRef = reference.collection('members').doc(uid);
  const targetRef = reference.collection('members').doc(targetUid);
  const seatRefs = Array.from({ length: 8 }, (_, index) => reference.collection('seats').doc(String(index)));
  await db.runTransaction(async (transaction) => {
    const [roomSnapshot, callerSnapshot, targetSnapshot, ...seatSnapshots] = await Promise.all([
      transaction.get(reference), transaction.get(callerRef), transaction.get(targetRef),
      ...seatRefs.map((seat) => transaction.get(seat)),
    ]);
    if (!roomSnapshot.exists || !callerSnapshot.exists || callerSnapshot.get('active') !== true ||
        !targetSnapshot.exists || targetSnapshot.get('active') !== true) {
      throw new HttpsError('failed-precondition', 'Both users must be active room members.');
    }
    const callerRole = callerSnapshot.get('role');
    const selfClaim = uid === targetUid;
    if (!selfClaim && !['host', 'moderator'].includes(String(callerRole))) {
      throw new HttpsError('permission-denied', 'Only the host or a moderator can assign speaker seats.');
    }
    if (selfClaim && roomSnapshot.get('hostUid') === uid && seatIndex !== 0) {
      throw new HttpsError('permission-denied', 'The host must remain in the reserved host seat.');
    }
    if (seatIndex === 0 && roomSnapshot.get('hostUid') !== targetUid) {
      throw new HttpsError('permission-denied', 'Seat 1 is reserved for the host.');
    }
    const existingSeatIndex = Number.isInteger(targetSnapshot.get('seatIndex'))
      ? Number(targetSnapshot.get('seatIndex')) : -1;
    const targetSeat = seatSnapshots[seatIndex];
    if (targetSeat.get('locked') === true && !['host', 'moderator'].includes(String(callerRole))) {
      throw new HttpsError('permission-denied', 'That speaker seat is locked.');
    }
    const occupant = targetSeat.get('uid');
    if (occupant && occupant !== targetUid) throw new HttpsError('already-exists', 'That seat is occupied.');
    if (existingSeatIndex >= 0 && existingSeatIndex !== seatIndex) {
      const previousSeat = seatSnapshots[existingSeatIndex];
      transaction.update(seatRefs[existingSeatIndex], {
        uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true, mutedByHost: false,
      });
    }
    transaction.update(seatRefs[seatIndex], {
      uid: targetUid,
      rtcUid: targetSnapshot.get('rtcUid') ?? null,
      name: targetSnapshot.get('name') ?? 'Ab-Play Player',
      photoUrl: targetSnapshot.get('photoUrl') ?? '',
      role: roomSnapshot.get('hostUid') === targetUid ? 'host' : 'speaker',
      micMuted: true,
      mutedByHost: false,
    });
    transaction.update(targetRef, {
      seatIndex,
      role: roomSnapshot.get('hostUid') === targetUid ? 'host' : 'speaker',
      micMuted: true,
      mutedByHost: false,
    });
    transaction.create(reference.collection('events').doc(), makeEvent('speakerSeatAssigned', uid, { targetUid, seatIndex }));
  });
  return { rtc: await getRtcCredentials(id, targetUid) };
});

export const leaveVoiceSpeakerSeat = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const id = normalizeRoomId(objectData(request).roomId);
  const reference = roomRef(id);
  const memberRef = reference.collection('members').doc(uid);
  await db.runTransaction(async (transaction) => {
    const member = await transaction.get(memberRef);
    if (!member.exists || member.get('active') !== true) throw new HttpsError('failed-precondition', 'You are not in this room.');
    const seatIndex = Number(member.get('seatIndex'));
    if (!Number.isInteger(seatIndex) || seatIndex < 0) return;
    if (member.get('role') === 'host') throw new HttpsError('failed-precondition', 'The host must transfer the host role before stepping down.');
    transaction.update(reference.collection('seats').doc(String(seatIndex)), {
      uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true, mutedByHost: false,
    });
    transaction.update(memberRef, { seatIndex: null, role: 'listener', micMuted: true, mutedByHost: false });
    transaction.create(reference.collection('events').doc(), makeEvent('speakerSeatRemoved', uid, { seatIndex }));
  });
  return { rtc: await getRtcCredentials(id, uid) };
});

export const setVoiceMicrophoneState = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const data = objectData(request);
  const id = normalizeRoomId(data.roomId);
  const muted = data.muted === true;
  const reference = roomRef(id);
  const memberRef = reference.collection('members').doc(uid);
  await db.runTransaction(async (transaction) => {
    const member = await transaction.get(memberRef);
    if (!member.exists || member.get('active') !== true) throw new HttpsError('permission-denied', 'Join this room first.');
    if (!muted && (!Number.isInteger(member.get('seatIndex')) || member.get('mutedByHost') === true)) {
      throw new HttpsError('permission-denied', 'Only an unmuted speaker may open the microphone.');
    }
    transaction.update(memberRef, { micMuted: muted, lastSeenAt: FieldValue.serverTimestamp() });
    const seatIndex = Number(member.get('seatIndex'));
    if (Number.isInteger(seatIndex) && seatIndex >= 0) {
      transaction.update(reference.collection('seats').doc(String(seatIndex)), { micMuted: muted });
    }
    transaction.create(reference.collection('events').doc(), makeEvent('microphoneChanged', uid, { muted }));
  });
  return { muted };
});

export const moderateVoiceRoomMember = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const data = objectData(request);
  const id = normalizeRoomId(data.roomId);
  const targetUid = safeString(data.targetUid, 128, 'Target user ID');
  const action = safeString(data.action, 24, 'Moderation action');
  const reference = roomRef(id);
  const callerRef = reference.collection('members').doc(uid);
  const targetRef = reference.collection('members').doc(targetUid);
  await db.runTransaction(async (transaction) => {
    const [room, caller, target] = await Promise.all([
      transaction.get(reference), transaction.get(callerRef), transaction.get(targetRef),
    ]);
    if (!room.exists || !caller.exists || !target.exists || caller.get('active') !== true || target.get('active') !== true) {
      throw new HttpsError('failed-precondition', 'Both users must be active room members.');
    }
    const callerRole = caller.get('role');
    const targetRole = target.get('role');
    if (!['host', 'moderator'].includes(String(callerRole)) || targetRole === 'host' || uid === targetUid) {
      throw new HttpsError('permission-denied', 'You cannot moderate this participant.');
    }
    const seatIndex = Number(target.get('seatIndex'));
    const seatRef = Number.isInteger(seatIndex) && seatIndex >= 0
      ? reference.collection('seats').doc(String(seatIndex)) : null;
    const seat = seatRef ? await transaction.get(seatRef) : null;
    if (action === 'mute' || action === 'unmute') {
      const muted = action === 'mute';
      transaction.update(targetRef, { mutedByHost: muted, micMuted: true });
      if (seatRef) transaction.update(seatRef, { mutedByHost: muted, micMuted: true });
    } else if (action === 'removeSpeaker') {
      if (seatRef) transaction.update(seatRef, { uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true, mutedByHost: false });
      transaction.update(targetRef, { seatIndex: null, role: 'listener', micMuted: true, mutedByHost: false });
    } else if (action === 'kick' || action === 'ban') {
      if (seatRef) transaction.update(seatRef, { uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true, mutedByHost: false });
      transaction.update(targetRef, { active: false, connected: false, removedByModeration: true, seatIndex: null, micMuted: true, role: 'listener' });
      transaction.update(reference, { participantCount: FieldValue.increment(-1) });
      if (action === 'ban') transaction.set(reference.collection('bans').doc(targetUid), { bannedBy: uid, createdAt: FieldValue.serverTimestamp() });
    } else {
      throw new HttpsError('invalid-argument', 'Unsupported moderation action.');
    }
    transaction.create(reference.collection('events').doc(), makeEvent(`member${action}`, uid, { targetUid }));
  });
  if (action === 'kick' || action === 'ban') {
    await getDatabase().ref(`voiceRoomPresence/${id}/${targetUid}`).remove();
  }
  return { success: true };
});

export const updateVoiceRoom = onCall({ enforceAppCheck: true, secrets: [roomPasswordPepper] }, async (request) => {
  const uid = uidFrom(request);
  const data = objectData(request);
  const id = normalizeRoomId(data.roomId);
  const reference = roomRef(id);
  const secretRef = db.collection('voiceRoomSecrets').doc(id);
  const action = safeString(data.action, 24, 'Room action');
  let membersToDisconnect: string[] = [];
  await db.runTransaction(async (transaction) => {
    const [room, member, secret] = await Promise.all([
      transaction.get(reference), transaction.get(reference.collection('members').doc(uid)), transaction.get(secretRef),
    ]);
    if (!room.exists || !member.exists || member.get('active') !== true) throw new HttpsError('permission-denied', 'Join the room first.');
    const role = member.get('role');
    const isHost = room.get('hostUid') === uid;
    const isModerator = role === 'moderator';
    const isAdmin = role === 'admin';
    const updates: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
    if (action === 'announcement') {
      if (!isHost && !isModerator && !isAdmin) throw new HttpsError('permission-denied', 'Only the host or moderators can post announcements.');
      updates.announcement = safeString(data.announcement, 240, 'Announcement');
    } else if (action === 'lock') {
      if (!isHost && !isAdmin) throw new HttpsError('permission-denied', 'Only the host or an admin can lock the room.');
      updates.locked = data.locked === true;
    } else if (action === 'seatLock') {
      if (!isHost && !isModerator && !isAdmin) throw new HttpsError('permission-denied', 'Only room moderators may lock seats.');
      const seatIndex = Number(data.seatIndex);
      if (!Number.isInteger(seatIndex) || seatIndex < 1 || seatIndex > 7) throw new HttpsError('invalid-argument', 'Invalid speaker seat.');
      const seatRef = reference.collection('seats').doc(String(seatIndex));
      const seat = await transaction.get(seatRef);
      if (!seat.exists) throw new HttpsError('not-found', 'Speaker seat does not exist.');
      if (data.locked === true && seat.get('uid')) throw new HttpsError('failed-precondition', 'Remove the participant before locking this seat.');
      transaction.update(seatRef, { locked: data.locked === true });
    } else if (action === 'details') {
      if (!isHost) throw new HttpsError('permission-denied', 'Only the host can edit room details.');
      if (data.name !== undefined) updates.name = safeString(data.name, 60, 'Room name');
      if (data.description !== undefined) updates.description = String(data.description).trim().slice(0, 500);
      if (data.coverPath !== undefined) {
        const path = String(data.coverPath);
        if (path && !path.startsWith(`voiceRoomCovers/${uid}/${id}/`)) throw new HttpsError('invalid-argument', 'Invalid room cover path.');
        updates.coverPath = path;
      }
      if (data.visibility === 'public' || data.visibility === 'private') updates.visibility = data.visibility;
      if (updates.visibility === 'private' && !secret.exists && typeof data.password !== 'string') {
        throw new HttpsError('invalid-argument', 'A password is required for a private room.');
      }
      if (data.password !== undefined) {
        if (typeof data.password !== 'string' || data.password.length < 6 || data.password.length > 64) {
          throw new HttpsError('invalid-argument', 'Room passwords must be 6 to 64 characters.');
        }
        const salt = randomBytes(16).toString('hex');
        transaction.set(secretRef, { salt, passwordHash: hashRoomPassword(data.password, salt) .toString('hex') });
      }
      if (updates.visibility === 'public') transaction.delete(secretRef);
    } else if (action === 'setModerator') {
      if (!isHost) throw new HttpsError('permission-denied', 'Only the host can change moderator roles.');
      const targetUid = safeString(data.targetUid, 128, 'Moderator');
      const targetRef = reference.collection('members').doc(targetUid);
      const target = await transaction.get(targetRef);
      if (!target.exists || target.get('active') !== true || targetUid === uid) throw new HttpsError('failed-precondition', 'Choose an active participant.');
      const currentRole = String(target.get('role') ?? 'listener');
      transaction.update(targetRef, { role: data.moderator === true ? 'moderator' : (Number.isInteger(target.get('seatIndex')) ? 'speaker' : 'listener') });
      transaction.create(reference.collection('events').doc(), makeEvent('moderatorChanged', uid, { targetUid, moderator: data.moderator === true, previousRole: currentRole }));
      return;
    } else if (action === 'transferHost') {
      if (!isHost) throw new HttpsError('permission-denied', 'Only the current host can transfer ownership.');
      const targetUid = safeString(data.targetUid, 128, 'New host');
      const targetRef = reference.collection('members').doc(targetUid);
      const target = await transaction.get(targetRef);
      if (!target.exists || target.get('active') !== true) throw new HttpsError('failed-precondition', 'The new host must be an active room member.');
      const seats = await Promise.all(Array.from({ length: 8 }, (_, index) => transaction.get(reference.collection('seats').doc(String(index)))));
      const oldSeatIndex = Number(member.get('seatIndex'));
      const targetSeatIndex = Number(target.get('seatIndex'));
      if (Number.isInteger(oldSeatIndex) && oldSeatIndex >= 0) transaction.update(reference.collection('seats').doc(String(oldSeatIndex)), { uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true });
      if (Number.isInteger(targetSeatIndex) && targetSeatIndex >= 0) transaction.update(reference.collection('seats').doc(String(targetSeatIndex)), { uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true });
      const seatZero = seats[0];
      const seatZeroUid = seatZero.get('uid');
      if (seatZeroUid && seatZeroUid !== uid && seatZeroUid !== targetUid) throw new HttpsError('failed-precondition', 'Host seat is occupied.');
      transaction.update(reference.collection('seats').doc('0'), { uid: targetUid, rtcUid: target.get('rtcUid') ?? null, name: target.get('name'), photoUrl: target.get('photoUrl'), role: 'host', micMuted: true, mutedByHost: false });
      transaction.update(reference, { hostUid: targetUid, hostName: target.get('name'), hostPhotoUrl: target.get('photoUrl'), updatedAt: FieldValue.serverTimestamp() });
      transaction.update(reference.collection('members').doc(uid), { role: 'speaker', seatIndex: null, micMuted: true });
      transaction.update(targetRef, { role: 'host', seatIndex: 0, micMuted: true, mutedByHost: false });
      transaction.create(reference.collection('events').doc(), makeEvent('hostTransferred', uid, { targetUid }));
      return;
    } else if (action === 'close') {
      if (!isHost) throw new HttpsError('permission-denied', 'Only the host can close this room.');
      const [activeMembers, seats] = await Promise.all([
        transaction.get(reference.collection('members').where('active', '==', true)),
        Promise.all(Array.from({ length: 8 }, (_, index) => transaction.get(reference.collection('seats').doc(String(index))))),
      ]);
      membersToDisconnect = activeMembers.docs.map((document) => document.id);
      for (const document of activeMembers.docs) transaction.update(document.ref, { active: false, connected: false, seatIndex: null, micMuted: true, role: 'listener' });
      for (const seat of seats) transaction.update(seat.ref, { uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true, mutedByHost: false });
      updates.status = 'closed';
      updates.participantCount = 0;
      transaction.create(reference.collection('events').doc(), makeEvent('roomClosed', uid));
    } else {
      throw new HttpsError('invalid-argument', 'Unsupported room action.');
    }
    transaction.update(reference, updates);
    transaction.create(reference.collection('events').doc(), makeEvent(`room${action}`, uid, { announcement: updates.announcement ?? null }));
  });
  if (membersToDisconnect.length > 0) {
    await Promise.all(membersToDisconnect.map((memberUid) => getDatabase().ref(`voiceRoomPresence/${id}/${memberUid}`).remove()));
  }
  return { success: true };
});

export const sendVoiceRoomGift = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const data = objectData(request);
  const roomId = normalizeRoomId(data.roomId);
  const targetUid = safeString(data.targetUid, 128, 'Gift recipient');
  const giftId = safeString(data.giftId, 32, 'Gift');
  const gift = giftCatalog[giftId];
  if (!gift) throw new HttpsError('invalid-argument', 'This gift is not available.');
  const requestId = normalizeRequestId(data.requestId);
  const transactionId = `${uid}_${requestId}`;
  const txnRef = db.collection('giftTransactions').doc(transactionId);
  const reference = roomRef(roomId);
  const senderWallet = walletRef(uid);
  const recipientWallet = walletRef(targetUid);
  const result = await db.runTransaction(async (transaction) => {
    const [prior, room, senderMember, recipientMember, senderBalance, contribution, giftWall] = await Promise.all([
      transaction.get(txnRef), transaction.get(reference),
      transaction.get(reference.collection('members').doc(uid)),
      transaction.get(reference.collection('members').doc(targetUid)),
      transaction.get(senderWallet),
      transaction.get(reference.collection('contributions').doc(uid)),
      transaction.get(db.collection('users').doc(targetUid).collection('giftWall').doc(giftId)),
    ]);
    const recipientBalanceSnapshot = uid === targetUid ? senderBalance : await transaction.get(recipientWallet);
    if (prior.exists) return { ...prior.data(), duplicate: true };
    if (!room.exists || room.get('status') !== 'open' ||
        !senderMember.exists || senderMember.get('active') !== true ||
        !recipientMember.exists || recipientMember.get('active') !== true) {
      throw new HttpsError('failed-precondition', 'Sender and recipient must be active in this room.');
    }
    if (!senderBalance.exists || Number(senderBalance.get('balance') ?? 0) < gift.coins) {
      throw new HttpsError('failed-precondition', 'Insufficient coin balance.');
    }
    const rewards = computeGiftRewards(gift.coins, randomInt(0, 10_000));
    const senderCurrent = Number(senderBalance.get('balance') ?? 0);
    const recipientCurrent = Number(recipientBalanceSnapshot.get('balance') ?? 0);
    const senderNext = uid === targetUid
      ? senderCurrent - rewards.senderDeduction + rewards.recipientCoinBack + rewards.jackpotAmount
      : senderCurrent - rewards.senderDeduction;
    transaction.set(senderWallet, { uid, balance: senderNext, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    if (uid !== targetUid) {
      transaction.set(recipientWallet, {
        uid: targetUid,
        balance: recipientCurrent + rewards.recipientCoinBack + rewards.jackpotAmount,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    transaction.set(reference.collection('members').doc(uid), {
      contributionCoins: FieldValue.increment(gift.coins),
    }, { merge: true });
    transaction.set(reference.collection('contributions').doc(uid), {
      uid,
      name: senderMember.get('name'),
      photoUrl: senderMember.get('photoUrl') ?? '',
      coins: FieldValue.increment(gift.coins),
      giftCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    transaction.set(db.collection('users').doc(targetUid).collection('giftWall').doc(giftId), {
      giftId,
      name: gift.name,
      icon: gift.icon,
      count: FieldValue.increment(1),
      receivedCoins: FieldValue.increment(gift.coins),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    let experience = Number(room.get('experience') ?? 0) + gift.coins;
    let level = Number(room.get('level') ?? 1);
    let nextLevelExperience = Number(room.get('nextLevelExperience') ?? 1_000);
    while (experience >= nextLevelExperience) {
      experience -= nextLevelExperience;
      level++;
      nextLevelExperience = Math.floor(nextLevelExperience * 1.5);
    }
    transaction.update(reference, { experience, level, nextLevelExperience, updatedAt: FieldValue.serverTimestamp() });
    const dailyId = new Date().toISOString().slice(0, 10);
    transaction.set(reference.collection('dailyTasks').doc(dailyId).collection('members').doc(uid), {
      giftsSent: FieldValue.increment(1),
      giftCoinsSent: FieldValue.increment(gift.coins),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    const giftResult = {
      transactionId,
      roomId,
      senderUid: uid,
      recipientUid: targetUid,
      giftId,
      giftName: gift.name,
      giftIcon: gift.icon,
      giftCoins: gift.coins,
      recipientCoinBack: rewards.recipientCoinBack,
      jackpotAmount: rewards.jackpotAmount,
      senderBalance: senderNext,
      recipientBalance: uid === targetUid ? senderNext : recipientCurrent + rewards.recipientCoinBack + rewards.jackpotAmount,
      createdAt: Timestamp.now(),
    };
    transaction.create(txnRef, giftResult);
    transaction.create(reference.collection('events').doc(transactionId), makeEvent('giftSent', uid, {
      transactionId, senderName: senderMember.get('name'), recipientUid: targetUid,
      recipientName: recipientMember.get('name'), giftId, giftName: gift.name,
      giftIcon: gift.icon, giftCoins: gift.coins,
      recipientCoinBack: rewards.recipientCoinBack,
      jackpotAmount: rewards.jackpotAmount,
    }));
    return giftResult;
  });
  return result;
});

export const sendVoiceRoomChat = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const data = objectData(request);
  const roomId = normalizeRoomId(data.roomId);
  const text = safeString(data.text, 500, 'Message');
  const reference = roomRef(roomId);
  await db.runTransaction(async (transaction) => {
    const [room, member] = await Promise.all([
      transaction.get(reference),
      transaction.get(reference.collection('members').doc(uid)),
    ]);
    if (!room.exists || room.get('status') !== 'open' || !member.exists || member.get('active') !== true) {
      throw new HttpsError('permission-denied', 'Join the room before sending a message.');
    }
    transaction.create(reference.collection('events').doc(), makeEvent('chatMessage', uid, {
      senderName: member.get('name') ?? 'Ab-Play Player',
      text,
    }));
  });
  return { success: true };
});

export const getVoiceWallet = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const reference = walletRef(uid);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(reference);
    if (!existing.exists) transaction.create(reference, { uid, balance: 0, updatedAt: FieldValue.serverTimestamp() });
  });
  const wallet = await reference.get();
  return { uid, balance: Number(wallet.get('balance') ?? 0) };
});

export const updateVoicePresence = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const id = normalizeRoomId(objectData(request).roomId);
  const memberRef = roomRef(id).collection('members').doc(uid);
  const member = await memberRef.get();
  if (!member.exists || member.get('active') !== true) throw new HttpsError('permission-denied', 'Join this room first.');
  await getDatabase().ref(`voiceRoomPresence/${id}/${uid}`).set({ connected: true, updatedAt: Date.now() });
  await memberRef.update({ connected: true, lastSeenAt: FieldValue.serverTimestamp() });
  return { connected: true };
});

async function handleParticipantDisconnect(roomId: string, uid: string) {
  const reference = roomRef(roomId);
  const memberRef = reference.collection('members').doc(uid);
  await db.runTransaction(async (transaction) => {
    const presenceSnapshot = await getDatabase().ref(`voiceRoomPresence/${roomId}`).get();
    if (presenceSnapshot.child(uid).exists()) return;
    const [room, member, others] = await Promise.all([
      transaction.get(reference), transaction.get(memberRef),
      transaction.get(reference.collection('members').where('active', '==', true)),
    ]);
    if (!room.exists || !member.exists || member.get('active') !== true) return;
    const seatIndex = Number(member.get('seatIndex'));
    if (Number.isInteger(seatIndex) && seatIndex >= 0) {
      transaction.update(reference.collection('seats').doc(String(seatIndex)), {
        uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true, mutedByHost: false,
      });
    }
    transaction.update(memberRef, { active: false, connected: false, seatIndex: null, micMuted: true, role: 'listener' });
    transaction.update(reference, {
      participantCount: FieldValue.increment(-1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(reference.collection('events').doc(), makeEvent('memberDisconnected', uid));
    if (room.get('hostUid') !== uid) return;
    const nextHost = others.docs
      .filter((candidate) => candidate.id !== uid && candidate.get('active') === true && presenceSnapshot.child(candidate.id).exists())
      .sort((left, right) => Number(left.get('joinedAt')?.toMillis?.() ?? 0) - Number(right.get('joinedAt')?.toMillis?.() ?? 0))[0];
    if (!nextHost) {
      transaction.update(reference, { status: 'closed', participantCount: 0, hostDisconnectedAt: FieldValue.serverTimestamp() });
      transaction.create(reference.collection('events').doc(), makeEvent('roomClosed', uid, { reason: 'hostDisconnected' }));
      return;
    }
    const nextUid = nextHost.id;
    const nextSeatIndex = Number(nextHost.get('seatIndex'));
    if (Number.isInteger(nextSeatIndex) && nextSeatIndex >= 0 && nextSeatIndex !== 0) {
      transaction.update(reference.collection('seats').doc(String(nextSeatIndex)), {
        uid: null, name: null, photoUrl: null, role: 'listener', micMuted: true,
      });
    }
    transaction.update(reference.collection('seats').doc('0'), {
      uid: nextUid,
      rtcUid: nextHost.get('rtcUid') ?? null,
      name: nextHost.get('name') ?? 'Ab-Play Player',
      photoUrl: nextHost.get('photoUrl') ?? '',
      role: 'host',
      micMuted: true,
      mutedByHost: false,
    });
    transaction.update(reference.collection('members').doc(nextUid), { role: 'host', seatIndex: 0, micMuted: true, mutedByHost: false });
    transaction.update(reference, {
      hostUid: nextUid,
      hostName: nextHost.get('name') ?? 'Ab-Play Player',
      hostPhotoUrl: nextHost.get('photoUrl') ?? '',
      hostDisconnectedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(reference.collection('events').doc(), makeEvent('hostTransferred', uid, { targetUid: nextUid, reason: 'hostDisconnected' }));
  });
}

export const voicePresenceDisconnected = onValueDeleted(
  { ref: '/voiceRoomPresence/{roomId}/{uid}', retry: true },
  async (event) => {
    await handleParticipantDisconnect(event.params.roomId, event.params.uid);
  },
);

export const reportVoiceRoomUser = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const data = objectData(request);
  const roomId = normalizeRoomId(data.roomId);
  const targetUid = safeString(data.targetUid, 128, 'Reported user');
  const reason = safeString(data.reason, 500, 'Report reason');
  const member = await roomRef(roomId).collection('members').doc(uid).get();
  if (!member.exists || member.get('active') !== true) throw new HttpsError('permission-denied', 'Join the room before submitting a report.');
  const report = db.collection('voiceRoomReports').doc();
  await report.create({ roomId, reporterUid: uid, targetUid, reason, status: 'open', createdAt: FieldValue.serverTimestamp() });
  return { reportId: report.id };
});

export const blockVoiceRoomUser = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const targetUid = safeString(objectData(request).targetUid, 128, 'Blocked user');
  if (uid === targetUid) throw new HttpsError('invalid-argument', 'You cannot block yourself.');
  await db.collection('userBlocks').doc(uid).collection('blocked').doc(targetUid).set({ createdAt: FieldValue.serverTimestamp() });
  return { success: true };
});

export const unblockVoiceRoomUser = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = uidFrom(request);
  const targetUid = safeString(objectData(request).targetUid, 128, 'Blocked user');
  await db.collection('userBlocks').doc(uid).collection('blocked').doc(targetUid).delete();
  return { success: true };
});
