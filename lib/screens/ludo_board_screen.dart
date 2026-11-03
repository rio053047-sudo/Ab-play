import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ab_play/models/ludo/ludo_color.dart';
import 'package:ab_play/models/ludo/ludo_engine.dart';
import 'package:ab_play/models/ludo/ludo_player.dart';
import 'package:ab_play/theme/app_colors.dart';
import 'package:ab_play/theme/app_typography.dart';
import 'package:ab_play/viewmodels/ludo_viewmodel.dart';
import 'package:ab_play/widgets/ludo/ludo_board_widget.dart';

class LudoBoardScreen extends StatefulWidget {
  final String roomCode;

  const LudoBoardScreen({super.key, this.roomCode = '8421'});

  @override
  State<LudoBoardScreen> createState() => _LudoBoardScreenState();
}

class _LudoBoardScreenState extends State<LudoBoardScreen> {
  bool _isVictoryDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LudoViewModel>(context);
    final engine = viewModel.engine;

    // Trigger victory dialog only once when game finishes
    if (engine.state == LudoGameState.finished && engine.winner != null && !_isVictoryDialogShown) {
      _isVictoryDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVictoryDialog(context, viewModel);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _confirmExit(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
              ),
              child: Text(
                'LUDO #${widget.roomCode}',
                style: AppTypography.labelLarge.copyWith(
                  color: const Color(0xFFFFD700),
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
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
            icon: const Icon(Icons.volume_up, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Column(
            children: [
              // Top Player Row (Green & Yellow) with Turn Timer Rings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPremiumPlayerCard(engine.players[1], viewModel),
                  _buildPremiumPlayerCard(engine.players[2], viewModel),
                ],
              ),

              const Spacer(),

              // Board Center Widget
              LudoBoardWidget(viewModel: viewModel),

              const Spacer(),

              // Bottom Player Row (Red & Blue) with Turn Timer Rings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPremiumPlayerCard(engine.players[0], viewModel),
                  _buildPremiumPlayerCard(engine.players[3], viewModel),
                ],
              ),

              const SizedBox(height: 12),

              // Dice & Turn Action Controls with 15s Timer Bar
              _buildDiceControlSection(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumPlayerCard(LudoPlayer player, LudoViewModel viewModel) {
    final isCurrentTurn = viewModel.engine.currentPlayer.id == player.id;
    final isWarning = isCurrentTurn && viewModel.isLowTime;
    final timerProgress = viewModel.timerProgress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C192E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTurn
              ? (isWarning ? AppColors.error : const Color(0xFFFFD700))
              : Colors.white12,
          width: isCurrentTurn ? 2.0 : 1.0,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: isWarning
                      ? AppColors.error.withValues(alpha: 0.5)
                      : const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 10,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Avatar with Radial Countdown Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCurrentTurn)
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    value: timerProgress,
                    strokeWidth: 3.5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWarning ? AppColors.error : (player.color as LudoColor).color,
                    ),
                  ),
                ),
              CircleAvatar(
                radius: 15,
                backgroundColor: (player.color as LudoColor).color,
                child: Text(
                  player.name[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (isCurrentTurn) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${viewModel.remainingSeconds}s',
                      style: TextStyle(
                        color: isWarning ? AppColors.error : const Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${player.tokensHomeCount}/4 Home',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
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
    final isLowTime = viewModel.isLowTime;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C192E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLowTime ? AppColors.error.withValues(alpha: 0.6) : Colors.white12,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Turn Timer Countdown Bar
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: isLowTime ? AppColors.error : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                'Turn Timer: ${viewModel.remainingSeconds}s',
                style: TextStyle(
                  color: isLowTime ? AppColors.error : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isLowTime)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AUTO-MOVE SOON',
                    style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: viewModel.timerProgress,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLowTime ? AppColors.error : const Color(0xFFFFD700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Player Turn Banner and Interactive Dice Roll Cup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Player',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 3D Styled Dice Button
              GestureDetector(
                onTap: isMyTurn && engine.state == LudoGameState.rolling && !viewModel.isProcessingAction
                    ? () => viewModel.rollDice()
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isMyTurn
                          ? [const Color(0xFFFFE082), const Color(0xFFFFB300), const Color(0xFFFFA000)]
                          : [Colors.grey.shade700, Colors.grey.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMyTurn ? const Color(0xFFFFF8E1) : Colors.white24,
                      width: 2.0,
                    ),
                    boxShadow: [
                      if (isMyTurn)
                        BoxShadow(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Center(
                    child: viewModel.isRollingDice
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3),
                          )
                        : _buildDiceFace(engine.currentDiceValue),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiceFace(int? value) {
    if (value == null) {
      return const Text(
        '🎲',
        style: TextStyle(fontSize: 30),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B2E),
          ),
        ),
      ),
    );
  }

  void _showVictoryDialog(BuildContext context, LudoViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C192E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text('🏆 MATCH FINISHED! 🏆', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1C192E),
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
