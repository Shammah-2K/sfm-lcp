import 'package:flutter/material.dart';

import 'stock_screen.dart';
import 'today_screen.dart';
import 'totals_screen.dart';

/// Three flat destinations: Today, Totals, Stock (brief section 7.1).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.participantCode});

  final String participantCode;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          TodayScreen(participantCode: widget.participantCode),
          TotalsScreen(participantCode: widget.participantCode),
          StockScreen(participantCode: widget.participantCode),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            key: Key('tab-today'),
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            key: Key('tab-totals'),
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Totals',
          ),
          NavigationDestination(
            key: Key('tab-stock'),
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
        ],
      ),
    );
  }
}
