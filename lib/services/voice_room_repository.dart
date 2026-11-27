import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/voice_room.dart';

class VoiceRtcCredentials {
  const VoiceRtcCredentials(
      {required this.appId,
      required this.token,
      required this.uid,
      required this.channel,
      required this.publisher});
  final String appId;
  final String token;
  final int uid;
  final String channel;
  final bool publisher;

  factory VoiceRtcCredentials.fromMap(Map<Object?, Object?> data) =>
      VoiceRtcCredentials(
        appId: data['appId'] as String,
        token: data['token'] as String,
        uid: (data['uid'] as num).toInt(),
        channel: data['channel'] as String? ?? '',
        publisher: data['publisher'] == true,
      );
}

class VoiceRoomRepository {
  VoiceRoomRepository(
      {FirebaseFirestore? firestore,
      FirebaseFunctions? functions,
      FirebaseDatabase? database})
      : _firestoreOverride = firestore,
        _functionsOverride = functions,
        _databaseOverride = database;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;
  final FirebaseDatabase? _databaseOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ??
      FirebaseFunctions.instanceFor(region: 'asia-south1');
  FirebaseDatabase get _database =>
      _databaseOverride ?? FirebaseDatabase.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ??
      (throw StateError('Please sign in first.'));
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('voiceRooms');
  DocumentReference<Map<String, dynamic>> room(String id) => _rooms.doc(id);

  Future<Map<String, dynamic>> _call(
      String name, Map<String, Object?> data) async {
    try {
      final result =
          await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw StateError(
          error.message ?? 'Voice Room request failed (${error.code}).');
    }
  }

