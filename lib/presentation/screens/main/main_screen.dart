import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/heart_loader.dart';
import '../swipe/home_swipe_screen.dart';
import '../matches/matches_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';

/// MainScreen - Bottom navigation container for main app screens
/// Holds Home, Matches, Messages, and Profile tabs
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeSwipeScreen(),
    MatchesScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    
    // Show loading screen while profile is loading
    if (userProfile.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: HeartLoader(
            text: 'Loading your profile...',
            size: 96,
          ),
        ),
      );
    }
    
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 24,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // Dark gray background
          borderRadius: BorderRadius.circular(40), // More circular/rounded
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.cupidPink 
              : Colors.transparent,
          shape: BoxShape.circle, // Fully circular background
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? Colors.white : Colors.grey[400],
          size: 26,
        ),
      ),
    );
  }
}
