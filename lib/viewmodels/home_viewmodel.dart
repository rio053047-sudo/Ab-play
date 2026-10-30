import 'package:flutter/material.dart';
import '../models/game_item.dart';
import '../models/user_shortcut.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedTabIndex = 0;
  int _coinBalance = 12500;
  final String _username = "AbPlay_Gamer";
  final String _userId = "ID: 8842109";
  final int _userLevel = 12;
  final bool _isVip = true;

  int get selectedTabIndex => _selectedTabIndex;
  int get coinBalance => _coinBalance;
  String get username => _username;
  String get userId => _userId;
  int get userLevel => _userLevel;
  bool get isVip => _isVip;

  final List<UserShortcut> _shortcuts = const [
    UserShortcut(
      id: 'ranking',
      title: 'Ranking',
      icon: Icons.emoji_events_rounded,
      iconColor: Color(0xFFFFB300),
      badgeColor: Color(0xFFFFF8E1),
    ),
    UserShortcut(
      id: 'task',
      title: 'My Task',
      icon: Icons.assignment_rounded,
      iconColor: Color(0xFF29B6F6),
      badgeColor: Color(0xFFE1F5FE),
      badgeText: 'HOT',
    ),
    UserShortcut(
      id: 'friends',
      title: 'Friends',
      icon: Icons.people_alt_rounded,
      iconColor: Color(0xFFAB47BC),
      badgeColor: Color(0xFFF3E5F5),
    ),
  ];

  List<UserShortcut> get shortcuts => _shortcuts;

  final List<GameItem> _games = const [
    GameItem(
      id: 'spy',
      title: "Who's the Spy",
      subtitle: 'Find the undercover liar!',
      tag: 'PARTY',
      playerCount: '6-10 Players',
      category: GameCategory.party,
      iconName: 'spy_game',
      isRecentlyPlayed: true,
      activePlayers: 12430,
    ),
    GameItem(
      id: 'paint_hide',
      title: 'Paint to Hide',
      subtitle: 'Color camouflage challenge',
      tag: 'NEW',
      playerCount: '4-8 Players',
      category: GameCategory.casual,
      iconName: 'paint_hide',
      isRecentlyPlayed: false,
      activePlayers: 8900,
    ),
    GameItem(
      id: 'trickster',
      title: "Trickster's Challenge",
      subtitle: 'Witty party quiz & tricks',
      tag: 'HOT',
      playerCount: '2-6 Players',
      category: GameCategory.party,
      iconName: 'trickster',
      isRecentlyPlayed: false,
      activePlayers: 15400,
    ),
    GameItem(
      id: 'hide_seek',
      title: 'Hide and Seek',
      subtitle: 'Classic room escape fun',
      tag: 'POPULAR',
      playerCount: '4-10 Players',
      category: GameCategory.popular,
      iconName: 'hide_seek',
      isRecentlyPlayed: true,
      activePlayers: 22100,
    ),
    GameItem(
      id: 'werewolf',
      title: 'Space Werewolf',
      subtitle: 'Deduction & voice survival',
      tag: 'VOICE',
      playerCount: '6-12 Players',
      category: GameCategory.strategy,
      iconName: 'werewolf',
      isRecentlyPlayed: false,
      activePlayers: 31200,
    ),
    GameItem(
      id: 'oh_my_card',
      title: 'Oh My Card',
      subtitle: 'Fast-paced Uno style match',
      tag: 'CARD',
      playerCount: '2-4 Players',
      category: GameCategory.card,
      iconName: 'oh_my_card',
      isRecentlyPlayed: true,
      activePlayers: 19800,
    ),
    GameItem(
      id: 'ludo',
      title: 'Ab-Play Ludo',
      subtitle: 'Classic board roll & race',
      tag: 'CLASSIC',
      playerCount: '2-4 Players',
      category: GameCategory.popular,
      iconName: 'ludo',
      isRecentlyPlayed: true,
      activePlayers: 45000,
    ),
    GameItem(
      id: 'draw_guess',
      title: 'Guess My Drawing',
      subtitle: 'Draw fast, guess right!',
      tag: 'CREATIVE',
      playerCount: '4-8 Players',
      category: GameCategory.casual,
      iconName: 'draw_guess',
      isRecentlyPlayed: true,
      activePlayers: 11200,
    ),
  ];

  List<GameItem> get games => _games;

  List<GameItem> get recentlyPlayedGames =>
      _games.where((g) => g.isRecentlyPlayed).toList();

  void setSelectedTab(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void addCoins(int amount) {
    _coinBalance += amount;
    notifyListeners();
  }
}
