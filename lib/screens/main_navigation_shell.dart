import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/localization_service.dart';
import '../viewmodels/home_viewmodel.dart';
import 'home_screen.dart';
import 'voice_room/voice_room_screen.dart';
import 'chat/chats_screen.dart';
import 'discover/discover_tab_screen.dart';
import 'profile/profile_tab_screen.dart';
import 'store/customization_store_screen.dart';
import 'family/family_screen.dart';
import 'friendship/friendship_screen.dart';
import 'events/events_screen.dart';
import 'achievements/achievements_screen.dart';
import 'admin/admin_panel_screen.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;

    return Consumer<HomeViewModel>(
      builder: (context, homeVM, child) {
        return Scaffold(
          body: IndexedStack(
            index: homeVM.selectedTabIndex,
            children: [
              const HomeScreen(),
              const VoiceRoomLobbyScreen(),
              const ChatsTabScreen(),
              const DiscoverTabScreen(),
              ProfileTabScreen(
                onOpenStore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomizationStoreScreen())),
                onOpenFamily: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen())),
                onOpenFriendship: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendshipScreen())),
                onOpenEvents: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
                onOpenAchievements: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                onOpenAdmin: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: homeVM.selectedTabIndex,
              onTap: (index) => homeVM.setSelectedTab(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.secondaryText,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.videogame_asset_outlined),
                  activeIcon: const Icon(Icons.videogame_asset_rounded),
                  label: loc.tr('tab_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.mic_none_rounded),
                  activeIcon: const Icon(Icons.mic_rounded),
                  label: loc.tr('tab_voice'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: const Icon(Icons.chat_bubble_rounded),
                  label: loc.tr('tab_chats'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.explore_outlined),
                  activeIcon: const Icon(Icons.explore_rounded),
                  label: loc.tr('tab_discover'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline_rounded),
                  activeIcon: const Icon(Icons.person_rounded),
                  label: loc.tr('tab_me'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
