import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';
import 'home_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../transactions/transaction_history_screen.dart';
import '../profile/profile_menu_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      const NotificationCenterScreen(),
      const TransactionHistoryScreen(),
      const ProfileMenuScreen(),
    ];
  }

  void _onTap(int i) {
    // reload home data whenever switching back to home tab
    if (i == 0 && _i != 0) {
      _homeKey.currentState?.reloadUser();
    }
    setState(() => _i = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _screens),
      bottomNavigationBar: MgBottomNav(currentIndex: _i, onTap: _onTap),
    );
  }
}
