enum ChatMessageType {
  text,
  image,
  voice,
  roomInvite,
}

enum FriendshipStatus {
  none,
  requested,
  received,
  friends,
  blocked,
}

class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;
  final DateTime lastSeen;
  FriendshipStatus status;

  ChatUser({
    required this.id,
    required this.name,
    this.avatar = '',
    this.isOnline = false,
    DateTime? lastSeen,
    this.status = FriendshipStatus.none,
  }) : lastSeen = lastSeen ?? DateTime.now();
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final ChatMessageType type;
  final String content; // Text, image URL, voice duration/url, or room JSON
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.type = ChatMessageType.text,
    required this.content,
    DateTime? timestamp,
    this.isRead = false,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatConversation {
  final String id;
  final String title;
  final bool isGroup;
  final List<ChatUser> participants;
  final List<ChatMessage> messages;
  int unreadCount;

  ChatConversation({
    required this.id,
    required this.title,
    this.isGroup = false,
    required this.participants,
    List<ChatMessage>? messages,
    this.unreadCount = 0,
  }) : messages = messages ?? [];

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
}
