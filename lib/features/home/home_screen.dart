import 'package:flutter/material.dart';
import 'package:vaultsafe/features/passwords/passwords_screen.dart';
import 'package:vaultsafe/features/settings/settings_screen.dart';
import 'package:vaultsafe/features/profile/profile_screen.dart';

/// 主界面 - 底部导航
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PasswordsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.password_rounded),
            label: '密码',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: '我的',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
