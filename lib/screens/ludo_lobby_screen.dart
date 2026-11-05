import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ab_play/theme/app_colors.dart';
import 'package:ab_play/theme/app_typography.dart';
import 'package:ab_play/viewmodels/ludo_viewmodel.dart';
import 'package:ab_play/screens/ludo_board_screen.dart';

class LudoLobbyScreen extends StatefulWidget {
  const LudoLobbyScreen({super.key});

  @override
  State<LudoLobbyScreen> createState() => _LudoLobbyScreenState();
}

class _LudoLobbyScreenState extends State<LudoLobbyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ludo Master',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '12,500',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFFF7A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎲 Ab-Play Ludo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Play local matches or create/join custom rooms!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Create / Join Custom Room Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_box_rounded, color: Colors.white),
                      label: const Text('Create Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleCreateRoom(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.meeting_room_rounded, color: Color(0xFF00E676)),
                      label: const Text('Join Room', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                      onPressed: () => _handleJoinRoom(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                'Select Game Mode',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    _buildModeCard(
                      context: context,
                      title: 'Quick Match (Vs Bots)',
                      subtitle: 'Fast 4-Player Ludo match with AI bots',
                      icon: Icons.smart_toy,
                      badge: 'Hot',
                      badgeColor: AppColors.error,
                      gradientColors: [const Color(0xFF6B38FF), const Color(0xFFA838FF)],
                      onTap: () => _startMatch(context, roomCode: 'QUICK_${Random().nextInt(9000) + 1000}'),
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      context: context,
                      title: 'Classic 4-Player',
                      subtitle: 'Traditional rules, earn coin rewards',
                      icon: Icons.group,
                      badge: '100 Coins',
                      badgeColor: Colors.amber,
                      gradientColors: [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
                      onTap: () => _startMatch(context, roomCode: 'CLASSIC_${Random().nextInt(9000) + 1000}'),
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      context: context,
                      title: 'Pass & Play',
                      subtitle: 'Play on 1 device with local friends',
                      icon: Icons.phone_android,
                      gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                      onTap: () => _startMatch(context, roomCode: 'LOCAL_PASS_PLAY'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor ?? AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }

  void _handleCreateRoom(BuildContext context) {
    final generatedCode = '${Random().nextInt(899999) + 100000}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Room Created!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this Room Code with friends:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141221),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    generatedCode,
                    style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Room Code $generatedCode copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Online multiplayer sockets are offline; game starts with local AI bots.',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              _startMatch(context, roomCode: generatedCode);
            },
            child: const Text('Enter Room'),
          )
        ],
      ),
    );
  }

  void _handleJoinRoom(BuildContext context) {
    _roomCodeController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Join Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter 6-digit Room Code:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: _roomCodeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: '123456',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF141221),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Online server connectivity is offline; room launches in local mode.',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final code = _roomCodeController.text.trim();
              if (code.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid room code')),
                );
                return;
              }
              Navigator.pop(context);
              _startMatch(context, roomCode: code);
            },
            child: const Text('Join Match'),
          )
        ],
      ),
    );
  }

  void _startMatch(BuildContext context, {String roomCode = '8421'}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LudoViewModel(),
          child: LudoBoardScreen(roomCode: roomCode),
        ),
      ),
    );
  }
}
