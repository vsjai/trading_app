import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/models/holding.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/portfolio_providers.dart';
import 'package:trading_app/state/storage_providers.dart';

void main() {
  group('Portfolio Holdings & Aggregations', () {
    late InMemoryStorageService storage;
    late MarketFeedService feed;
    late ProviderContainer container;

    setUp(() {
      storage = InMemoryStorageService();
      feed = MarketFeedService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          marketFeedServiceProvider.overrideWithValue(feed),
        ],
      );
    });

    tearDown(() {
      feed.dispose();
      container.dispose();
    });

    test(
      'calculates aggregate total invested, current value, and P&L matching row sum',
      () {
        final holdings = [
          const Holding(
            symbol: 'RELIANCE',
            quantity: 10,
            totalCostPaise: 2900000,
          ), // avg 290,000
          const Holding(
            symbol: 'TCS',
            quantity: 5,
            totalCostPaise: 1900000,
          ), // avg 380,000
        ];

        container.read(holdingsProvider.notifier).setHoldings(holdings);

        final summary = container.read(portfolioSummaryProvider);

        final relLtp = feed.getLatestQuote('RELIANCE')!.ltpPaise;
        final tcsLtp = feed.getLatestQuote('TCS')!.ltpPaise;

        final expectedInvested = 2900000 + 1900000;
        final expectedCurrent = (10 * relLtp) + (5 * tcsLtp);
        final expectedPnl = expectedCurrent - expectedInvested;
        final expectedPnlPercent = (expectedPnl / expectedInvested) * 100.0;

        expect(summary.totalInvestedPaise, expectedInvested);
        expect(summary.totalCurrentValuePaise, expectedCurrent);
        expect(summary.totalPnlPaise, expectedPnl);
        expect(summary.totalPnlPercent, closeTo(expectedPnlPercent, 0.001));
        expect(summary.holdingsCount, 2);
      },
    );

    test('defaults to P&L descending sort criteria', () {
      expect(
        container.read(holdingsSortCriteriaProvider),
        HoldingsSortCriteria.pnl,
      );
      expect(container.read(holdingsSortAscendingProvider), isFalse);
    });

    test('sorts holdings by P&L descending correctly', () {
      // RELIANCE base is 295050; setting cost to 200,000 gives huge profit (+95050 per share)
      // TCS base is 384500; setting cost to 390,000 gives loss (-5500 per share)
      // INFY base is 152025; setting cost to 150,000 gives small profit (+2025 per share)
      final holdings = [
        const Holding(
          symbol: 'TCS',
          quantity: 10,
          totalCostPaise: 3900000,
        ), // Loss
        const Holding(
          symbol: 'RELIANCE',
          quantity: 10,
          totalCostPaise: 2000000,
        ), // Big profit
        const Holding(
          symbol: 'INFY',
          quantity: 10,
          totalCostPaise: 1500000,
        ), // Small profit
      ];

      container.read(holdingsProvider.notifier).setHoldings(holdings);

      final sorted = container.read(sortedHoldingsProvider);

      expect(sorted.length, 3);
      expect(sorted[0].symbol, 'RELIANCE'); // Highest profit
      expect(sorted[1].symbol, 'INFY'); // Moderate profit
      expect(sorted[2].symbol, 'TCS'); // Loss
    });

    test('sorts holdings by symbol alphabetically', () {
      final holdings = [
        const Holding(symbol: 'TCS', quantity: 10, totalCostPaise: 3000000),
        const Holding(
          symbol: 'AXISBANK',
          quantity: 10,
          totalCostPaise: 1000000,
        ),
        const Holding(symbol: 'INFY', quantity: 10, totalCostPaise: 1500000),
      ];

      container.read(holdingsProvider.notifier).setHoldings(holdings);
      container.read(holdingsSortCriteriaProvider.notifier).state =
          HoldingsSortCriteria.symbol;
      container.read(holdingsSortAscendingProvider.notifier).state = true;

      final sorted = container.read(sortedHoldingsProvider);
      expect(sorted[0].symbol, 'AXISBANK');
      expect(sorted[1].symbol, 'INFY');
      expect(sorted[2].symbol, 'TCS');
    });

    test('sorts holdings by Current Value descending', () {
      // 100 shares of ITC @ ~435 = ~43,500
      // 1 share of RELIANCE @ ~2950 = ~2,950
      // 50 shares of SBIN @ ~785 = ~39,250
      final holdings = [
        const Holding(symbol: 'RELIANCE', quantity: 1, totalCostPaise: 290000),
        const Holding(symbol: 'ITC', quantity: 100, totalCostPaise: 4300000),
        const Holding(symbol: 'SBIN', quantity: 50, totalCostPaise: 3900000),
      ];

      container.read(holdingsProvider.notifier).setHoldings(holdings);
      container.read(holdingsSortCriteriaProvider.notifier).state =
          HoldingsSortCriteria.currentValue;
      container.read(holdingsSortAscendingProvider.notifier).state = false;

      final sorted = container.read(sortedHoldingsProvider);
      expect(sorted[0].symbol, 'ITC'); // Highest market value
      expect(sorted[1].symbol, 'SBIN'); // Second highest
      expect(sorted[2].symbol, 'RELIANCE'); // Lowest
    });

    test(
      'partial sell reduces holding quantity and preserves proportional cost',
      () {
        const initial = Holding(
          symbol: 'HDFCBANK',
          quantity: 20,
          totalCostPaise: 3000000,
        ); // avg 150,000

        final partial = initial.applySell(sellQty: 5);
        expect(partial, isNotNull);
        expect(partial!.quantity, 15);
        expect(partial.totalCostPaise, 2250000); // 15 * 150,000
        expect(partial.avgCostPaise, 150000); // unchanged avg cost per share
      },
    );

    test('selling 100% quantity liquidates and removes holding', () {
      const initial = Holding(
        symbol: 'ICICIBANK',
        quantity: 8,
        totalCostPaise: 800000,
      );

      final liquidated = initial.applySell(sellQty: 8);
      expect(liquidated, isNull);
    });
  });
}
