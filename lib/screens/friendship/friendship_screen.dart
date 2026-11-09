import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/friendship_viewmodel.dart';

class FriendshipScreen extends StatelessWidget {
  const FriendshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friendshipVM = Provider.of<FriendshipViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Friendship & CP Level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💖 Grow Friendship Together',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Play Ludo, voice chat, and complete daily partner missions to unlock rare CP badges and frames!',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Your Best Buddies', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...friendshipVM.relations.map((rel) => _buildRelationCard(context, rel, friendshipVM)),
        ],
      ),
    );
  }

  Widget _buildRelationCard(BuildContext context, FriendshipRelation rel, FriendshipViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.pinkAccent.withValues(alpha: 0.3),
                child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(rel.friendName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(8)),
                          child: Text('Lv.${rel.level}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(rel.badgeTitle, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          LinearProgressIndicator(
            value: (rel.xp % 300) / 300,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP: ${rel.xp} pts', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text('Daily Cap: ${rel.dailyXpEarned}/${FriendshipRelation.maxDailyXp}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),

          // Partner Daily Missions
          const Text(
            'Daily Partner Missions',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...rel.dailyMissions.map((mission) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF221F38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mission.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${mission.current}/${mission.target} • +${mission.rewardXp} XP', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                    ],
                  ),
                ),
                Icon(
                  mission.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: mission.isCompleted ? Colors.greenAccent : Colors.white38,
                  size: 18,
                ),
              ],
            ),
          )),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.casino, size: 16),
                  label: const Text('Play Ludo (+50 XP)', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final ok = vm.addFriendshipActivity(friendId: rel.friendId, activityType: 'game', basePoints: 50);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('+50 Friendship XP & Mission Progress with ${rel.friendName}!')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mic, size: 16),
                  label: const Text('Voice Chat (+30 XP)', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final ok = vm.addFriendshipActivity(friendId: rel.friendId, activityType: 'voice', basePoints: 30);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('+30 Friendship XP & Voice Progress with ${rel.friendName}!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
