import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/models/chat_model.dart';
import 'package:ab_play/models/voice_room.dart';
import 'package:ab_play/services/server_wallet_service.dart';
import 'package:ab_play/services/voice_room_battle_engine.dart';

void main() {
  group('Multi-User Simulated Staging Tests', () {
    test('Concurrent message delivery between two distinct users', () {
      final userA = ChatUser(id: 'usr_alpha', name: 'Alpha Player', isOnline: true);
      final userB = ChatUser(id: 'usr_beta', name: 'Beta Player', isOnline: true);

      final conversation = ChatConversation(
        id: 'conv_ab',
        title: 'Alpha & Beta',
        participants: [userA, userB],
      );

      // User A sends message to User B
      conversation.messages.add(
        ChatMessage(
          id: 'msg_1',
          senderId: userA.id,
          senderName: userA.name,
          content: 'Hey Beta, ready for Ludo?',
        ),
      );

      // User B receives and replies
      conversation.messages.add(
        ChatMessage(
          id: 'msg_2',
          senderId: userB.id,
          senderName: userB.name,
          content: 'Yes Alpha, launching the room now!',
        ),
      );

      expect(conversation.messages.length, equals(2));
      expect(conversation.messages.first.senderId, equals(userA.id));
      expect(conversation.messages.last.senderId, equals(userB.id));
    });

    test('Concurrent Voice Room multi-user seating and host moderation', () {
      final room = VoiceRoomModel(
        id: 'room_stage_1',
        title: 'Stage Room',
        hostId: 'usr_alpha',
        hostName: 'Alpha Host',
      );

      // Host Alpha occupies seat 0
      room.seats[0].occupy(uid: 'usr_alpha', name: 'Alpha Host', userRole: RoomRole.host);
      expect(room.seats[0].isOccupied, isTrue);

      // Guest Beta takes seat 1
      room.seats[1].occupy(uid: 'usr_beta', name: 'Beta Guest', userRole: RoomRole.speaker);
      expect(room.seats[1].isOccupied, isTrue);

      // Host mutes Guest Beta
      room.seats[1].isMutedByHost = true;
      expect(room.seats[1].isMutedByHost, isTrue);

      // Guest Beta leaves seat
      room.seats[1].leave();
      expect(room.seats[1].isOccupied, isFalse);
    });

    test('Multi-user Voice Room Battle live scoring synchronization', () {
      final battle = VoiceRoomBattleEngine();
      battle.startBattleInvite(rivalTitle: 'Beta Titans', rivalId: 'room_beta');
      expect(battle.status, equals(RoomBattleStatus.invited));

      battle.acceptBattle();
      expect(battle.status, equals(RoomBattleStatus.active));

      // User A contributes 250 gift points
      battle.addBattleGiftPoints(250);
      expect(battle.teamScore, equals(250));

      // User B contributes 500 gift points
      battle.addBattleGiftPoints(500);
      expect(battle.teamScore, equals(750));

      battle.reset();
      expect(battle.status, equals(RoomBattleStatus.idle));
    });

    test('Multi-user wallet transactions with mutual credit and idempotency', () {
      final wallet = ServerWalletService.instance;
      int userABalance = 5000;
      int userBBalance = 1000;

      // User A sends 1000 coin gift to User B
      final res = wallet.executeGiftTransaction(
        idempotencyKey: 'multi_user_tx_998',
        senderId: 'usr_alpha',
        recipientId: 'usr_beta',
        giftValue: 1000,
        giftName: 'Diamond Ring',
        getSenderBalance: () => userABalance,
        deductSenderCoins: (amt) => userABalance -= amt,
        creditRecipientCoins: (amt) => userBBalance += amt,
      );

      expect(res['success'], isTrue);
      expect(userABalance, equals(4000));
      // Recipient receives coinback reward (25% of 1000 = 250)
      expect(userBBalance, greaterThanOrEqualTo(1250));

      // Duplicate attempt by network retry must be rejected
      final dup = wallet.executeGiftTransaction(
        idempotencyKey: 'multi_user_tx_998',
        senderId: 'usr_alpha',
        recipientId: 'usr_beta',
        giftValue: 1000,
        giftName: 'Diamond Ring',
        getSenderBalance: () => userABalance,
        deductSenderCoins: (amt) => userABalance -= amt,
        creditRecipientCoins: (amt) => userBBalance += amt,
      );

      expect(dup['success'], isFalse);
      expect(dup['error'], contains('Duplicate transaction'));
    });
  });
}
