import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/services/realtime_socket_client.dart';
import 'package:ab_play/viewmodels/friendship_viewmodel.dart';

void main() {
  group('RealtimeSocketClient & Friendship Stage Tests', () {
    test('Socket client handles connect, emit, and on event listeners', () async {
      final client = RealtimeSocketClient.instance;
      bool receivedCustomEvent = false;

      client.on('test:event', (data) {
        if (data['msg'] == 'hello_abplay') {
          receivedCustomEvent = true;
        }
      });

      await client.connect(serverUrl: 'wss://abplay.app/live', authToken: 'test_token');
      expect(client.isConnected, isTrue);

      client.emit('test:event', {'msg': 'hello_abplay'});
      expect(receivedCustomEvent, isTrue);

      client.disconnect();
      expect(client.isConnected, isFalse);
    });

    test('Friendship mission progresses and completes with joint activities', () {
      final vm = FriendshipViewModel();
      final rel = vm.relations.first;

      final ludoMission = rel.dailyMissions.firstWhere((m) => m.id == 'm_ludo');
      expect(ludoMission.isCompleted, isFalse);

      final initialXp = rel.xp;

      // Play Ludo match together
      vm.addFriendshipActivity(friendId: rel.friendId, activityType: 'game', basePoints: 50);

      // Verify mission completed and reward XP added (50 base + 80 mission reward)
      expect(ludoMission.isCompleted, isTrue);
      expect(rel.xp, equals(initialXp + 50 + 80));
    });

    test('Friendship serialization to and from JSON works seamlessly', () {
      final relation = FriendshipRelation(
        friendId: 'u_test',
        friendName: 'TestFriend',
        xp: 900,
        level: 4,
      );

      final json = relation.toJson();
      expect(json['friendId'], equals('u_test'));
      expect(json['xp'], equals(900));

      final restored = FriendshipRelation.fromJson(json);
      expect(restored.friendId, equals('u_test'));
      expect(restored.badgeTitle, equals('Close Buddies 🌸'));
      expect(restored.dailyMissions.isNotEmpty, isTrue);
    });
  });
}
