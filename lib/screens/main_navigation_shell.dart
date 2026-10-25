import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../viewmodels/home_viewmodel.dart';
import 'home_screen.dart';
import 'tab_placeholders.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeVM, child) {
        return Scaffold(
          body: IndexedStack(
            index: homeVM.selectedTabIndex,
            children: const [
              HomeScreen(),
              VoiceRoomScreen(),
              ChatsScreen(),
              DiscoverScreen(),
              ProfileScreen(),
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.videogame_asset_outlined),
                  activeIcon: Icon(Icons.videogame_asset_rounded),
                  label: 'Ab-Play',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mic_none_rounded),
                  activeIcon: Icon(Icons.mic_rounded),
                  label: 'Voice Room',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore_rounded),
                  label: 'Discover',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Me',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
