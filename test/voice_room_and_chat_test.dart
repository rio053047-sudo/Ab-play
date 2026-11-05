import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/models/voice_room.dart';
import 'package:ab_play/models/chat_model.dart';
import 'package:ab_play/viewmodels/voice_room_viewmodel.dart';
import 'package:ab_play/viewmodels/chat_viewmodel.dart';

void main() {
  group('VoiceRoomViewModel Tests', () {
    test('takes and leaves seats with correct role updates', () async {
      final roomVM = VoiceRoomViewModel();
      roomVM.setLoggedInUser('test_u1', 'PlayerOne');

      final testRoom = VoiceRoomModel(
        id: 'r_test',
        title: 'Test Party Room',
        hostId: 'host_99',
        hostName: 'RoomHost',
      );

      await roomVM.enterRoom(testRoom);
      expect(roomVM.activeRoom, isNotNull);
      expect(roomVM.isMicMuted, isTrue);

      // Take Seat #0
      roomVM.takeSeat(0);
      expect(testRoom.seats[0].isOccupied, isTrue);
      expect(testRoom.seats[0].userId, equals('test_u1'));
      expect(roomVM.isMicMuted, isFalse);

      // Step down
      roomVM.leaveSeat();
      expect(testRoom.seats[0].isOccupied, isFalse);
      expect(roomVM.isMicMuted, isTrue);

      await roomVM.leaveRoom();
      expect(roomVM.activeRoom, isNull);
    });

    test('gifting deducts coins and triggers combo multiplier', () async {
      final roomVM = VoiceRoomViewModel();
      roomVM.setLoggedInUser('test_u1', 'PlayerOne');

      final testRoom = VoiceRoomModel(
        id: 'r_test2',
        title: 'Gift Room',
        hostId: 'host_99',
        hostName: 'RoomHost',
      );

      await roomVM.enterRoom(testRoom);
      int coinBalance = 500;

      final gift = VoiceRoomViewModel.standardGifts.first; // Rose (10 coins)
      final success = roomVM.sendGift(
        gift: gift,
        receiverName: 'RoomHost',
        getCoinBalance: () => coinBalance,
        deductCoins: (amount) => coinBalance -= amount,
      );

      expect(success, isTrue);
      expect(coinBalance, equals(490));
      expect(roomVM.lastSentGiftCombo, equals(1));

      // Combo send
      roomVM.sendGift(
        gift: gift,
        receiverName: 'RoomHost',
        getCoinBalance: () => coinBalance,
        deductCoins: (amount) => coinBalance -= amount,
      );
      expect(coinBalance, equals(480));
      expect(roomVM.lastSentGiftCombo, equals(2));
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

      chatVM.sendRoomInvite(conv.id, roomId: 'room_101', roomTitle: 'Lofi Room');
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
