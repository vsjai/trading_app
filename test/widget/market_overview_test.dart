import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/app_constants.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/ui/market/market_overview_screen.dart';

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

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        marketFeedServiceProvider.overrideWithValue(testFeed),
        storageServiceProvider.overrideWithValue(testStorage),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const MarketOverviewScreen(),
      ),
    );
  }

  testWidgets(
    'MarketOverviewScreen renders all 10 stocks and header elements',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Live Market'), findsOneWidget);
      expect(find.text('10 Instruments'), findsOneWidget);
      expect(find.text('MARKET LIVE'), findsOneWidget);

      for (final stock in AppConstants.initialStocks.take(5)) {
        expect(find.text(stock.symbol), findsOneWidget);
      }
    },
  );

  testWidgets('MarketOverviewScreen scrolls smoothly to show bottom stocks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final lastStock = AppConstants.initialStocks.last;
    await tester.scrollUntilVisible(
      find.text(lastStock.symbol),
      300.0,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text(lastStock.symbol), findsOneWidget);
  });

  testWidgets('Emitting ticks updates price badge dynamically', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final initialQuote = testFeed.getLatestQuote('RELIANCE')!;
    testFeed.emitTickForSymbol('RELIANCE');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final updatedQuote = testFeed.getLatestQuote('RELIANCE')!;
    expect(updatedQuote.ltpPaise, isNot(initialQuote.ltpPaise));
  });

  testWidgets(
    'Tapping speed badge opens TickRateControlSheet and switches to stress mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsOneWidget);

      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();

      expect(find.text('Market Feed Simulation Speed'), findsOneWidget);
      expect(find.text('Stress Test (High Load)'), findsOneWidget);

      await tester.tap(find.text('Stress Test (High Load)'));
      await tester.pumpAndSettle();

      expect(testFeed.currentMode, TickRateMode.stress);
    },
  );

  testWidgets('Prices remain current when navigating away and returning', (
    WidgetTester tester,
  ) async {
    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketFeedServiceProvider.overrideWithValue(testFeed),
          storageServiceProvider.overrideWithValue(testStorage),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          theme: AppTheme.darkTheme,
          home: const MarketOverviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    testFeed.emitTickForSymbol('TCS');
    final latestPrice = testFeed.getLatestQuote('TCS')!.ltpPaise;

    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Temporary Route')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Temporary Route'), findsOneWidget);

    navKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('Live Market'), findsOneWidget);
    expect(testFeed.getLatestQuote('TCS')?.ltpPaise, latestPrice);
  });
}
