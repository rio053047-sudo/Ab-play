import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/voice_room.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/voice_room_viewmodel.dart';

class VoiceRoomLobbyScreen extends StatelessWidget {
  const VoiceRoomLobbyScreen({super.key});

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
            onPressed: () async {
              final room = await showSearch<VoiceRoomModel>(
                  context: context,
                  delegate: _VoiceRoomSearchDelegate(roomVM.publicRooms));
              if (room != null && context.mounted) {
                _enterRoom(context, room, roomVM);
              }
            },
          ),
          IconButton(
              tooltip: 'Join by room ID',
              icon: const Icon(Icons.vpn_key, color: Colors.white70),
              onPressed: () => _showJoinById(context, roomVM)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _showCreateRoomDialog(context, roomVM),
                  child: const Text('Create',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Active Live Rooms',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<VoiceRoomModel>>(
            stream: roomVM.publicRooms,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Could not load rooms: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator()));
              }
              if (snapshot.data!.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        'No public rooms are live yet. Create one to get started.',
                        style: TextStyle(color: Colors.white70)));
              }
              return Column(
                  children: snapshot.data!
                      .map((room) => _buildRoomCard(context, room, roomVM))
                      .toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(
      BuildContext context, VoiceRoomModel room, VoiceRoomViewModel roomVM) {
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
            FutureBuilder<String>(
              future: room.coverPath.isEmpty
                  ? null
                  : FirebaseStorage.instance
                      .ref(room.coverPath)
                      .getDownloadURL(),
              builder: (context, snapshot) => CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                backgroundImage:
                    snapshot.hasData ? NetworkImage(snapshot.data!) : null,
                child: snapshot.hasData
                    ? null
                    : const Icon(Icons.headset_mic_rounded,
                        color: AppColors.primary, size: 28),
              ),
            ),
            if (room.isPrivate)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
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
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
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
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: () => _enterRoom(context, room, roomVM),
          child: const Text('Join',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _enterRoom(
      BuildContext context, VoiceRoomModel room, VoiceRoomViewModel roomVM) {
    if (room.isPrivate) {
      final codeCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF221F38),
          title: const Text('Private Room Password',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: codeCtrl,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter room password',
              hintStyle: TextStyle(color: Colors.white30),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToRoom(context, room, roomVM, password: codeCtrl.text);
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

  void _navigateToRoom(
      BuildContext context, VoiceRoomModel room, VoiceRoomViewModel roomVM,
      {String? password}) async {
    try {
      await roomVM.enterRoom(room, password: password);
      if (!context.mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const VoiceRoomLiveScreen()));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    }
  }

  void _showCreateRoomDialog(BuildContext context, VoiceRoomViewModel roomVM) {
    final titleCtrl = TextEditingController(text: 'My Party Voice Room');
    final descriptionCtrl = TextEditingController();
    bool isPrivate = false;
    XFile? coverImage;
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF221F38),
          title: const Text('Create Voice Room',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              TextField(
                  controller: descriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Colors.white70))),
              TextButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null) setState(() => coverImage = picked);
                },
                icon:
                    const Icon(Icons.image_outlined, color: AppColors.primary),
                label: Text(coverImage?.name ?? 'Choose room cover image',
                    style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Private Room',
                    style: TextStyle(color: Colors.white70)),
                value: isPrivate,
                onChanged: (val) => setState(() => isPrivate = val),
              ),
              if (isPrivate)
                TextField(
                  controller: codeCtrl,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (6 to 64 characters)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await roomVM.createAndEnterRoom(
                      name: titleCtrl.text.trim(),
                      description: descriptionCtrl.text.trim(),
                      isPrivate: isPrivate,
                      password: isPrivate ? codeCtrl.text : null,
                      coverImage: coverImage);
                  if (!context.mounted) return;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VoiceRoomLiveScreen()));
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          error.toString().replaceFirst('Bad state: ', ''))));
                }
              },
              child: const Text('Create & Enter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinById(BuildContext context, VoiceRoomViewModel roomVM) {
    final idController = TextEditingController();
    final passwordController = TextEditingController();
    showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Join a room'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'Room ID')),
                TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password (private rooms only)')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      final room = VoiceRoomModel(
                          id: idController.text.trim(),
                          title: 'Voice Room',
                          hostId: '',
                          hostName: 'Host');
                      try {
                        await roomVM.enterRoom(room,
                            password: passwordController.text.isEmpty
                                ? null
                                : passwordController.text);
                        if (!context.mounted) return;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VoiceRoomLiveScreen()));
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error
                                .toString()
                                .replaceFirst('Bad state: ', ''))));
                      }
                    },
                    child: const Text('Join')),
              ],
            ));
  }
}

