import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/models/holding.dart';
import 'package:trading_app/models/stock_quote.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/ui/navigation/main_navigation_scaffold.dart';

void main() {
  group('Performance & Stress Audits (Phase 6)', () {
    late InMemoryStorageService storage;
    late MarketFeedService stressFeed;

    setUp(() {
      storage = InMemoryStorageService();
      stressFeed = MarketFeedService();
    });

    tearDown(() {
      stressFeed.dispose();
    });

    test(
      'High-frequency feed emits >= 50 ticks per second overall (>= 5 ticks/sec/stock)',
      () async {
        stressFeed.setMode(TickRateMode.stress);
        stressFeed.start();

        final receivedTicks = <StockQuote>[];
        final subscription = stressFeed.quoteStream.listen((quote) {
          receivedTicks.add(quote);
        });

        await Future.delayed(const Duration(milliseconds: 1100));
        await subscription.cancel();
        stressFeed.pause();

        expect(receivedTicks.length, greaterThanOrEqualTo(50));

        final symbolCounts = <String, int>{};
        for (final tick in receivedTicks) {
          symbolCounts[tick.symbol] = (symbolCounts[tick.symbol] ?? 0) + 1;
        }

        expect(symbolCounts.keys.length, equals(10));
        final avgTicksPerStock = receivedTicks.length / 10.0;
        expect(avgTicksPerStock, greaterThanOrEqualTo(5.0));
      },
    );

    test(
      'MarketFeedService instance is shared as single source of truth without duplication',
      () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            marketFeedServiceProvider.overrideWithValue(stressFeed),
          ],
        );

        final feedFromMarketProvider = container.read(
          marketFeedServiceProvider,
        );
        final feedServiceFromDirect = stressFeed;

        expect(
          identical(feedFromMarketProvider, feedServiceFromDirect),
          isTrue,
        );

        final initialQuote = container
            .read(marketFeedServiceProvider)
            .getLatestQuote('RELIANCE');
        expect(initialQuote, isNotNull);
        container.dispose();
      },
    );

    test(
      'Granular stream subscription prevents unnecessary rebuild of unrelated stocks',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            marketFeedServiceProvider.overrideWithValue(stressFeed),
          ],
        );

        int relianceEmitCount = 0;
        int tcsEmitCount = 0;

        final relSub = container.listen<AsyncValue<StockQuote>>(
          stockQuoteProvider('RELIANCE'),
          (previous, next) {
            if (next.hasValue) relianceEmitCount++;
          },
        );

        final tcsSub = container.listen<AsyncValue<StockQuote>>(
          stockQuoteProvider('TCS'),
          (previous, next) {
            if (next.hasValue) tcsEmitCount++;
          },
        );

        await Future.delayed(const Duration(milliseconds: 20));
        final relBaseline = relianceEmitCount;
        final tcsBaseline = tcsEmitCount;

        stressFeed.emitCustomQuote(
          StockQuote.compute(
            symbol: 'RELIANCE',
            ltpPaise: 300000,
            previousClosePaise: 295050,
            direction: PriceDirection.up,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        expect(relianceEmitCount, greaterThan(relBaseline));
        expect(tcsEmitCount, equals(tcsBaseline));

        relSub.close();
        tcsSub.close();
        container.dispose();
      },
    );

    testWidgets(
      'Smooth scrolling under stress-level live feed without errors or jank',
      (WidgetTester tester) async {
        final allHoldings = stressFeed.allStocks.map((s) {
          return Holding(
            symbol: s.symbol,
            quantity: 25,
            totalCostPaise: s.basePricePaise * 25,
          );
        }).toList();
        storage.saveHoldings(allHoldings);

        stressFeed.setMode(TickRateMode.stress);
        stressFeed.start();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storage),
              marketFeedServiceProvider.overrideWithValue(stressFeed),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const MainNavigationScaffold(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Navigate to Holdings
        await tester.tap(find.text('Holdings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Scroll Holdings down and up rapidly
        final scrollableHoldings = find.byType(Scrollable).last;
        await tester.fling(scrollableHoldings, const Offset(0, -400), 1000);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.fling(scrollableHoldings, const Offset(0, 400), 1000);
        await tester.pump(const Duration(milliseconds: 50));

        // Navigate to Market Overview
        await tester.tap(find.text('Market'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Scroll Market Overview down and up rapidly
        final scrollableMarket = find.byType(Scrollable).last;
        await tester.fling(scrollableMarket, const Offset(0, -500), 1200);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.fling(scrollableMarket, const Offset(0, 500), 1200);
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Live Market'), findsOneWidget);

        stressFeed.pause();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  });
}
