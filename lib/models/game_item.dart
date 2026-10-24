enum GameCategory { popular, party, casual, strategy, card }

class GameItem {
  final String id;
  final String title;
  final String subtitle;
  final String tag;
  final String playerCount;
  final GameCategory category;
  final String iconName;
  final bool isRecentlyPlayed;
  final int activePlayers;

  const GameItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.playerCount,
    required this.category,
    required this.iconName,
    this.isRecentlyPlayed = false,
    this.activePlayers = 0,
  });
}
