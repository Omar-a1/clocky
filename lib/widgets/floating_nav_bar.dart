import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoogleClockNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GoogleClockNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.navBarBackground,
        border: Border(
          top: BorderSide(
            color: Color(0xFF1E2D28),
            width: 0.5,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        indicatorColor: AppTheme.navBarIndicator,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), // Pilled / rounded background
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.hourglass_empty_rounded),
            selectedIcon: Icon(Icons.hourglass_bottom_rounded),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
