import 'package:flutter/material.dart';
import 'lobby_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon:         Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label:        'Lobby',
    ),
    NavigationDestination(
      icon:         Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart_rounded),
      label:        'Stats',
    ),
    NavigationDestination(
      icon:         Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label:        'Settings',
    ),
  ];

  // IndexedStack keeps each tab alive when switching — scroll positions and
  // loaded data are preserved.
  static const _screens = [
    LobbyScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex:    _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor:  Colors.white,
        indicatorColor:   const Color(0xFF1B2B4B).withOpacity(0.10),
        labelBehavior:    NavigationDestinationLabelBehavior.alwaysShow,
        destinations:     _destinations,
      ),
    );
  }
}