import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/achievements_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achVM = Provider.of<AchievementsViewModel>(context);
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Achievements & Badges', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏅 Hall of Fame Badges', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Unlock exclusive profile badges and free coin rewards across all 8 milestones!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.stars_rounded, color: Colors.white, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('All Achievements (8)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...achVM.achievements.map((item) => _buildAchievementCard(context, item, achVM, homeVM)),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, AchievementItem item, AchievementsViewModel vm, HomeViewModel homeVM) {
    final ratio = (item.progress / item.targetProgress).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.isCompleted ? Colors.amber.withValues(alpha: 0.2) : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Text(item.icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('+${item.rewardCoins} Coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.description, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(item.isCompleted ? Colors.greenAccent : AppColors.primary),
                  minHeight: 5,
                ),
                const SizedBox(height: 4),
                Text('${item.progress}/${item.targetProgress}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: item.isClaimed ? Colors.white24 : (item.isCompleted ? Colors.greenAccent : Colors.white10),
              foregroundColor: item.isCompleted && !item.isClaimed ? Colors.black : Colors.white54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: item.isCompleted && !item.isClaimed
                ? () {
                    vm.claimAchievement(item.id, (coins) => homeVM.addCoins(coins));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unlocked "${item.title}" (+${item.rewardCoins} Coins)! 🎉')),
                    );
                  }
                : null,
            child: Text(item.isClaimed ? 'Claimed' : (item.isCompleted ? 'Claim' : 'Locked'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
