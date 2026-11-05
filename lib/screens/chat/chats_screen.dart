import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/voice_room_viewmodel.dart';
import '../voice_room/voice_room_screen.dart';

class ChatsTabScreen extends StatefulWidget {
  const ChatsTabScreen({super.key});

  @override
  State<ChatsTabScreen> createState() => _ChatsTabScreenState();
}

class _ChatsTabScreenState extends State<ChatsTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = Provider.of<ChatViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text(
          'Chats & Friends',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Messages'),
                  if (chatVM.conversations.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: Text('${chatVM.conversations.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Friends'),
                  if (chatVM.friendRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text('${chatVM.friendRequests.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationsTab(context, chatVM),
          _buildFriendsTab(context, chatVM),
        ],
      ),
    );
  }

  Widget _buildConversationsTab(BuildContext context, ChatViewModel chatVM) {
    if (chatVM.conversations.isEmpty) {
      return const Center(
        child: Text('No active conversations', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatVM.conversations.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, index) {
        final conv = chatVM.conversations[index];
        final lastMsg = conv.lastMessage;

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationDetailScreen(conversation: conv),
              ),
            );
          },
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: conv.isGroup ? Colors.teal : AppColors.primary,
                child: Icon(conv.isGroup ? Icons.groups : Icons.person, color: Colors.white),
              ),
              if (!conv.isGroup && conv.participants.isNotEmpty && conv.participants.first.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF141221), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            conv.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            lastMsg != null ? lastMsg.content : 'No messages yet',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            lastMsg != null ? '${lastMsg.timestamp.hour}:${lastMsg.timestamp.minute.toString().padLeft(2, '0')}' : '',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        );
      },
    );
  }

  Widget _buildFriendsTab(BuildContext context, ChatViewModel chatVM) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Friend Requests Section
        if (chatVM.friendRequests.isNotEmpty) ...[
          const Text(
            'Friend Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...chatVM.friendRequests.map((req) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(req.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                    onPressed: () => chatVM.acceptFriendRequest(req),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () => chatVM.rejectFriendRequest(req),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],

        // Friends List Section
        const Text(
          'My Friends',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...chatVM.friends.map((friend) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                if (friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            title: Text(friend.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(friend.isOnline ? 'Online now' : 'Offline', style: TextStyle(color: friend.isOnline ? Colors.greenAccent : Colors.white38, fontSize: 11)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final conv = chatVM.createOrGetDirectConversation(friend);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConversationDetailScreen(conversation: conv)),
                );
              },
              child: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        )),

        const SizedBox(height: 16),

        // Add Friends Section
        const Text(
          'Discover Friends',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...chatVM.discoverUsers.map((user) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.indigoAccent,
              child: Icon(Icons.person_add, color: Colors.white),
            ),
            title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => chatVM.sendFriendRequest(user),
              child: const Text('Add Friend', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ),
        )),
      ],
    );
  }
}

class ConversationDetailScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ConversationDetailScreen({super.key, required this.conversation});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = Provider.of<ChatViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: Text(widget.conversation.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: AppColors.primary),
            tooltip: 'Invite to Voice Room',
            onPressed: () => _showInviteVoiceRoomDialog(context, chatVM),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: widget.conversation.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.conversation.messages[index];
                final isMe = msg.senderId == chatVM.currentUserId;
                return _buildMessageBubble(context, msg, isMe);
              },
            ),
          ),
          _buildInputBar(context, chatVM),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isMe) {
    _scrollToBottom();

    if (msg.type == ChatMessageType.roomInvite) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Colors.cyanAccent, size: 18),
                  SizedBox(width: 6),
                  Text('Voice Room Invitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Text(msg.content, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6A11CB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                onPressed: () {
                  final roomVM = Provider.of<VoiceRoomViewModel>(context, listen: false);
                  final targetRoom = VoiceRoomLobbyScreen.defaultRooms.first;
                  roomVM.enterRoom(targetRoom);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VoiceRoomLiveScreen()),
                  );
                },
                child: const Text('Join Room Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
      );
    }

    if (msg.type == ChatMessageType.voice) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : const Color(0xFF2A2742),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Voice memo (5")', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : const Color(0xFF2A2742),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.content,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatViewModel chatVM) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E1B2E),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Voice memo shortcut
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.cyanAccent),
              onPressed: () {
                chatVM.sendVoiceMessage(widget.conversation.id, 5);
              },
            ),
            // Input field
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2742),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary, size: 18),
                      onPressed: () {
                        chatVM.sendTextMessage(widget.conversation.id, _msgController.text);
                        _msgController.clear();
                      },
                    ),
                  ),
                  onSubmitted: (text) {
                    chatVM.sendTextMessage(widget.conversation.id, text);
                    _msgController.clear();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
              onPressed: () {
                chatVM.sendTextMessage(widget.conversation.id, '🎉 Let’s Party! 🚀');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteVoiceRoomDialog(BuildContext context, ChatViewModel chatVM) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        title: const Text('Send Room Invite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Invite conversation members to join "🎧 Chill Night Lofi & Chat"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              chatVM.sendRoomInvite(
                widget.conversation.id,
                roomId: 'room_101',
                roomTitle: '🎧 Chill Night Lofi & Chat',
              );
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}
