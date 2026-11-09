import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'services/real_auth_service.dart';
import 'services/localization_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/achievements_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/customization_store_viewmodel.dart';
import 'viewmodels/events_viewmodel.dart';
import 'viewmodels/family_viewmodel.dart';
import 'viewmodels/friendship_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/voice_room_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AbPlayApp());
}

class AbPlayApp extends StatelessWidget {
  const AbPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: RealAuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceRoomViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => FriendshipViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => FamilyViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => EventsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomizationStoreViewModel(),
        ),
        ChangeNotifierProvider.value(
          value: LocalizationService.instance,
        ),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, loc, _) => MaterialApp(
          title: loc.tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Consumer<AuthViewModel>(
            builder: (context, authVM, child) {
              if (authVM.isLoggedIn) {
                return const MainNavigationShell();
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
