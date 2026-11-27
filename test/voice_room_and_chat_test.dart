import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/models/voice_room.dart';
import 'package:ab_play/models/chat_model.dart';
import 'package:ab_play/viewmodels/chat_viewmodel.dart';

void main() {
  group('VoiceRoomModel tests', () {
    test('provides eight seats and supports display model occupancy', () {
      final room = VoiceRoomModel(
          id: 'room_abcd1234', title: 'Room', hostId: 'host', hostName: 'Host');
      expect(room.maxCapacity, 8);
      expect(room.seats, hasLength(8));
      room.seats[1].occupy(uid: 'participant', name: 'Participant');
      expect(room.seats[1].isOccupied, isTrue);
      room.seats[1].leave();
      expect(room.seats[1].isOccupied, isFalse);
    });
  });

  group('ChatViewModel Tests', () {
    test('sends text and voice messages and invites to rooms', () {
      final chatVM = ChatViewModel();
      expect(chatVM.conversations.isNotEmpty, isTrue);

      final conv = chatVM.conversations.first;
      final initialCount = conv.messages.length;

      chatVM.sendTextMessage(conv.id, 'Hello world from test!');
      expect(conv.messages.length, equals(initialCount + 1));
      expect(conv.messages.last.content, equals('Hello world from test!'));

      chatVM.sendVoiceMessage(conv.id, 10);
      expect(conv.messages.last.type, equals(ChatMessageType.voice));

      chatVM.sendRoomInvite(conv.id,
          roomId: 'room_101', roomTitle: 'Lofi Room');
      expect(conv.messages.last.type, equals(ChatMessageType.roomInvite));
    });

    test('accepts and rejects friend requests', () {
      final chatVM = ChatViewModel();
      expect(chatVM.friendRequests.isNotEmpty, isTrue);

      final req = chatVM.friendRequests.first;
      chatVM.acceptFriendRequest(req);
      expect(req.status, equals(FriendshipStatus.friends));
      expect(chatVM.friends.contains(req), isTrue);
    });
  });
}
