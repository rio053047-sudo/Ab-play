import 'package:flutter/foundation.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._internal();
  LocalizationService._internal();

  String _currentLocale = 'en'; // 'en' or 'hi'
  String get currentLocale => _currentLocale;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Ab-Play',
      'tab_home': 'Ab-Play',
      'tab_voice': 'Voice Room',
      'tab_chats': 'Chats',
      'tab_discover': 'Discover',
      'tab_me': 'Me',
      'quick_match': 'Quick Match',
      'recharge': 'Recharge',
      'coins': 'Coins',
      'friends': 'Friends',
      'ranking': 'Ranking',
      'events': 'Events',
      'family': 'Family / Club',
      'store': 'Store',
      'achievements': 'Achievements',
      'admin_panel': 'Admin Center',
      'settings': 'Settings',
      'language': 'Language',
      'logout': 'Sign Out',
    },
    'hi': {
      'app_title': 'अब-प्ले',
      'tab_home': 'अब-प्ले',
      'tab_voice': 'वॉइस रूम',
      'tab_chats': 'चैट',
      'tab_discover': 'डिस्कवर',
      'tab_me': 'प्रोफ़ाइल',
      'quick_match': 'त्वरित मैच',
      'recharge': 'रिचार्ज',
      'coins': 'सिक्के',
      'friends': 'मित्र',
      'ranking': 'रैंकिंग',
      'events': 'प्रतियोगिताएं',
      'family': 'क्लब / परिवार',
      'store': 'स्टोर',
      'achievements': 'उपलब्धियां',
      'admin_panel': 'व्यवस्थापक केंद्र',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'logout': 'लॉग आउट',
    },
  };

  String tr(String key) {
    return _localizedValues[_currentLocale]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  void toggleLocale() {
    _currentLocale = _currentLocale == 'en' ? 'hi' : 'en';
    notifyListeners();
  }

  void setLocale(String langCode) {
    if (_currentLocale != langCode && (langCode == 'en' || langCode == 'hi')) {
      _currentLocale = langCode;
      notifyListeners();
    }
  }
}
