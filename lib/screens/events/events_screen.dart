import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/events_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventsVM = Provider.of<EventsViewModel>(context);
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Events & Competitions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔥 Limited-Time Missions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Complete gaming & voice challenges daily to earn free Ab-Play coins!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.military_tech_rounded, color: Colors.white, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Active Challenges', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...eventsVM.events.map((ev) => _buildEventCard(context, ev, eventsVM, homeVM)),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, GameEvent ev, EventsViewModel vm, HomeViewModel homeVM) {
    final progressRatio = (ev.currentProgress / ev.requiredProgress).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(ev.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text('${ev.remainingTime.inHours}h remaining', style: const TextStyle(color: Colors.amber, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(ev.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressRatio,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(ev.isCompleted ? Colors.greenAccent : AppColors.primary),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${ev.currentProgress}/${ev.requiredProgress}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('+${ev.rewardCoins} Coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ev.isClaimed ? Colors.white24 : (ev.isCompleted ? Colors.greenAccent : Colors.white12),
                      foregroundColor: ev.isCompleted && !ev.isClaimed ? Colors.black : Colors.white54,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    onPressed: ev.isCompleted && !ev.isClaimed
                        ? () {
                            vm.claimReward(ev.id, (coins) => homeVM.addCoins(coins));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Claimed +${ev.rewardCoins} Coins! 🎉')),
                            );
                          }
                        : null,
                    child: Text(ev.isClaimed ? 'Claimed' : (ev.isCompleted ? 'Claim' : 'In Progress'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
