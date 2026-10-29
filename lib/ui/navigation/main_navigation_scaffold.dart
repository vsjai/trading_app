import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/theme_provider.dart';
import '../holdings/holdings_screen.dart';
import '../market/market_overview_screen.dart';
import '../settings/settings_screen.dart';
import '../watchlist/watchlists_screen.dart';

class MainNavigationScaffold extends ConsumerStatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  ConsumerState<MainNavigationScaffold> createState() =>
      _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState
    extends ConsumerState<MainNavigationScaffold> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const MarketOverviewScreen(),
    const WatchlistsScreen(),
    HoldingsScreen(onExploreTap: () => setState(() => _currentIndex = 0)),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppTheme.darkBorder.withValues(alpha: 0.7)
                  : AppTheme.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          key: ValueKey('navbar_${themeMode.name}'),
          selectedIndex: _currentIndex,
          backgroundColor: isDark
              ? AppTheme.darkSurface
              : AppTheme.lightSurface,
          indicatorColor: isDark
              ? AppTheme.primary.withValues(alpha: 0.22)
              : AppTheme.primary.withValues(alpha: 0.12),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.candlestick_chart_outlined,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              selectedIcon: Icon(
                Icons.candlestick_chart,
                color: isDark ? AppTheme.primaryLight : AppTheme.primary,
              ),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.bookmark_border_rounded,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              selectedIcon: Icon(
                Icons.bookmark_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primary,
              ),
              label: 'Watchlist',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.pie_chart_outline_rounded,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              selectedIcon: Icon(
                Icons.pie_chart_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primary,
              ),
              label: 'Holdings',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.settings_outlined,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              selectedIcon: Icon(
                Icons.settings_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primary,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
