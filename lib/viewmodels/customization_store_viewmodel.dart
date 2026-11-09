import 'package:flutter/foundation.dart';

enum CustomizationCategory {
  frame,
  entryEffect,
  nameColor,
  bubble,
}

class StoreItem {
  final String id;
  final String title;
  final String description;
  final String icon;
  final CustomizationCategory category;
  final int coinCost;
  final bool isPermanent;
  final int daysDuration;
  bool isOwned;
  bool isEquipped;

  StoreItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.coinCost,
    this.isPermanent = true,
    this.daysDuration = 30,
    this.isOwned = false,
    this.isEquipped = false,
  });
}

class CustomizationStoreViewModel extends ChangeNotifier {
  final List<StoreItem> _catalog = [
    StoreItem(
      id: 'frame_cyber',
      title: 'Cyberpunk Neon Frame',
      description: 'Luminous glowing frame for your avatar',
      icon: '🔮',
      category: CustomizationCategory.frame,
      coinCost: 800,
      isOwned: true,
      isEquipped: true,
    ),
    StoreItem(
      id: 'frame_gold_dragon',
      title: 'Golden Dragon Frame',
      description: 'Mythical golden dragon animated frame',
      icon: '🐉',
      category: CustomizationCategory.frame,
      coinCost: 2500,
    ),
    StoreItem(
      id: 'entry_supercar',
      title: 'Supercar Entry Effect',
      description: 'Roaring supercar drives across screen on entry',
      icon: '🏎️',
      category: CustomizationCategory.entryEffect,
      coinCost: 5000,
    ),
    StoreItem(
      id: 'entry_galaxy',
      title: 'Galaxy Warp Portal',
      description: 'Cosmic portal animation when joining voice rooms',
      icon: '🌌',
      category: CustomizationCategory.entryEffect,
      coinCost: 10000,
    ),
    StoreItem(
      id: 'color_ruby',
      title: 'Ruby Red Name Glow',
      description: 'Highlight your username in vibrant ruby red',
      icon: '💎',
      category: CustomizationCategory.nameColor,
      coinCost: 600,
    ),
    StoreItem(
      id: 'bubble_retro',
      title: 'Retro Pixel Chat Bubble',
      description: 'Classic 8-bit themed chat bubble in messages',
      icon: '💬',
      category: CustomizationCategory.bubble,
      coinCost: 1200,
    ),
  ];

  List<StoreItem> get catalog => List.unmodifiable(_catalog);
  List<StoreItem> get ownedItems => _catalog.where((item) => item.isOwned).toList();

  bool purchaseItem(String itemId, int currentCoins, void Function(int) deductCoins) {
    final item = _catalog.firstWhere((i) => i.id == itemId, orElse: () => _catalog.first);
    if (!item.isOwned && currentCoins >= item.coinCost) {
      deductCoins(item.coinCost);
      item.isOwned = true;
      item.isEquipped = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void toggleEquip(String itemId) {
    final item = _catalog.firstWhere((i) => i.id == itemId);
    if (!item.isOwned) return;

    // Unequip others in same category
    if (!item.isEquipped) {
      for (var other in _catalog.where((i) => i.category == item.category)) {
        other.isEquipped = false;
      }
      item.isEquipped = true;
    } else {
      item.isEquipped = false;
    }
    notifyListeners();
  }
}