  Stream<List<VoiceRoomModel>> watchPublicRooms() {
    try {
      return _rooms
          .where('visibility', isEqualTo: 'public')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(_roomFromMap).toList(growable: false));
    } catch (error) {
      return Stream.error(error);
    }
  }

  VoiceRoomModel _roomFromMap(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return VoiceRoomModel(
      id: snapshot.id,
      title: data['name'] as String? ?? 'Voice Room',
      description: data['description'] as String? ?? '',
      coverPath: data['coverPath'] as String? ?? '',
      hostId: data['hostUid'] as String? ?? '',
      hostName: data['hostName'] as String? ?? 'Host',
      hostAvatar: data['hostPhotoUrl'] as String? ?? '',
      isPrivate: data['visibility'] == 'private',
      isLocked: data['locked'] == true,
      roomLevel: (data['level'] as num?)?.toInt() ?? 1,
      currentExp: (data['experience'] as num?)?.toInt() ?? 0,
      maxExp: (data['nextLevelExperience'] as num?)?.toInt() ?? 1000,
      maxCapacity: (data['maxParticipants'] as num?)?.toInt() ?? 8,
      onlineCount: (data['participantCount'] as num?)?.toInt() ?? 0,
      announcement: data['announcement'] as String? ?? '',
      seats: List.generate(8, (index) => VoiceRoomSeat(index: index)),
    );
  }

  Future<(VoiceRoomModel, VoiceRtcCredentials)> createRoom(
      {required String name,
      String description = '',
      required bool isPrivate,
      String? password,
      XFile? coverImage}) async {
    final result = await _call('createVoiceRoom', {
      'name': name,
      'description': description,
      'visibility': isPrivate ? 'private' : 'public',
      if (isPrivate) 'password': password
    });
    final id = result['roomId'] as String;
    final roomDoc = await room(id).get();
    var roomModel = _roomFromMap(roomDoc);
    if (coverImage != null) {
      try {
        final extension =
            coverImage.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        final imageRef =
            _storage.ref('voiceRoomCovers/$_uid/$id/cover.$extension');
        await imageRef.putData(
            await coverImage.readAsBytes(),
            SettableMetadata(
                contentType: extension == 'png' ? 'image/png' : 'image/jpeg'));
        await _call('updateVoiceRoom', {
          'roomId': id,
          'action': 'details',
          'coverPath': imageRef.fullPath
        });
        roomModel.coverPath = imageRef.fullPath;
      } catch (_) {
        // The room remains usable if optional cover upload fails.
      }
    }
    final credentialData = Map<Object?, Object?>.from(result['rtc'] as Map);
    credentialData['channel'] = roomDoc.data()?['channelName'] ?? id;
    return (roomModel, VoiceRtcCredentials.fromMap(credentialData));
  }

  Future<(VoiceRoomModel, VoiceRtcCredentials)> joinRoom(String id,
      {String? password}) async {
    final result = await _call('joinVoiceRoom',
        {'roomId': id, if (password != null) 'password': password});
    final roomDoc = await room(id).get();
    if (!roomDoc.exists) throw StateError('This room has closed.');
    final credentialData = Map<Object?, Object?>.from(result['rtc'] as Map);
    credentialData['channel'] = roomDoc.data()?['channelName'] ?? id;
    return (_roomFromMap(roomDoc), VoiceRtcCredentials.fromMap(credentialData));
  }

  Future<VoiceRtcCredentials> refreshRtcToken(String id) async {
    final result = await _call('getVoiceRtcToken', {'roomId': id});
    final roomDoc = await room(id).get();
    final credentialData = Map<Object?, Object?>.from(result['rtc'] as Map);
    credentialData['channel'] = roomDoc.data()?['channelName'] ?? id;
    return VoiceRtcCredentials.fromMap(credentialData);
  }

  Stream<List<VoiceRoomSeat>> watchSeats(String id) =>
      room(id).collection('seats').snapshots().map((snapshot) {
        final seats = List.generate(8, (index) => VoiceRoomSeat(index: index));
        for (final document in snapshot.docs) {
          final data = document.data();
          final index = (data['seatIndex'] as num?)?.toInt();
          if (index == null || index < 0 || index >= seats.length) continue;
          final seat = seats[index];
          seat.userId = data['uid'] as String?;
          seat.userName = data['name'] as String?;
          seat.userAvatar = data['photoUrl'] as String?;
          seat.rtcUid = (data['rtcUid'] as num?)?.toInt();
          seat.role = data['role'] == 'host'
              ? RoomRole.host
              : seat.isOccupied
                  ? RoomRole.speaker
                  : RoomRole.listener;
          seat.isLocked = data['locked'] == true;
          seat.isMutedByHost = data['mutedByHost'] == true;
          seat.isMicOpen = data['micMuted'] != true;
        }
        return seats;
      });

  Stream<Map<String, dynamic>> watchRoom(String id) =>
      room(id).snapshots().map((snapshot) => snapshot.data() ?? const {});

  Stream<List<Map<String, dynamic>>> watchMembers(String id) => room(id)
      .collection('members')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList(growable: false));
  Stream<Map<String, dynamic>?> watchMember(String id) => room(id)
      .collection('members')
      .doc(_uid)
      .snapshots()
      .map((snapshot) => snapshot.data());

  Stream<List<Map<String, dynamic>>> watchEvents(String id) => room(id)
      .collection('events')
      .orderBy('createdAt')
      .limitToLast(100)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false));
  Stream<List<Map<String, dynamic>>> watchGiftHistory(String id) => room(id)
      .collection('events')
      .where('type', isEqualTo: 'giftSent')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false));
  Stream<Map<String, dynamic>> watchDailyTask(String id) => room(id)
      .collection('dailyTasks')
      .doc(DateTime.now().toUtc().toIso8601String().substring(0, 10))
      .collection('members')
      .doc(_uid)
      .snapshots()
      .map((snapshot) => snapshot.data() ?? const {});

  Future<void> attachPresence(String id) async {
    final ref = _database.ref('voiceRoomPresence/$id/$_uid');
    await ref.onDisconnect().remove();
    await ref.set({'connected': true, 'updatedAt': ServerValue.timestamp});
    await _call('updateVoicePresence', {'roomId': id});
  }

  Future<void> leaveRoom(String id) async {
    try {
      await _call('leaveVoiceRoom', {'roomId': id});
    } finally {
      await _database.ref('voiceRoomPresence/$id/$_uid').remove();
    }
  }

  Future<void> assignSeat(String id, int seatIndex, {String? targetUid}) =>
      _call('setVoiceSpeakerSeat', {
        'roomId': id,
        'seatIndex': seatIndex,
        if (targetUid != null) 'targetUid': targetUid
      }).then((_) {});
  Future<void> leaveSeat(String id) =>
      _call('leaveVoiceSpeakerSeat', {'roomId': id}).then((_) {});
  Future<void> setMicrophone(String id, bool muted) =>
      _call('setVoiceMicrophoneState', {'roomId': id, 'muted': muted})
          .then((_) {});
  Future<void> moderate(String id, String uid, String action) => _call(
      'moderateVoiceRoomMember',
      {'roomId': id, 'targetUid': uid, 'action': action}).then((_) {});
  Future<void> setModerator(String id, String uid, bool moderator) =>
      _call('updateVoiceRoom', {
        'roomId': id,
        'action': 'setModerator',
        'targetUid': uid,
        'moderator': moderator
      }).then((_) {});
  Future<void> update(String id, String action, Map<String, Object?> values) =>
      _call('updateVoiceRoom', {'roomId': id, 'action': action, ...values})
          .then((_) {});
  Future<void> sendGift(String id, String targetUid, String giftId) =>
      _call('sendVoiceRoomGift', {
        'roomId': id,
        'targetUid': targetUid,
        'giftId': giftId,
        'requestId': _requestId()
      }).then((_) {});
  Future<void> sendChat(String id, String text) =>
      _call('sendVoiceRoomChat', {'roomId': id, 'text': text}).then((_) {});
  Future<void> reportUser(String roomId, String targetUid, String reason) =>
      _call('reportVoiceRoomUser', {
        'roomId': roomId,
        'targetUid': targetUid,
        'reason': reason
      }).then((_) {});
  Future<void> blockUser(String targetUid) =>
      _call('blockVoiceRoomUser', {'targetUid': targetUid}).then((_) {});
  Future<int> walletBalance() async =>
      ((await _call('getVoiceWallet', const {}))['balance'] as num?)?.toInt() ??
      0;
  Stream<int> watchWallet() => _firestore
      .collection('wallets')
      .doc(_uid)
      .snapshots()
      .map((snapshot) => (snapshot.data()?['balance'] as num?)?.toInt() ?? 0);

  String _requestId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
}
