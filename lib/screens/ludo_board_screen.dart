import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ab_play/models/ludo/ludo_color.dart';
import 'package:ab_play/models/ludo/ludo_engine.dart';
import 'package:ab_play/theme/app_colors.dart';
import 'package:ab_play/theme/app_typography.dart';
import 'package:ab_play/viewmodels/ludo_viewmodel.dart';
import 'package:ab_play/widgets/ludo/ludo_board_widget.dart';

class LudoBoardScreen extends StatelessWidget {
  final String roomCode;

  const LudoBoardScreen({super.key, this.roomCode = '8421'});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LudoViewModel>(context);
    final engine = viewModel.engine;

    // Trigger victory dialog when game finishes
    if (engine.state == LudoGameState.finished && engine.winner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVictoryDialog(context, viewModel);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _confirmExit(context),
        ),
        title: Text(
          'Ludo Room #$roomCode',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: AppColors.success),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice room connected!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Top Player Row (Green & Yellow)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerCard(engine.players[1], engine.currentPlayer.color == LudoColor.green),
                  _buildPlayerCard(engine.players[2], engine.currentPlayer.color == LudoColor.yellow),
                ],
              ),

              const Spacer(),

              // Board Center Widget
              LudoBoardWidget(viewModel: viewModel),

              const Spacer(),

              // Bottom Player Row (Red & Blue)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerCard(engine.players[0], engine.currentPlayer.color == LudoColor.red),
                  _buildPlayerCard(engine.players[3], engine.currentPlayer.color == LudoColor.blue),
                ],
              ),

              const SizedBox(height: 16),

              // Dice & Turn Action Controls
              _buildDiceControlSection(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(dynamic player, bool isCurrentTurn) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTurn ? (player.color as LudoColor).color.withValues(alpha: 0.3) : const Color(0xFF221F38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? (player.color as LudoColor).color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: (player.color as LudoColor).color,
            child: Text(
              player.name[0],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                '${player.tokensHomeCount}/4 Home',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiceControlSection(BuildContext context, LudoViewModel viewModel) {
    final engine = viewModel.engine;
    final isMyTurn = !engine.currentPlayer.isBot;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF221F38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Turn Banner
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Turn',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: engine.currentPlayer.color.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    engine.currentPlayer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Dice Button / Value Box
          GestureDetector(
            onTap: isMyTurn && engine.state == LudoGameState.rolling
                ? () => viewModel.rollDice()
                : null,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMyTurn
                      ? [AppColors.primary, AppColors.secondary]
                      : [Colors.grey.shade700, Colors.grey.shade800],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isMyTurn)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    )
                ],
              ),
              child: Center(
                child: viewModel.isRollingDice
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        engine.currentDiceValue != null
                            ? '${engine.currentDiceValue}'
                            : '🎲',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showVictoryDialog(BuildContext context, LudoViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text('🏆 MATCH FINISHED! 🏆', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${viewModel.engine.winner?.displayName} Player Wins!',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reward: +500 Coins',
              style: TextStyle(color: AppColors.success, fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // return to lobby
            },
            child: const Text('Back to Lobby'),
          )
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        title: const Text('Leave Match?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to exit the Ludo room?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave'),
          )
        ],
      ),
    );
  }
}
