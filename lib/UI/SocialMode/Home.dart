import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kaia/UI/SocialMode/AccountScreen.dart';
import 'package:kaia/UI/SocialMode/DiscoverScreen.dart';
import 'package:kaia/UI/SocialMode/HomeScreen.dart';
import 'package:kaia/Service/NotificationService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialHome extends StatefulWidget {
  const SocialHome({super.key});

  @override
  State<SocialHome> createState() => _SocialHomeState();
}

class _SocialHomeState extends State<SocialHome> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final token = await NotificationService.requestNotificationPermission();
      if (token != null) {
        await NotificationService.saveDeviceToken(user.id, token);
      }
    }
  }

  List<Widget> get _screens => [
    HomeScreen(),
    DiscoverScreen(),
    Accountscreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Allows the body gradient to show under the floating nav bar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
        ),
        child: _screens[_selectedIndex], // Shows the active screen
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF1F2937)
            : Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.globe),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4A00E0) : Colors.white70,
              size: 26,
            ),

            // We use AnimatedSize or just an AnimatedOpacity/Padding if we want the text to appear smoothly.
            // Using a simple conditional here for simplicity, AnimatedContainer handles the bounding box well.
          ],
        ),
      ),
    );
  }
}
