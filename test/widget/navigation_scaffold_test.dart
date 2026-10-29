import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/state/theme_provider.dart';
import 'package:trading_app/ui/navigation/main_navigation_scaffold.dart';

void main() {
  late InMemoryStorageService inMemoryStorage;

  setUp(() {
    inMemoryStorage = InMemoryStorageService();
  });

  Widget buildScaffold({ThemeMode initialTheme = ThemeMode.dark}) {
    if (initialTheme == ThemeMode.light) {
      inMemoryStorage.saveThemeMode('light');
    }
    return ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(inMemoryStorage)],
      child: Consumer(
        builder: (context, ref, child) {
          final mode = ref.watch(themeModeProvider);
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: const MainNavigationScaffold(),
          );
        },
      ),
    );
  }

  testWidgets('MainNavigationScaffold renders all 4 tabs in specified order', (
    tester,
  ) async {
    await tester.pumpWidget(buildScaffold());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Holdings'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Bottom navigation bar background updates when theme changes', (
    tester,
  ) async {
    await tester.pumpWidget(buildScaffold(initialTheme: ThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 100));

    final navBarDark = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBarDark.backgroundColor, AppTheme.darkSurface);

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));

    final lightOption = find.text('Light Mode');
    expect(lightOption, findsOneWidget);
    await tester.tap(lightOption);
    await tester.pump(const Duration(milliseconds: 300));

    final navBarLight = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navBarLight.backgroundColor, AppTheme.lightSurface);
  });
}
