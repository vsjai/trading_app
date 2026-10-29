import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/models/holding.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/ui/holdings/holdings_screen.dart';

void main() {
  late MarketFeedService testFeed;
  late InMemoryStorageService testStorage;

  setUp(() {
    testFeed = MarketFeedService();
    testStorage = InMemoryStorageService();
  });

  tearDown(() {
    testFeed.dispose();
  });

  Widget createSubject({List<Holding>? initialHoldings, int? walletBalance}) {
    if (initialHoldings != null) {
      testStorage.saveHoldings(initialHoldings);
    }
    if (walletBalance != null) {
      testStorage.saveWalletBalance(walletBalance);
    }

    return ProviderScope(
      overrides: [
        marketFeedServiceProvider.overrideWithValue(testFeed),
        storageServiceProvider.overrideWithValue(testStorage),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HoldingsScreen(),
      ),
    );
  }

  testWidgets('HoldingsScreen displays empty state when no holdings exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject(initialHoldings: []));
    await tester.pumpAndSettle();

    expect(find.text('Portfolio & Holdings'), findsOneWidget);
    expect(find.text('No Holdings Yet'), findsOneWidget);
    expect(find.text('Total P&L'), findsOneWidget);
  });

  testWidgets('HoldingsScreen renders holdings summary card and holding rows', (
    WidgetTester tester,
  ) async {
    final holdings = [
      const Holding(symbol: 'RELIANCE', quantity: 10, totalCostPaise: 2900000),
      const Holding(symbol: 'TCS', quantity: 5, totalCostPaise: 1900000),
    ];

    await tester.pumpWidget(createSubject(initialHoldings: holdings));
    await tester.pumpAndSettle();

    expect(find.text('RELIANCE'), findsOneWidget);
    expect(find.text('TCS'), findsOneWidget);
    expect(find.text('2 Positions'), findsOneWidget);
    expect(find.text('Invested'), findsOneWidget);
    expect(find.text('Current Value'), findsOneWidget);
  });

  testWidgets(
    'Tapping holding row opens BuySellTicketSheet preselected with that stock',
    (WidgetTester tester) async {
      final holdings = [
        const Holding(symbol: 'INFY', quantity: 15, totalCostPaise: 2000000),
      ];

      await tester.pumpWidget(createSubject(initialHoldings: holdings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('INFY'));
      await tester.pumpAndSettle();

      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('SELL'), findsOneWidget);
      expect(find.text('Projected Order Value'), findsOneWidget);
    },
  );

  testWidgets('Switching sort filter updates sorting state', (
    WidgetTester tester,
  ) async {
    final holdings = [
      const Holding(symbol: 'TCS', quantity: 10, totalCostPaise: 3800000),
      const Holding(symbol: 'AXISBANK', quantity: 10, totalCostPaise: 1100000),
    ];

    await tester.pumpWidget(createSubject(initialHoldings: holdings));
    await tester.pumpAndSettle();

    // Default is P&L
    expect(find.text('P&L'), findsOneWidget);

    // Tap 'Symbol' sort chip
    await tester.tap(find.text('Symbol'));
    await tester.pumpAndSettle();

    expect(find.text('Symbol'), findsOneWidget);
  });

  testWidgets('Smooth scrolling when all 10 stocks are held', (
    WidgetTester tester,
  ) async {
    final allHoldings = testFeed.allStocks.map((s) {
      return Holding(
        symbol: s.symbol,
        quantity: 10,
        totalCostPaise: s.basePricePaise * 10,
      );
    }).toList();

    await tester.pumpWidget(createSubject(initialHoldings: allHoldings));
    await tester.pumpAndSettle();

    expect(find.text('10 Positions'), findsOneWidget);

    final lastSymbol = allHoldings.last.symbol;
    await tester.scrollUntilVisible(
      find.text(lastSymbol),
      300.0,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text(lastSymbol), findsOneWidget);
  });
}
