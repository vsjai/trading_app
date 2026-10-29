import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/app_constants.dart';
import 'package:trading_app/models/holding.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/portfolio_providers.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/ui/settings/settings_screen.dart';

void main() {
  late InMemoryStorageService inMemoryStorage;

  setUp(() {
    inMemoryStorage = InMemoryStorageService();
  });

  Widget buildTestableSettings({
    ThemeMode initialTheme = ThemeMode.dark,
    int initialWallet = AppConstants.defaultWalletBalancePaise,
    List<Holding>? initialHoldings,
  }) {
    if (initialTheme == ThemeMode.light) {
      inMemoryStorage.saveThemeMode('light');
    }
    if (initialWallet != AppConstants.defaultWalletBalancePaise) {
      inMemoryStorage.saveWalletBalance(initialWallet);
    }
    if (initialHoldings != null) {
      inMemoryStorage.saveHoldings(initialHoldings);
    }

    return ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(inMemoryStorage)],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  testWidgets('SettingsScreen renders all sections and initial values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestableSettings());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('App Theme'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Light Mode'), findsOneWidget);

    expect(find.text('SIMULATED MARKET DATA'), findsOneWidget);
    expect(find.text('Mock Feed Tick Rate'), findsOneWidget);
    expect(find.textContaining('Normal'), findsOneWidget);
    expect(find.textContaining('Active (1.0'), findsOneWidget);
    expect(find.textContaining('Stress Mode'), findsOneWidget);

    expect(find.text('PAPER TRADING ACCOUNT'), findsOneWidget);
    expect(find.text('Available Cash Balance'), findsOneWidget);
    expect(find.text('Reset Balance to ₹5,00,000.00'), findsOneWidget);
    expect(find.text('Clear Positions & Holdings'), findsOneWidget);

    expect(find.text('APPLICATION & DATA'), findsOneWidget);
    expect(find.text('Active Watchlists'), findsOneWidget);
    expect(find.text('Open Positions'), findsOneWidget);
    expect(find.text('Orders Executed'), findsOneWidget);
    expect(find.text('Canonical Stocks'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
  });

  testWidgets('Tapping Light Mode switches theme mode and persists', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableSettings(initialTheme: ThemeMode.dark),
    );
    await tester.pumpAndSettle();

    final lightModeFinder = find.text('Light Mode');
    expect(lightModeFinder, findsOneWidget);

    await tester.tap(lightModeFinder);
    await tester.pumpAndSettle();

    final saved = inMemoryStorage.loadThemeMode();
    expect(saved, 'light');
  });

  testWidgets('Tapping Dark Mode switches theme mode and persists', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableSettings(initialTheme: ThemeMode.light),
    );
    await tester.pumpAndSettle();

    final darkModeFinder = find.text('Dark Mode');
    expect(darkModeFinder, findsOneWidget);

    await tester.tap(darkModeFinder);
    await tester.pumpAndSettle();

    final saved = inMemoryStorage.loadThemeMode();
    expect(saved, 'dark');
  });

  testWidgets('Changing Tick Rate selects active mode', (tester) async {
    await tester.pumpWidget(buildTestableSettings());
    await tester.pumpAndSettle();

    final activeTile = find.textContaining('Active (1.0 tick/s/stock)');
    expect(activeTile, findsOneWidget);

    await tester.tap(activeTile);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(container.read(tickRateModeProvider), TickRateMode.active);
  });

  testWidgets('Reset balance restores to 5 Lakhs and shows snackbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestableSettings(initialWallet: 25000000));
    await tester.pumpAndSettle();

    expect(find.text('₹2,50,000.00'), findsOneWidget);

    final resetBtn = find.text('Reset Balance to ₹5,00,000.00');
    expect(resetBtn, findsOneWidget);

    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    expect(find.text('₹5,00,000.00'), findsOneWidget);
    expect(
      find.text('Wallet balance reset to default ₹5,00,000.00'),
      findsOneWidget,
    );
  });

  testWidgets('Canceling Clear Positions & Holdings leaves holdings intact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const holding = Holding(
      symbol: 'RELIANCE',
      quantity: 10,
      totalCostPaise: 2950500,
    );
    await tester.pumpWidget(buildTestableSettings(initialHoldings: [holding]));
    await tester.pumpAndSettle();

    final clearBtn = find.text('Clear Positions & Holdings');
    expect(clearBtn, findsOneWidget);

    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(find.text('Clear Positions & Holdings?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(container.read(holdingsProvider).length, 1);
  });

  testWidgets(
    'Confirming Clear Positions & Holdings clears holdings and shows snackbar',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const holding = Holding(
        symbol: 'TCS',
        quantity: 5,
        totalCostPaise: 1922500,
      );
      await tester.pumpWidget(
        buildTestableSettings(initialHoldings: [holding]),
      );
      await tester.pumpAndSettle();

      final clearBtn = find.text('Clear Positions & Holdings');
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('Clear Positions & Holdings?'), findsOneWidget);
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(holdingsProvider), isEmpty);
      expect(
        find.text('All positions and holdings cleared successfully.'),
        findsOneWidget,
      );
    },
  );
}