class _VoiceRoomSearchDelegate extends SearchDelegate<VoiceRoomModel> {
  _VoiceRoomSearchDelegate(this.rooms);
  final Stream<List<VoiceRoomModel>> rooms;

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop());
  @override
  Widget buildResults(BuildContext context) => _buildRooms(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildRooms(context);

  Widget _buildRooms(BuildContext context) =>
      StreamBuilder<List<VoiceRoomModel>>(
        stream: rooms,
        builder: (context, snapshot) {
          final term = query.trim().toLowerCase();
          final matches = (snapshot.data ?? const <VoiceRoomModel>[]).where(
              (room) =>
                  term.isEmpty ||
                  room.title.toLowerCase().contains(term) ||
                  room.hostName.toLowerCase().contains(term) ||
                  room.id.toLowerCase().contains(term));
          return ListView(
              children: matches
                  .map((room) => ListTile(
                        title: Text(room.title),
                        subtitle: Text(
                            '${room.id} · ${room.hostName} · ${room.onlineCount}/${room.maxCapacity}'),
                        onTap: () => close(context, room),
                      ))
                  .toList());
        },
      );
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
        body: Center(
            child: Text('Room closed', style: TextStyle(color: Colors.white))),
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
            final leave = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                      title: const Text('Leave voice room?'),
                      content:
                          const Text('You will disconnect from this room.'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Stay')),
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Leave'))
                      ],
                    ));
            if (leave != true || !context.mounted) return;
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Lv.${room.roomLevel}',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
              ],
            ),
            Row(children: [
              Text('ID: ${room.id}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 8),
              ValueListenableBuilder<String>(
                valueListenable: roomVM.rtcService.connectionStatus,
                builder: (_, status, __) => Text(status,
                    style: TextStyle(
                        color: status == 'connected'
                            ? Colors.greenAccent
                            : Colors.amber,
                        fontSize: 10)),
              ),
            ]),
          ],
        ),
        actions: [
          if (room.hostId == roomVM.currentUserId)
            IconButton(
              tooltip: room.isLocked ? 'Unlock room' : 'Lock room',
              icon: Icon(room.isLocked ? Icons.lock_open : Icons.lock,
                  color: Colors.white70),
              onPressed: () => roomVM.toggleRoomLock(!room.isLocked),
            ),
          IconButton(
            tooltip: 'Members and contribution ranking',
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white70),
            onPressed: () => _showMembersSheet(context, roomVM),
          ),
          // BGM Button
          IconButton(
            icon:
                const Icon(Icons.music_note_rounded, color: Colors.cyanAccent),
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
              if (roomVM.lastError != null)
                MaterialBanner(
                  content: Text(roomVM.lastError!,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red.shade900,
                  actions: [
                    TextButton(
                        onPressed: roomVM.clearError,
                        child: const Text('Dismiss'))
                  ],
                ),
              // Host Profile & Announcement Header
              _buildHostAndAnnouncementHeader(context, room),

              // 8-Seat Grid Area
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSeatsGrid(context, roomVM, room),
              ),

              StreamBuilder<Map<String, dynamic>>(
                stream: roomVM.dailyTask,
                builder: (context, snapshot) {
                  final sent =
                      (snapshot.data?['giftsSent'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [
                      const Icon(Icons.flag_outlined,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text("Daily task · send 3 gifts: $sent/3",
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ]),
                  );
                },
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

  Widget _buildHostAndAnnouncementHeader(
      BuildContext context, VoiceRoomModel room) {
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
                    Text('Host: ${room.hostName}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('HOST',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(room.announcement,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsGrid(
      BuildContext context, VoiceRoomViewModel roomVM, VoiceRoomModel room) {
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
                          ? (seat.isSpeaking
                              ? Colors.greenAccent.withValues(alpha: 0.3)
                              : const Color(0xFF2A2742))
                          : const Color(0xFF221F38),
                      border: Border.all(
                        color: seat.isSpeaking
                            ? Colors.greenAccent
                            : (seat.isOccupied
                                ? AppColors.primary
                                : Colors.white24),
                        width: seat.isSpeaking ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: seat.isLocked
                          ? const Icon(Icons.lock,
                              color: Colors.white38, size: 20)
                          : seat.isOccupied
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 26)
                              : Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (seat.isOccupied && !seat.isMicOpen)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.redAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.mic_off,
                            size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                seat.isOccupied
                    ? (seat.userName ?? 'User')
                    : 'Seat ${index + 1}',
                style: TextStyle(
                  color: seat.isOccupied ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight:
                      seat.isOccupied ? FontWeight.bold : FontWeight.normal,
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

  void _handleSeatTap(BuildContext context, VoiceRoomViewModel roomVM,
      int index, VoiceRoomSeat seat) {
    if (seat.isOccupied) {
      // Show user moderation / info sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF221F38),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(seat.userName ?? 'User',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.amber),
                title: const Text('Send Gift',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showGiftSheet(
                      context, roomVM, seat.userName ?? 'User', seat.userId!);
                },
              ),
              if (seat.userId == roomVM.currentUserId)
                ListTile(
                  leading:
                      const Icon(Icons.arrow_downward, color: Colors.redAccent),
                  title: const Text('Step Down to Listeners',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    roomVM.leaveSeat();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.mic_off, color: Colors.orangeAccent),
                title: Text(seat.isMutedByHost ? 'Unmute User' : 'Mute User',
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  roomVM.muteSeatUser(index);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.person_remove, color: Colors.redAccent),
                title: const Text('Kick from Seat',
                    style: TextStyle(color: Colors.redAccent)),
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
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Seat #${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (!seat.isLocked)
                ListTile(
                  leading: const Icon(Icons.mic, color: AppColors.primary),
                  title: const Text('Take This Seat',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    roomVM.takeSeat(index);
                  },
                ),
              ListTile(
                leading: Icon(seat.isLocked ? Icons.lock_open : Icons.lock,
                    color: Colors.amber),
                title: Text(seat.isLocked ? 'Unlock Seat' : 'Lock Seat',
                    style: const TextStyle(color: Colors.white)),
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
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
            ),
          );
        }

        if (msg.isGiftNotice) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF8008), Color(0xFFFFC837)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${msg.senderName} ${msg.text}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
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
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send,
                          color: AppColors.primary, size: 18),
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
                color:
                    roomVM.isMicMuted ? Colors.redAccent : Colors.greenAccent,
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
              onPressed: () => _showGiftSheet(
                  context, roomVM, 'yourself', roomVM.currentUserId),
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
        gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
        ],
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
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
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
            style: const TextStyle(
                color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 24),
          ),
        ],
      ),
    );
  }

  void _showGiftSheet(BuildContext context, VoiceRoomViewModel roomVM,
      String targetUser, String targetUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF221F38),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    Text('Send Gift to: $targetUser',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text('${roomVM.coinBalance}',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold)),
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
                      onTap: () async {
                        final success = await roomVM.sendGift(
                          gift: gift,
                          receiverName: targetUser,
                          receiverUid: targetUid,
                        );
                        if (!context.mounted) return;
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(roomVM.lastError ??
                                    'Gift could not be sent.')),
                          );
                        } else {
                          if (context.mounted) Navigator.pop(context);
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
                            Text(gift.icon,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(gift.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                            Text('${gift.coinCost} Coins',
                                style: const TextStyle(
                                    color: Colors.amber, fontSize: 9)),
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

  void _showMembersSheet(BuildContext context, VoiceRoomViewModel roomVM) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF221F38),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: roomVM.roomMembers,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Could not load members: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70)));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = [
                ...snapshot.data!
              ]..sort((a, b) => ((b['contributionCoins'] as num?)?.toInt() ?? 0)
                  .compareTo((a['contributionCoins'] as num?)?.toInt() ?? 0));
              return Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(children: [
                        const Text('Members · Contribution ranking',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                        TextButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _showGiftHistorySheet(context, roomVM);
                            },
                            icon:
                                const Icon(Icons.history, color: Colors.amber),
                            label: const Text('Room gift history')),
                      ])),
                  Expanded(
                      child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final uid = member['uid'] as String? ?? '';
                      final name = member['name'] as String? ?? 'Player';
                      final role = member['role'] as String? ?? 'listener';
                      final contribution =
                          (member['contributionCoins'] as num?)?.toInt() ?? 0;
                      return ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                            '$role · $contribution coins contributed',
                            style: const TextStyle(color: Colors.white60)),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          if (roomVM.activeRoom?.hostId ==
                                  roomVM.currentUserId &&
                              uid != roomVM.currentUserId)
                            IconButton(
                                tooltip: 'Make speaker',
                                icon: const Icon(Icons.mic,
                                    color: Colors.cyanAccent),
                                onPressed: () {
                                  final openSeats = roomVM.activeRoom!.seats
                                      .where((seat) =>
                                          !seat.isLocked &&
                                          !seat.isOccupied &&
                                          seat.index > 0)
                                      .toList();
                                  if (openSeats.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'There are no free speaker seats.')));
                                    return;
                                  }
                                  showDialog<void>(
                                      context: context,
                                      builder: (dialogContext) => SimpleDialog(
                                          title: const Text(
                                              'Choose a speaker seat'),
                                          children: openSeats
                                              .map((seat) => SimpleDialogOption(
                                                  child: Text(
                                                      'Seat ${seat.index + 1}'),
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        dialogContext);
                                                    unawaited(
                                                        roomVM.assignSpeaker(
                                                            uid, seat.index));
                                                  }))
                                              .toList()));
                                }),
                          if (roomVM.activeRoom?.hostId ==
                                  roomVM.currentUserId &&
                              uid != roomVM.currentUserId)
                            IconButton(
                                tooltip: 'Transfer host role',
                                icon: const Icon(Icons.star_outline,
                                    color: Colors.cyanAccent),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                            title: const Text('Transfer host?'),
                                            content: Text(
                                                'Make $name the new room host?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          dialogContext, false),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          dialogContext, true),
                                                  child: const Text('Transfer'))
                                            ],
                                          ));
                                  if (confirmed == true) {
                                    await roomVM.transferHost(uid);
                                  }
                                }),
                          if (uid != roomVM.currentUserId)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white70),
                              onSelected: (action) async {
                                if (action == 'block') {
                                  await roomVM.blockUser(uid);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('User blocked.')));
                                } else if (action == 'kick') {
                                  await roomVM.moderateMember(uid, 'kick');
                                } else if (action == 'moderator') {
                                  await roomVM.setModerator(
                                      uid, role != 'moderator');
                                } else {
                                  final reason = await showDialog<String>(
                                      context: context,
                                      builder: (dialogContext) {
                                        final controller =
                                            TextEditingController();
                                        return AlertDialog(
                                            title: const Text(
                                                'Report participant'),
                                            content: TextField(
                                                controller: controller,
                                                maxLines: 3,
                                                decoration: const InputDecoration(
                                                    hintText:
                                                        'Tell us what happened')),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          dialogContext),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          dialogContext,
                                                          controller.text
                                                              .trim()),
                                                  child: const Text('Submit'))
                                            ]);
                                      });
                                  if (reason != null && reason.isNotEmpty) {
                                    await roomVM.reportUser(uid, reason);
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'report', child: Text('Report')),
                                const PopupMenuItem(
                                    value: 'block', child: Text('Block')),
                                if (roomVM.activeRoom?.hostId ==
                                        roomVM.currentUserId &&
                                    uid != roomVM.currentUserId) ...[
                                  PopupMenuItem(
                                      value: 'kick',
                                      child: Text(
                                          'Remove ${role == 'listener' ? 'member' : 'from room'}')),
                                  PopupMenuItem(
                                      value: 'moderator',
                                      child: Text(role == 'moderator'
                                          ? 'Remove moderator'
                                          : 'Make moderator')),
                                ],
                              ],
                            ),
                          IconButton(
                              tooltip: 'Send gift',
                              icon: const Icon(Icons.card_giftcard,
                                  color: Colors.amber),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _showGiftSheet(context, roomVM, name, uid);
                              }),
                        ]),
                      );
                    },
                  )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showGiftHistorySheet(BuildContext context, VoiceRoomViewModel roomVM) {
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF221F38),
        builder: (_) => SizedBox(
              height: MediaQuery.sizeOf(context).height * .6,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: roomVM.giftHistory,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text(
                              'Could not load gift history: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white70)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No gifts sent yet.',
                              style: TextStyle(color: Colors.white70)));
                    }
                    return ListView(
                        children: snapshot.data!.map((event) {
                      final payload = event['payload'] is Map
                          ? Map<String, dynamic>.from(event['payload'] as Map)
                          : <String, dynamic>{};
                      return ListTile(
                          leading: Text(payload['giftIcon'] as String? ?? '🎁',
                              style: const TextStyle(fontSize: 24)),
                          title: Text(
                              '${payload['senderName'] ?? 'Player'} → ${payload['recipientName'] ?? 'Player'}',
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                              '${payload['giftName'] ?? 'Gift'} · ${payload['giftCoins'] ?? 0} coins',
                              style: const TextStyle(color: Colors.white60)));
                    }).toList());
                  }),
            ));
  }

  void _showBgmSheet(BuildContext context, VoiceRoomViewModel roomVM) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF221F38),
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.music_off, color: Colors.white54, size: 32),
          SizedBox(height: 12),
          Text('Shared room music is not configured yet.',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Live voice communication is provided by Agora RTC.',
              style: TextStyle(color: Colors.white60)),
        ])),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Room Settings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Room Title',
                  labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noticeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Room Announcement',
                  labelStyle: TextStyle(color: Colors.white70)),
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
