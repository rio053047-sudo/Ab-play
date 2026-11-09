import 'package:flutter/material.dart';
import '../../services/localization_service.dart';
import '../../theme/app_colors.dart';

class DiscoverTabScreen extends StatefulWidget {
  const DiscoverTabScreen({super.key});

  @override
  State<DiscoverTabScreen> createState() => _DiscoverTabScreenState();
}

class _DiscoverTabScreenState extends State<DiscoverTabScreen> {
  final List<Map<String, dynamic>> _trendingMoments = [
    {
      'id': 'm1',
      'author': 'Sophia_Gamer',
      'avatarColor': Colors.purple,
      'time': '10m ago',
      'content': 'Won our 4-player Ludo tournament! 🎲🏆 Who wants a rematch?',
      'likes': 142,
      'comments': 28,
      'hasLiked': false,
    },
    {
      'id': 'm2',
      'author': 'DJ_Pixel',
      'avatarColor': Colors.teal,
      'time': '1h ago',
      'content': 'Live in Voice Room #101 playing Chill Beats! Tune in and grab mic! 🎧✨',
      'likes': 89,
      'comments': 15,
      'hasLiked': true,
    },
    {
      'id': 'm3',
      'author': 'CyberKnight',
      'avatarColor': Colors.blue,
      'time': '3h ago',
      'content': 'Our club "Ab-Play Phoenix" just hit Level 5! Accepting top active players now. 🛡️🔥',
      'likes': 256,
      'comments': 64,
      'hasLiked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: Text(
          loc.tr('tab_discover'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_rounded, color: AppColors.primary),
            onPressed: () => _showCreatePostDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trending Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8008), Color(0xFFFFC837)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔥 Trending Community Moments',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Share your game wins, clips, and voice room memories with friends!',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.whatshot_rounded, color: Colors.white, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Community Feed Items
          ..._trendingMoments.map((moment) => _buildMomentCard(context, moment)),
        ],
      ),
    );
  }

  Widget _buildMomentCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: item['avatarColor'] as Color,
                radius: 18,
                child: Text(
                  (item['author'] as String).substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['author'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      item['time'] as String,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white38),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item['content'] as String,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: Icon(
                  item['hasLiked'] as bool ? Icons.favorite : Icons.favorite_border,
                  color: item['hasLiked'] as bool ? Colors.redAccent : Colors.white60,
                  size: 18,
                ),
                label: Text(
                  '${item['likes']}',
                  style: TextStyle(color: item['hasLiked'] as bool ? Colors.redAccent : Colors.white60, fontSize: 12),
                ),
                onPressed: () {
                  setState(() {
                    final bool liked = item['hasLiked'] as bool;
                    item['hasLiked'] = !liked;
                    item['likes'] = (item['likes'] as int) + (liked ? -1 : 1);
                  });
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.mode_comment_outlined, color: Colors.white60, size: 18),
                label: Text('${item['comments']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                onPressed: () {},
              ),
              TextButton.icon(
                icon: const Icon(Icons.share_rounded, color: Colors.white60, size: 18),
                label: const Text('Share', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Moment link copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        title: const Text('Share a Moment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'What is happening in your games or voice room?',
            hintStyle: TextStyle(color: Colors.white30),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  _trendingMoments.insert(0, {
                    'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
                    'author': 'AbPlay_Gamer',
                    'avatarColor': AppColors.primary,
                    'time': 'Just now',
                    'content': textController.text.trim(),
                    'likes': 0,
                    'comments': 0,
                    'hasLiked': false,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
