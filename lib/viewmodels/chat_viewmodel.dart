import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatViewModel extends ChangeNotifier {
  final String _currentUserId = '8842109';
  final String _currentUserName = 'AbPlay_Gamer';

  final List<ChatUser> _users = [
    ChatUser(id: 'u_101', name: 'Sophia VIP', isOnline: true, status: FriendshipStatus.friends),
    ChatUser(id: 'u_102', name: 'Leo Gamer', isOnline: true, status: FriendshipStatus.friends),
    ChatUser(id: 'u_103', name: 'Elena Song', isOnline: false, status: FriendshipStatus.friends),
    ChatUser(id: 'u_104', name: 'PixelKing', isOnline: false, status: FriendshipStatus.received),
    ChatUser(id: 'u_105', name: 'Zoe Explorer', isOnline: true, status: FriendshipStatus.none),
  ];

  late final List<ChatConversation> _conversations;

  ChatViewModel() {
    _conversations = [
      ChatConversation(
        id: 'conv_1',
        title: 'Sophia VIP',
        isGroup: false,
        participants: [_users[0]],
        messages: [
          ChatMessage(
            id: 'm1',
            senderId: 'u_101',
            senderName: 'Sophia VIP',
            content: 'Hey! Join my voice room later tonight! 🎧',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          ChatMessage(
            id: 'm2',
            senderId: _currentUserId,
            senderName: _currentUserName,
            content: 'Sure, I will definitely join after this Ludo match!',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
      ChatConversation(
        id: 'conv_group_1',
        title: '🎮 Ab-Play Elite Squad',
        isGroup: true,
        participants: [_users[0], _users[1], _users[2]],
        messages: [
          ChatMessage(
            id: 'gm1',
            senderId: 'u_102',
            senderName: 'Leo Gamer',
            content: 'Who wants to start a 4-Player Ludo game?',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          ChatMessage(
            id: 'gm2',
            senderId: 'u_101',
            senderName: 'Sophia VIP',
            type: ChatMessageType.roomInvite,
            content: 'Voice Room: "🎧 Chill Night Lofi & Chat"',
            metadata: {'roomId': 'room_101', 'roomTitle': '🎧 Chill Night Lofi & Chat'},
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
    ];
  }

  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<ChatUser> get friends => _users.where((u) => u.status == FriendshipStatus.friends).toList();
  List<ChatUser> get friendRequests => _users.where((u) => u.status == FriendshipStatus.received).toList();
  List<ChatUser> get discoverUsers => _users.where((u) => u.status == FriendshipStatus.none).toList();

  void sendTextMessage(String conversationId, String text) {
    if (text.trim().isEmpty) return;
    final conv = _conversations.firstWhere((c) => c.id == conversationId);
    conv.messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        content: text.trim(),
      ),
    );
    notifyListeners();
  }

  void sendVoiceMessage(String conversationId, int secondsDuration) {
    final conv = _conversations.firstWhere((c) => c.id == conversationId);
    conv.messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        type: ChatMessageType.voice,
        content: 'Voice message ($secondsDuration" sec)',
        metadata: {'duration': secondsDuration},
      ),
    );
    notifyListeners();
  }

  void sendImageMessage(String conversationId, String imageUrl) {
    final conv = _conversations.firstWhere((c) => c.id == conversationId);
    conv.messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        type: ChatMessageType.image,
        content: imageUrl,
      ),
    );
    notifyListeners();
  }

  void sendRoomInvite(String conversationId, {required String roomId, required String roomTitle}) {
    final conv = _conversations.firstWhere((c) => c.id == conversationId);
    conv.messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        type: ChatMessageType.roomInvite,
        content: 'Voice Room: "$roomTitle"',
        metadata: {'roomId': roomId, 'roomTitle': roomTitle},
      ),
    );
    notifyListeners();
  }

  void acceptFriendRequest(ChatUser user) {
    user.status = FriendshipStatus.friends;
    // Auto-create direct conversation if none exists
    final existing = _conversations.where((c) => !c.isGroup && c.participants.any((p) => p.id == user.id));
    if (existing.isEmpty) {
      _conversations.insert(
        0,
        ChatConversation(
          id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
          title: user.name,
          isGroup: false,
          participants: [user],
          messages: [
            ChatMessage(
              id: 'init_msg',
              senderId: _currentUserId,
              senderName: _currentUserName,
              content: 'You are now friends on Ab-Play! Say hello! 👋',
            ),
          ],
        ),
      );
    }
    notifyListeners();
  }

  void rejectFriendRequest(ChatUser user) {
    user.status = FriendshipStatus.none;
    notifyListeners();
  }

  void sendFriendRequest(ChatUser user) {
    user.status = FriendshipStatus.requested;
    notifyListeners();
  }

  ChatConversation createOrGetDirectConversation(ChatUser user) {
    final existing = _conversations.firstWhere(
      (c) => !c.isGroup && c.participants.any((p) => p.id == user.id),
      orElse: () {
        final newConv = ChatConversation(
          id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
          title: user.name,
          isGroup: false,
          participants: [user],
        );
        _conversations.insert(0, newConv);
        return newConv;
      },
    );
    notifyListeners();
    return existing;
  }
}
