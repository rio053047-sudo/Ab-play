import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/voice_room.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/voice_room_viewmodel.dart';
import '../../services/room_bgm_service.dart';

class VoiceRoomLobbyScreen extends StatelessWidget {
  const VoiceRoomLobbyScreen({super.key});

  static final List<VoiceRoomModel> defaultRooms = [
    VoiceRoomModel(
      id: 'room_101',
      title: '🎧 Chill Night Lofi & Chat',
      description: 'Relaxing music, casual talks, welcoming all new friends!',
      hostId: 'host_101',
      hostName: 'DJ_Luna',
      tag: RoomTag.music,
      roomLevel: 5,
      onlineCount: 38,
      maxCapacity: 50,
      seats: [
        VoiceRoomSeat(index: 0, userId: 'user_1', userName: 'Alex', isMicOpen: true, isSpeaking: true),
        VoiceRoomSeat(index: 1, userId: 'user_2', userName: 'Maya', isMicOpen: false),
        VoiceRoomSeat(index: 2),
        VoiceRoomSeat(index: 3, isLocked: true),
        VoiceRoomSeat(index: 4),
        VoiceRoomSeat(index: 5),
        VoiceRoomSeat(index: 6),
        VoiceRoomSeat(index: 7),
      ],
    ),
    VoiceRoomModel(
      id: 'room_102',
      title: '🔥 Ab-Play Gaming Squad & Voice',
      description: 'Ludo Master tournaments, team voice party!',
      hostId: 'host_102',
      hostName: 'CyberKnight',
      tag: RoomTag.gaming,
      roomLevel: 3,
      onlineCount: 24,
      maxCapacity: 50,
      seats: List.generate(8, (i) => VoiceRoomSeat(index: i)),
    ),
    VoiceRoomModel(
      id: 'room_103',
      title: '🔒 VIP Secret Lounge',
      description: 'Passcode required. Private party for friends.',
      hostId: 'host_103',
      hostName: 'PrincessAura',
      tag: RoomTag.party,
      isPrivate: true,
      passcode: '1234',
      roomLevel: 8,
      onlineCount: 12,
      maxCapacity: 30,
      seats: List.generate(8, (i) => VoiceRoomSeat(index: i)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final roomVM = Provider.of<VoiceRoomViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.mic_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Voice Rooms',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () => _showCreateRoomDialog(context, roomVM),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Party Voice Rooms',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hop into 8-seat audio rooms, chat, play BGM and send animated gifts!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6A11CB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _showCreateRoomDialog(context, roomVM),
                  child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Active Live Rooms',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...defaultRooms.map((room) => _buildRoomCard(context, room, roomVM)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, VoiceRoomModel room, VoiceRoomViewModel roomVM) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 28),
            ),
            if (room.isPrivate)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.lock, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                room.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv.${room.roomLevel}',
                style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Text(
                'Host: ${room.hostName}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.people_alt, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${room.onlineCount}/${room.maxCapacity}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () => _enterRoom(context, room, roomVM),
          child: const Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _enterRoom(BuildContext context, VoiceRoomModel room, VoiceRoomViewModel roomVM) {
    if (room.isPrivate) {
      final codeCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF221F38),
          title: const Text('Private Room Passcode', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: codeCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter 4-digit code',
              hintStyle: TextStyle(color: Colors.white30),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeCtrl.text == room.passcode) {
                  Navigator.pop(context);
                  _navigateToRoom(context, room, roomVM);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Passcode!')),
                  );
                }
              },
              child: const Text('Enter'),
            ),
          ],
        ),
      );
    } else {
      _navigateToRoom(context, room, roomVM);
    }
  }

  void _navigateToRoom(BuildContext context, VoiceRoomModel room, VoiceRoomViewModel roomVM) async {
    await roomVM.enterRoom(room);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VoiceRoomLiveScreen(),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context, VoiceRoomViewModel roomVM) {
    final titleCtrl = TextEditingController(text: 'My Party Voice Room');
    bool isPrivate = false;
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF221F38),
          title: const Text('Create Voice Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Room Title',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Private Room', style: TextStyle(color: Colors.white70)),
                value: isPrivate,
                onChanged: (val) => setState(() => isPrivate = val),
              ),
              if (isPrivate)
                TextField(
                  controller: codeCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '4-digit Passcode',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final newRoom = VoiceRoomModel(
                  id: 'room_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim().isEmpty ? 'My Voice Room' : titleCtrl.text.trim(),
                  hostId: roomVM.currentUserId,
                  hostName: 'AbPlay_Gamer',
                  isPrivate: isPrivate,
                  passcode: isPrivate ? codeCtrl.text : null,
                  seats: List.generate(8, (i) => VoiceRoomSeat(index: i)),
                );
                Navigator.pop(ctx);
                _navigateToRoom(context, newRoom, roomVM);
              },
              child: const Text('Create & Enter'),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceRoomLiveScreen extends StatefulWidget {
  const VoiceRoomLiveScreen({super.key});

  @override
  State<VoiceRoomLiveScreen> createState() => _VoiceRoomLiveScreenState();
}

