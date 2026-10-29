import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../market/market_overview_screen.dart';
import '../watchlist/watchlists_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WatchlistsScreen(),
    MarketOverviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.border.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.bookmark_border_rounded),
              selectedIcon: Icon(
                Icons.bookmark_rounded,
                color: AppTheme.primaryLight,
              ),
              label: 'Watchlist',
            ),
            NavigationDestination(
              icon: Icon(Icons.candlestick_chart_outlined),
              selectedIcon: Icon(
                Icons.candlestick_chart,
                color: AppTheme.primaryLight,
              ),
              label: 'Market',
            ),
          ],
        ),
      ),
    );
  }
}
