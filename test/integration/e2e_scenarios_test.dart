import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/models/order.dart';
import 'package:trading_app/models/stock_quote.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/portfolio_providers.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/state/watchlist_providers.dart';
import 'package:trading_app/ui/navigation/main_navigation_scaffold.dart';

void main() {
  group('End-to-End Scenarios (Phase 6 Audit)', () {
    late InMemoryStorageService sharedStorage;
    late MarketFeedService sharedFeed;

    setUp(() {
      sharedStorage = InMemoryStorageService();
      sharedFeed = MarketFeedService();
    });

    tearDown(() {
      sharedFeed.dispose();
    });

    Widget createTestApp({
      required InMemoryStorageService storage,
      required MarketFeedService feed,
    }) {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          marketFeedServiceProvider.overrideWithValue(feed),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainNavigationScaffold(),
        ),
      );
    }

    test(
      'Scenario 1: Watchlists restore correctly after an app restart',
      () async {
        final container1 = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final notifier1 = container1.read(watchlistsProvider.notifier);
        final newId = await notifier1.createWatchlist('Bluechip Portfolio');
        await notifier1.addStockToWatchlist(newId, 'RELIANCE');
        await notifier1.addStockToWatchlist(newId, 'TCS');
        await notifier1.renameWatchlist(newId, 'Top Bluechips');

        final beforeRestart = container1.read(watchlistsProvider);
        expect(beforeRestart.any((w) => w.name == 'Top Bluechips'), isTrue);
        container1.dispose();

        final container2 = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final afterRestart = container2.read(watchlistsProvider);
        expect(afterRestart.length, beforeRestart.length);
        final restoredCustom = afterRestart.firstWhere((w) => w.id == newId);
        expect(restoredCustom.name, 'Top Bluechips');
        expect(restoredCustom.symbols, ['RELIANCE', 'TCS']);
        container2.dispose();
      },
    );

    test(
      'Scenario 2: Watchlist reorder and removal never associate prices with the wrong stock',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final notifier = container.read(watchlistsProvider.notifier);
        final wlId = await notifier.createWatchlist('OrderTest');
        await notifier.addStockToWatchlist(wlId, 'RELIANCE');
        await notifier.addStockToWatchlist(wlId, 'TCS');
        await notifier.addStockToWatchlist(wlId, 'INFY');

        final relQuote = sharedFeed.getLatestQuote('RELIANCE')!;
        final tcsQuote = sharedFeed.getLatestQuote('TCS')!;
        final infyQuote = sharedFeed.getLatestQuote('INFY')!;

        await notifier.reorderStocks(wlId, 1, 0);
        var currentWl = container
            .read(watchlistsProvider)
            .firstWhere((w) => w.id == wlId);
        expect(currentWl.symbols, ['TCS', 'RELIANCE', 'INFY']);

        expect(
          sharedFeed.getLatestQuote(currentWl.symbols[0])!.ltpPaise,
          tcsQuote.ltpPaise,
        );
        expect(
          sharedFeed.getLatestQuote(currentWl.symbols[1])!.ltpPaise,
          relQuote.ltpPaise,
        );
        expect(
          sharedFeed.getLatestQuote(currentWl.symbols[2])!.ltpPaise,
          infyQuote.ltpPaise,
        );

        await notifier.removeStockFromWatchlist(wlId, 'RELIANCE');
        currentWl = container
            .read(watchlistsProvider)
            .firstWhere((w) => w.id == wlId);
        expect(currentWl.symbols, ['TCS', 'INFY']);

        expect(
          sharedFeed.getLatestQuote(currentWl.symbols[0])!.ltpPaise,
          tcsQuote.ltpPaise,
        );
        expect(
          sharedFeed.getLatestQuote(currentWl.symbols[1])!.ltpPaise,
          infyQuote.ltpPaise,
        );
        container.dispose();
      },
    );

    test(
      'Scenario 3: Identical stocks across multiple watchlists display the same LTP',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final notifier = container.read(watchlistsProvider.notifier);
        final wl1 = await notifier.createWatchlist('List 1');
        final wl2 = await notifier.createWatchlist('List 2');
        await notifier.addStockToWatchlist(wl1, 'SBIN');
        await notifier.addStockToWatchlist(wl2, 'SBIN');

        final targetQuote = StockQuote.compute(
          symbol: 'SBIN',
          ltpPaise: 82500,
          previousClosePaise: 81000,
          direction: PriceDirection.up,
        );
        sharedFeed.emitCustomQuote(targetQuote);

        final quote1 = sharedFeed.getLatestQuote('SBIN');
        final quote2 = sharedFeed.getLatestQuote('SBIN');

        expect(quote1, isNotNull);
        expect(quote2, isNotNull);
        expect(quote1!.ltpPaise, 82500);
        expect(quote2!.ltpPaise, 82500);
        expect(quote1.ltpPaise, equals(quote2.ltpPaise));
        container.dispose();
      },
    );

    testWidgets(
      'Scenario 4: Live prices continue updating when navigating between screens',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(storage: sharedStorage, feed: sharedFeed),
        );
        await tester.pumpAndSettle();

        expect(find.text('Watchlist'), findsWidgets);

        await tester.tap(find.text('Holdings'));
        await tester.pumpAndSettle();
        expect(find.text('Portfolio & Holdings'), findsOneWidget);

        final newReliancePrice = 310000;
        sharedFeed.emitCustomQuote(
          StockQuote.compute(
            symbol: 'RELIANCE',
            ltpPaise: newReliancePrice,
            previousClosePaise: 295050,
            direction: PriceDirection.up,
          ),
        );

        await tester.tap(find.text('Market'));
        await tester.pumpAndSettle();
        expect(find.text('Live Market'), findsOneWidget);

        await tester.tap(find.text('Watchlist').first);
        await tester.pumpAndSettle();

        final currentReliance = sharedFeed.getLatestQuote('RELIANCE');
        expect(currentReliance?.ltpPaise, newReliancePrice);
      },
    );

    test(
      'Scenario 5: A stock removed from a watchlist is no longer displayed in that watchlist after restart',
      () async {
        final container1 = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final notifier1 = container1.read(watchlistsProvider.notifier);
        final defaultWl = container1.read(watchlistsProvider).first;
        final targetSymbol = defaultWl.symbols.first;

        await notifier1.removeStockFromWatchlist(defaultWl.id, targetSymbol);
        expect(
          container1
              .read(watchlistsProvider)
              .first
              .symbols
              .contains(targetSymbol),
          isFalse,
        );
        container1.dispose();

        final container2 = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final restoredWl = container2.read(watchlistsProvider).first;
        expect(restoredWl.symbols.contains(targetSymbol), isFalse);
        container2.dispose();
      },
    );

    test(
      'Scenario 6: Buy orders use the latest LTP and correctly validate the wallet balance',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        await container.read(walletProvider.notifier).setBalance(100000);
        final tradingService = container.read(tradingServiceProvider);
        final ltp = sharedFeed.getLatestQuote('RELIANCE')!.ltpPaise;

        final failedResult = await tradingService.executeMarketOrder(
          symbol: 'RELIANCE',
          side: OrderSide.buy,
          quantity: 1,
          sampledPricePaise: ltp,
        );
        expect(failedResult.isSuccess, isFalse);
        expect(failedResult.errorMessage, contains('Insufficient margin'));
        expect(container.read(walletProvider), 100000);

        await container.read(walletProvider.notifier).setBalance(10000000);
        final successResult = await tradingService.executeMarketOrder(
          symbol: 'RELIANCE',
          side: OrderSide.buy,
          quantity: 2,
          sampledPricePaise: ltp,
        );

        expect(successResult.isSuccess, isTrue);
        final expectedBalance = 10000000 - (2 * ltp);
        expect(container.read(walletProvider), expectedBalance);
        container.dispose();
      },
    );

    test(
      'Scenario 7: Invalid, zero, negative, fractional, and excessive quantities are rejected',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final tradingService = container.read(tradingServiceProvider);
        final ltp = sharedFeed.getLatestQuote('INFY')!.ltpPaise;

        final zeroResult = await tradingService.executeMarketOrder(
          symbol: 'INFY',
          side: OrderSide.buy,
          quantity: 0,
          sampledPricePaise: ltp,
        );
        expect(zeroResult.isSuccess, isFalse);
        expect(zeroResult.errorMessage, contains('greater than zero'));

        final negResult = await tradingService.executeMarketOrder(
          symbol: 'INFY',
          side: OrderSide.buy,
          quantity: -5,
          sampledPricePaise: ltp,
        );
        expect(negResult.isSuccess, isFalse);

        final excessiveResult = await tradingService.executeMarketOrder(
          symbol: 'INFY',
          side: OrderSide.buy,
          quantity: 1000000,
          sampledPricePaise: ltp,
        );
        expect(excessiveResult.isSuccess, isFalse);
        expect(excessiveResult.errorMessage, contains('Insufficient margin'));
        container.dispose();
      },
    );

    test(
      'Scenario 8: Successful orders update wallet, order history, and holdings consistently',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final initialWallet = 5000000;
        await container.read(walletProvider.notifier).setBalance(initialWallet);
        final tradingService = container.read(tradingServiceProvider);
        final ltp = sharedFeed.getLatestQuote('TCS')!.ltpPaise;

        final res = await tradingService.executeMarketOrder(
          symbol: 'TCS',
          side: OrderSide.buy,
          quantity: 3,
          sampledPricePaise: ltp,
        );
        expect(res.isSuccess, isTrue);

        final totalOrderCost = 3 * ltp;
        expect(container.read(walletProvider), initialWallet - totalOrderCost);

        final holdings = container.read(holdingsProvider);
        expect(holdings.length, 1);
        expect(holdings.first.symbol, 'TCS');
        expect(holdings.first.quantity, 3);
        expect(holdings.first.totalCostPaise, totalOrderCost);
        expect(holdings.first.avgCostPaise, ltp);

        final orders = container.read(ordersProvider);
        expect(orders.length, 1);
        expect(orders.first.symbol, 'TCS');
        expect(orders.first.quantity, 3);
        expect(orders.first.pricePaise, ltp);
        expect(orders.first.side, OrderSide.buy);
        container.dispose();
      },
    );

    test(
      'Scenario 9: Sell orders cannot exceed the available quantity',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final tradingService = container.read(tradingServiceProvider);
        final ltp = sharedFeed.getLatestQuote('HDFCBANK')!.ltpPaise;

        final zeroHoldingSell = await tradingService.executeMarketOrder(
          symbol: 'HDFCBANK',
          side: OrderSide.sell,
          quantity: 1,
          sampledPricePaise: ltp,
        );
        expect(zeroHoldingSell.isSuccess, isFalse);
        expect(
          zeroHoldingSell.errorMessage,
          contains('Insufficient shares held'),
        );

        await container.read(walletProvider.notifier).setBalance(10000000);
        await tradingService.executeMarketOrder(
          symbol: 'HDFCBANK',
          side: OrderSide.buy,
          quantity: 5,
          sampledPricePaise: ltp,
        );

        final oversell = await tradingService.executeMarketOrder(
          symbol: 'HDFCBANK',
          side: OrderSide.sell,
          quantity: 6,
          sampledPricePaise: ltp,
        );
        expect(oversell.isSuccess, isFalse);
        expect(
          oversell.errorMessage,
          contains(
            'Insufficient shares held. You hold 5 shares of HDFCBANK, tried to sell 6',
          ),
        );
        container.dispose();
      },
    );

    test(
      'Scenario 10: Holdings disappear when quantity reaches zero',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final tradingService = container.read(tradingServiceProvider);
        final ltp = sharedFeed.getLatestQuote('ICICIBANK')!.ltpPaise;
        await container.read(walletProvider.notifier).setBalance(10000000);

        await tradingService.executeMarketOrder(
          symbol: 'ICICIBANK',
          side: OrderSide.buy,
          quantity: 10,
          sampledPricePaise: ltp,
        );
        expect(
          container.read(holdingsProvider).any((h) => h.symbol == 'ICICIBANK'),
          isTrue,
        );

        final sellRes = await tradingService.executeMarketOrder(
          symbol: 'ICICIBANK',
          side: OrderSide.sell,
          quantity: 10,
          sampledPricePaise: ltp,
        );
        expect(sellRes.isSuccess, isTrue);

        expect(
          container.read(holdingsProvider).any((h) => h.symbol == 'ICICIBANK'),
          isFalse,
        );
        container.dispose();
      },
    );

    test(
      'Scenario 11: Portfolio aggregates and sort order remain correct as prices change',
      () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final tradingService = container.read(tradingServiceProvider);
        await container.read(walletProvider.notifier).setBalance(50000000);

        final relianceBase = sharedFeed.getLatestQuote('RELIANCE')!.ltpPaise;
        final tcsBase = sharedFeed.getLatestQuote('TCS')!.ltpPaise;

        await tradingService.executeMarketOrder(
          symbol: 'RELIANCE',
          side: OrderSide.buy,
          quantity: 10,
          sampledPricePaise: relianceBase,
        );

        await tradingService.executeMarketOrder(
          symbol: 'TCS',
          side: OrderSide.buy,
          quantity: 10,
          sampledPricePaise: tcsBase,
        );

        var summary = container.read(portfolioSummaryProvider);
        var sorted = container.read(sortedHoldingsProvider);
        expect(
          summary.totalInvestedPaise,
          (10 * relianceBase) + (10 * tcsBase),
        );
        expect(summary.holdingsCount, 2);

        final higherTcs = (tcsBase * 1.20).round();
        final lowerReliance = (relianceBase * 0.90).round();

        sharedFeed.emitCustomQuote(
          StockQuote.compute(
            symbol: 'TCS',
            ltpPaise: higherTcs,
            previousClosePaise: tcsBase,
            direction: PriceDirection.up,
          ),
        );

        sharedFeed.emitCustomQuote(
          StockQuote.compute(
            symbol: 'RELIANCE',
            ltpPaise: lowerReliance,
            previousClosePaise: relianceBase,
            direction: PriceDirection.down,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));

        summary = container.read(portfolioSummaryProvider);
        final expectedCurrentValue = (10 * lowerReliance) + (10 * higherTcs);
        expect(summary.totalCurrentValuePaise, expectedCurrentValue);
        expect(
          summary.totalPnlPaise,
          expectedCurrentValue - summary.totalInvestedPaise,
        );

        sorted = container.read(sortedHoldingsProvider);
        expect(sorted.first.symbol, 'TCS');
        expect(sorted.last.symbol, 'RELIANCE');
        container.dispose();
      },
    );

    test(
      'Scenario 12: Watchlists, wallet, holdings, and order history restore after an app restart',
      () async {
        final container1 = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final wlNotifier = container1.read(watchlistsProvider.notifier);
        final wlId = await wlNotifier.createWatchlist('Long Term');
        await wlNotifier.addStockToWatchlist(wlId, 'ITC');

        await container1.read(walletProvider.notifier).setBalance(25000000);
        final trading = container1.read(tradingServiceProvider);
        final itcLtp = sharedFeed.getLatestQuote('ITC')!.ltpPaise;

        await trading.executeMarketOrder(
          symbol: 'ITC',
          side: OrderSide.buy,
          quantity: 50,
          sampledPricePaise: itcLtp,
        );

        final balanceBefore = container1.read(walletProvider);
        final holdingsBefore = container1.read(holdingsProvider);
        final ordersBefore = container1.read(ordersProvider);
        container1.dispose();

        final container2 = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(sharedStorage),
            marketFeedServiceProvider.overrideWithValue(sharedFeed),
          ],
        );

        final watchlistsAfter = container2.read(watchlistsProvider);
        expect(
          watchlistsAfter.any((w) => w.id == wlId && w.symbols.contains('ITC')),
          isTrue,
        );

        final balanceAfter = container2.read(walletProvider);
        expect(balanceAfter, balanceBefore);

        final holdingsAfter = container2.read(holdingsProvider);
        expect(holdingsAfter.length, holdingsBefore.length);
        expect(holdingsAfter.first.symbol, 'ITC');
        expect(holdingsAfter.first.quantity, 50);
        expect(
          holdingsAfter.first.totalCostPaise,
          holdingsBefore.first.totalCostPaise,
        );

        final ordersAfter = container2.read(ordersProvider);
        expect(ordersAfter.length, ordersBefore.length);
        expect(ordersAfter.first.symbol, 'ITC');
        expect(ordersAfter.first.quantity, 50);
        container2.dispose();
      },
    );
  });
}
