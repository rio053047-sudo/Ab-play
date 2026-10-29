import 'ludo_color.dart';

class LudoToken {
  final int id; // 0..3
  final LudoColor color;
  int step; // 0 = Yard, 1..51 = Main Track, 52..56 = Home Stretch, 57 = Home

  LudoToken({
    required this.id,
    required this.color,
    this.step = 0,
  });

  bool get isInYard => step == 0;
  bool get isInHomeStretch => step >= 52 && step <= 56;
  bool get isHome => step == 57;
  bool get isOnTrack => step >= 1 && step <= 51;

  int? get globalTrackIndex {
    if (!isOnTrack) return null;
    return (color.startTrackIndex + step - 1) % 52;
  }

  LudoToken copyWith({int? step}) {
    return LudoToken(
      id: id,
      color: color,
      step: step ?? this.step,
    );
  }
}
