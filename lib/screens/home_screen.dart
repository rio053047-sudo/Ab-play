import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/game_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);

    // Banners vs Grid items
    final featuredBannerGames = homeVM.games.where((g) => g.id == 'spy' || g.id == 'paint_hide').toList();
    final gridGames = homeVM.games.where((g) => g.id != 'spy' && g.id != 'paint_hide').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, homeVM),
              const SizedBox(height: 16),
              _buildFeatureBanner(context),
              const SizedBox(height: 16),
              _buildShortcutsRow(context, homeVM),
              const SizedBox(height: 20),
              _buildRecentlyPlayedSection(context, homeVM),
              const SizedBox(height: 20),
              _buildGamesSectionHeader(context),
              const SizedBox(height: 12),

              // Render Full-Width Featured Banners for Who's the Spy & Paint to Hide
              ...featuredBannerGames.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFullWidthGameBanner(context, game),
              )),

              // Render Grid Cards for remaining games
              _buildGameCardsGrid(context, gridGames),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, HomeViewModel vm) {
    return Row(
      children: [
        // User Avatar with Level Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFFE1F5FE),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv.${vm.userLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),

        // User Name & ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      vm.username,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Color(0xFF29B6F6), size: 16),
                  if (vm.isVip) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                vm.userId,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),

        // Coin Counter Pill
        GestureDetector(
          onTap: () {
            vm.addCoins(100);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recharge +100 Ab-Play Coins!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB300), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${(vm.coinBalance / 1000).toStringAsFixed(1)}k',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF57F17),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB300),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Task / Calendar Button
        IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryText, size: 22),
          onPressed: () {},
        ),
        const SizedBox(width: 8),

        // Notification Bell
        IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryText, size: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFeatureBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF651FFF), Color(0xFF00B0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PARTY LOBBY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Play Party Games & Voice Chat with Friends!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Quick Match',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SvgPicture.asset(
            'assets/images/abplay_mascot.svg',
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsRow(BuildContext context, HomeViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: vm.shortcuts.map((shortcut) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: shortcut.badgeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(shortcut.icon, color: shortcut.iconColor, size: 24),
                    ),
                    if (shortcut.badgeText != null)
                      Positioned(
                        top: -4,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3D00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            shortcut.badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  shortcut.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentlyPlayedSection(BuildContext context, HomeViewModel vm) {
    final recentGames = vm.recentlyPlayedGames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recently Played',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentGames.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final game = recentGames[index];
              return Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _getGameIcon(game.id),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamesSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Party Games',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            children: [
              Text(
                'Game Room',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullWidthGameBanner(BuildContext context, GameItem game) {
    final isBlue = game.id == 'spy';
    final gradient = isBlue
        ? const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)])
        : const LinearGradient(colors: [Color(0xFFF57C00), Color(0xFFFFB74D)]);

    return Container(
      width: double.infinity,
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: (isBlue ? const Color(0xFF1976D2) : const Color(0xFFF57C00)).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        game.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      game.playerCount,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  game.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: _getGameIconLarge(game.id),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCardsGrid(BuildContext context, List<GameItem> games) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(context, game);
      },
    );
  }

  Widget _buildGameCard(BuildContext context, GameItem game) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual thumbnail header
          Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: _getCardGradient(game.id),
            ),
            child: Stack(
              children: [
                Center(child: _getGameIconLarge(game.id)),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      game.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  game.subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 12, color: AppColors.secondaryText),
                        const SizedBox(width: 3),
                        Text(
                          game.playerCount,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getCardGradient(String gameId) {
    switch (gameId) {
      case 'spy':
        return const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]);
      case 'paint_hide':
        return const LinearGradient(colors: [Color(0xFFF57C00), Color(0xFFFFB74D)]);
      case 'trickster':
        return const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFFE082)]);
      case 'hide_seek':
        return const LinearGradient(colors: [Color(0xFF43A047), Color(0xFFA5D6A7)]);
      case 'werewolf':
        return const LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF9FA8DA)]);
      case 'oh_my_card':
        return const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFFCDD2)]);
      case 'ludo':
        return const LinearGradient(colors: [Color(0xFFFB8C00), Color(0xFFFFCC80)]);
      default:
        return const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF90CAF9)]);
    }
  }

  Widget _getGameIcon(String gameId) {
    switch (gameId) {
      case 'spy':
        return const Icon(Icons.security, color: Color(0xFF1976D2), size: 26);
      case 'paint_hide':
        return const Icon(Icons.palette, color: Color(0xFFF57C00), size: 26);
      case 'trickster':
        return const Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 26);
      case 'hide_seek':
        return const Icon(Icons.visibility_off, color: Color(0xFF43A047), size: 26);
      case 'werewolf':
        return const Icon(Icons.brightness_3, color: Color(0xFF3949AB), size: 26);
      case 'oh_my_card':
        return const Icon(Icons.style, color: Color(0xFFE53935), size: 26);
      case 'ludo':
        return const Icon(Icons.casino, color: Color(0xFFFB8C00), size: 26);
      default:
        return const Icon(Icons.brush, color: Color(0xFF1E88E5), size: 26);
    }
  }

  Widget _getGameIconLarge(String gameId) {
    switch (gameId) {
      case 'spy':
        return const Icon(Icons.security, color: Colors.white, size: 40);
      case 'paint_hide':
        return const Icon(Icons.palette, color: Colors.white, size: 40);
      case 'trickster':
        return const Icon(Icons.auto_awesome, color: Colors.white, size: 40);
      case 'hide_seek':
        return const Icon(Icons.visibility_off, color: Colors.white, size: 40);
      case 'werewolf':
        return const Icon(Icons.brightness_3, color: Colors.white, size: 40);
      case 'oh_my_card':
        return const Icon(Icons.style, color: Colors.white, size: 40);
      case 'ludo':
        return const Icon(Icons.casino, color: Colors.white, size: 40);
      default:
        return const Icon(Icons.brush, color: Colors.white, size: 40);
    }
  }
}
