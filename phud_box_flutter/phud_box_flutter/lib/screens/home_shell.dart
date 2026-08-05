import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'control_screen.dart';
import 'logs_screen.dart';
import 'overview_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['OVERVIEW', 'DATA LOGS', 'CONTROL'];
  static const _screens = [OverviewScreen(), LogsScreen(), ControlScreen()];

  @override
  Widget build(BuildContext context) {
    final connected = context.watch<AppState>().isConnected;

    return Scaffold(
      backgroundColor: AppColors.navyBg,
      appBar: AppBar(
        backgroundColor: AppColors.navyBg,
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Row(
          children: [
            Row(
              children: [
                Icon(
                  connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  connected ? 'Connected' : 'Disconnected',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _titles[_index],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1930),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                children: [
                  Text('PHUD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  Text('BOX', style: TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
