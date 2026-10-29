import 'ludo_color.dart';
import 'ludo_token.dart';

class LudoPlayer {
  final String id;
  final String name;
  final LudoColor color;
  final String? avatarUrl;
  final List<LudoToken> tokens;
  final bool isBot;

  LudoPlayer({
    required this.id,
    required this.name,
    required this.color,
    this.avatarUrl,
    List<LudoToken>? tokens,
    this.isBot = false,
  }) : tokens = tokens ??
            List.generate(4, (i) => LudoToken(id: i, color: color));

  bool get hasWon => tokens.every((t) => t.isHome);

  int get tokensHomeCount => tokens.where((t) => t.isHome).length;

  LudoPlayer copyWith({
    String? name,
    List<LudoToken>? tokens,
    bool? isBot,
  }) {
    return LudoPlayer(
      id: id,
      name: name ?? this.name,
      color: color,
      avatarUrl: avatarUrl,
      tokens: tokens ?? this.tokens.map((t) => t.copyWith()).toList(),
      isBot: isBot ?? this.isBot,
    );
  }
}
