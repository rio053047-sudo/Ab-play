import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../help_and_legal.dart';

class ProfileTabScreen extends StatelessWidget {
  final VoidCallback? onOpenAdmin;
  final VoidCallback? onOpenStore;
  final VoidCallback? onOpenFamily;
  final VoidCallback? onOpenEvents;
  final VoidCallback? onOpenAchievements;
  final VoidCallback? onOpenFriendship;

  const ProfileTabScreen({
    super.key,
    this.onOpenAdmin,
    this.onOpenStore,
    this.onOpenFamily,
    this.onOpenEvents,
    this.onOpenAchievements,
    this.onOpenFriendship,
  });

  @override
  Widget build(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);
    final loc = LocalizationService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: Text(
          loc.tr('tab_me'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Language Switcher (Hindi / English)
          IconButton(
            icon: const Icon(Icons.translate_rounded, color: Colors.cyanAccent),
            tooltip: 'Switch Language / भाषा बदलें',
            onPressed: () {
              loc.toggleLocale();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Language changed to: ${loc.currentLocale == 'en' ? 'English' : 'हिंदी'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1654), Color(0xFF1A103C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, size: 44, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Lv.${homeVM.userLevel}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              homeVM.username,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('VIP 2', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        homeVM.userId,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatItem('Followers', '342'),
                          const SizedBox(width: 16),
                          _buildStatItem('Following', '128'),
                          const SizedBox(width: 16),
                          _buildStatItem('Visitors', '1.2k'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Wallet Pill Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ab-Play Coin Wallet', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          '${homeVM.coinBalance} Coins',
                          style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    homeVM.addCoins(500);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recharged +500 Coins successfully!')),
                    );
                  },
                  child: Text(loc.tr('recharge'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Core Features Menu Grid
          Text(
            loc.tr('app_title') + ' Services',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildActionTile(
            icon: Icons.storefront_rounded,
            color: Colors.pinkAccent,
            title: 'Profile Customization Store',
            subtitle: 'Avatar frames, entry effects, and titles',
            onTap: onOpenStore,
          ),
          _buildActionTile(
            icon: Icons.diversity_3_rounded,
            color: Colors.tealAccent,
            title: 'Family & Clubs',
            subtitle: 'Join top clubs, donate & level up',
            onTap: onOpenFamily,
          ),
          _buildActionTile(
            icon: Icons.favorite_rounded,
            color: Colors.redAccent,
            title: 'Friendship Level & Badges',
            subtitle: 'Earn friendship XP & partner frames',
            onTap: onOpenFriendship,
          ),
          _buildActionTile(
            icon: Icons.emoji_events_rounded,
            color: Colors.amber,
            title: 'Events & Tournaments',
            subtitle: 'Daily quests, limited-time challenges',
            onTap: onOpenEvents,
          ),
          _buildActionTile(
            icon: Icons.military_tech_rounded,
            color: Colors.cyanAccent,
            title: 'Achievements & Badges',
            subtitle: 'Claim reward XP and display medals',
            onTap: onOpenAchievements,
          ),
          _buildActionTile(
            icon: Icons.admin_panel_settings_rounded,
            color: Colors.deepOrangeAccent,
            title: 'Admin & Moderation Panel',
            subtitle: 'Role-based platform control & safety',
            onTap: onOpenAdmin,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF221F38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Settings & Privacy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.greenAccent),
              title: const Text('Account Security & Logins', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none, color: Colors.amber),
              title: const Text('Notification Preferences', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.cyanAccent),
              title: const Text('Help Center & FAQs', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => const HelpDialog());
              },
            ),
          ],
        ),
      ),
    );
  }
}