class _VoiceRoomLiveScreenState extends State<VoiceRoomLiveScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
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
    final roomVM = Provider.of<VoiceRoomViewModel>(context);
    final room = roomVM.activeRoom;

    if (room == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF141221),
        body: Center(child: Text('Room closed', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await roomVM.leaveRoom();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    room.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                  child: Text('Lv.${room.roomLevel}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
            Text('ID: ${room.id}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          // BGM Button
          IconButton(
            icon: const Icon(Icons.music_note_rounded, color: Colors.cyanAccent),
            onPressed: () => _showBgmSheet(context, roomVM),
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => _showSettingsSheet(context, roomVM),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Host Profile & Announcement Header
              _buildHostAndAnnouncementHeader(context, room),

              // 8-Seat Grid Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSeatsGrid(context, roomVM, room),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Chat Messages Stream
              Expanded(
                child: _buildMessageList(roomVM),
              ),

              // Bottom Action & Input Bar
              _buildBottomBar(context, roomVM),
            ],
          ),

          // Gift Combo Banner Overlay
          if (roomVM.lastSentGift != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: _buildGiftBanner(roomVM),
            ),
        ],
      ),
    );
  }

  Widget _buildHostAndAnnouncementHeader(BuildContext context, VoiceRoomModel room) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1829),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.star, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Host: ${room.hostName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('HOST', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(room.announcement, style: const TextStyle(color: Colors.white60, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsGrid(BuildContext context, VoiceRoomViewModel roomVM, VoiceRoomModel room) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
      ),
      itemCount: room.seats.length,
      itemBuilder: (context, index) {
        final seat = room.seats[index];
        return GestureDetector(
          onTap: () => _handleSeatTap(context, roomVM, index, seat),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: seat.isOccupied
                          ? (seat.isSpeaking ? Colors.greenAccent.withValues(alpha: 0.3) : const Color(0xFF2A2742))
                          : const Color(0xFF221F38),
                      border: Border.all(
                        color: seat.isSpeaking
                            ? Colors.greenAccent
                            : (seat.isOccupied ? AppColors.primary : Colors.white24),
                        width: seat.isSpeaking ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: seat.isLocked
                          ? const Icon(Icons.lock, color: Colors.white38, size: 20)
                          : seat.isOccupied
                              ? const Icon(Icons.person, color: Colors.white, size: 26)
                              : Text('${index + 1}', style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (seat.isOccupied && !seat.isMicOpen)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.mic_off, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                seat.isOccupied ? (seat.userName ?? 'User') : 'Seat ${index + 1}',
                style: TextStyle(
                  color: seat.isOccupied ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: seat.isOccupied ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSeatTap(BuildContext context, VoiceRoomViewModel roomVM, int index, VoiceRoomSeat seat) {
    if (seat.isOccupied) {
      // Show user moderation / info sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF221F38),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(seat.userName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.amber),
                title: const Text('Send Gift', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showGiftSheet(context, roomVM, seat.userName ?? 'User');
                },
              ),
              if (seat.userId == roomVM.currentUserId)
                ListTile(
                  leading: const Icon(Icons.arrow_downward, color: Colors.redAccent),
                  title: const Text('Step Down to Listeners', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    roomVM.leaveSeat();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.mic_off, color: Colors.orangeAccent),
                title: Text(seat.isMutedByHost ? 'Unmute User' : 'Mute User', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  roomVM.muteSeatUser(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.redAccent),
                title: const Text('Kick from Seat', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  roomVM.kickUserFromSeat(index);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // Empty seat: Take or lock
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF221F38),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Seat #${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (!seat.isLocked)
                ListTile(
                  leading: const Icon(Icons.mic, color: AppColors.primary),
                  title: const Text('Take This Seat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    roomVM.takeSeat(index);
                  },
                ),
              ListTile(
                leading: Icon(seat.isLocked ? Icons.lock_open : Icons.lock, color: Colors.amber),
                title: Text(seat.isLocked ? 'Unlock Seat' : 'Lock Seat', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  roomVM.toggleLockSeat(index);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMessageList(VoiceRoomViewModel roomVM) {
    _scrollToBottom();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: roomVM.messages.length,
      itemBuilder: (context, index) {
        final msg = roomVM.messages[index];
        if (msg.isSystem) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          );
        }

        if (msg.isGiftNotice) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8008), Color(0xFFFFC837)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${msg.senderName} ${msg.text}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${msg.senderName}: ',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                TextSpan(
                  text: msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, VoiceRoomViewModel roomVM) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E1B2E),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Chat Input
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2742),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Say something in room...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary, size: 18),
                      onPressed: () {
                        roomVM.sendRoomChatMessage(_chatController.text);
                        _chatController.clear();
                      },
                    ),
                  ),
                  onSubmitted: (text) {
                    roomVM.sendRoomChatMessage(text);
                    _chatController.clear();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Mic Toggle
            IconButton(
              icon: Icon(
                roomVM.isMicMuted ? Icons.mic_off : Icons.mic,
                color: roomVM.isMicMuted ? Colors.redAccent : Colors.greenAccent,
              ),
              onPressed: () => roomVM.toggleMicrophone(),
            ),

            // Speaker Toggle
            IconButton(
              icon: Icon(
                roomVM.isSpeakerMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white70,
              ),
              onPressed: () => roomVM.toggleSpeaker(),
            ),

            // Gift Button
            IconButton(
              icon: const Icon(Icons.card_giftcard, color: Colors.amber),
              onPressed: () => _showGiftSheet(context, roomVM, 'All Room Friends'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftBanner(VoiceRoomViewModel roomVM) {
    final gift = roomVM.lastSentGift!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(gift.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${gift.name} Launched!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                gift.effectName,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'x${roomVM.lastSentGiftCombo}',
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 24),
          ),
        ],
      ),
    );
  }

  void _showGiftSheet(BuildContext context, VoiceRoomViewModel roomVM, String targetUser) {
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF221F38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Send Gift to: $targetUser', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text('${homeVM.coinBalance}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: VoiceRoomViewModel.standardGifts.length,
                  itemBuilder: (context, i) {
                    final gift = VoiceRoomViewModel.standardGifts[i];
                    return GestureDetector(
                      onTap: () {
                        final success = roomVM.sendGift(
                          gift: gift,
                          receiverName: targetUser,
                          getCoinBalance: () => homeVM.coinBalance,
                          deductCoins: (amount) => homeVM.deductCoins(amount),
                        );
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Insufficient Coins! Recharge from Home.')),
                          );
                        } else {
                          setState(() {});
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2742),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(gift.icon, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(gift.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            Text('${gift.coinCost} Coins', style: const TextStyle(color: Colors.amber, fontSize: 9)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBgmSheet(BuildContext context, VoiceRoomViewModel roomVM) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF221F38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AnimatedBuilder(
        animation: roomVM.bgmService,
        builder: (context, _) {
          final bgm = roomVM.bgmService;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.cyanAccent),
                    SizedBox(width: 8),
                    Text('Room Music Player', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ...RoomBgmService.defaultPlaylists.map((track) {
                  final isSelected = bgm.currentTrack?.id == track.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(track.title, style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white)),
                    subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: IconButton(
                      icon: Icon(isSelected && bgm.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.cyanAccent),
                      onPressed: () {
                        if (isSelected) {
                          bgm.togglePlayPause();
                        } else {
                          bgm.playTrack(track);
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white54),
                    Expanded(
                      child: Slider(
                        value: bgm.volume,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) => bgm.setVolume(val),
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white54),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, VoiceRoomViewModel roomVM) {
    final room = roomVM.activeRoom!;
    final titleCtrl = TextEditingController(text: room.title);
    final noticeCtrl = TextEditingController(text: room.announcement);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF221F38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Room Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Room Title', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noticeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Room Announcement', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                roomVM.updateRoomSettings(
                  title: titleCtrl.text,
                  announcement: noticeCtrl.text,
                  isPrivate: room.isPrivate,
                  passcode: room.passcode,
                  tag: room.tag,
                );
                Navigator.pop(context);
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
