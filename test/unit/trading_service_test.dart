import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/app_constants.dart';
import 'package:trading_app/models/order.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/portfolio_providers.dart';
import 'package:trading_app/state/storage_providers.dart';

void main() {
  group('TradingService & Portfolio Execution', () {
    late InMemoryStorageService storage;
    late ProviderContainer container;
    late TradingService tradingService;

    setUp(() {
      storage = InMemoryStorageService();
      container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
      );
      tradingService = container.read(tradingServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with default starting wallet balance', () {
      final balance = container.read(walletProvider);
      expect(balance, AppConstants.defaultWalletBalancePaise); // ₹5,00,000
    });

    test(
      'executes successful BUY order, updates wallet and creates holding',
      () async {
        final initialBalance = container.read(walletProvider);
        const symbol = 'RELIANCE';
        const quantity = 10;
        const sampledPricePaise = 300000; // ₹3,000.00
        const expectedTotalValuePaise = 3000000; // ₹30,000.00

        final result = await tradingService.executeMarketOrder(
          symbol: symbol,
          side: OrderSide.buy,
          quantity: quantity,
          sampledPricePaise: sampledPricePaise,
        );

        expect(result.isSuccess, isTrue);
        expect(result.order, isNotNull);
        expect(result.order!.symbol, symbol);
        expect(result.order!.side, OrderSide.buy);
        expect(result.order!.quantity, quantity);
        expect(result.order!.pricePaise, sampledPricePaise);
        expect(result.order!.totalValuePaise, expectedTotalValuePaise);

        // Verify wallet deduction
        final newBalance = container.read(walletProvider);
        expect(newBalance, initialBalance - expectedTotalValuePaise);
        expect(storage.loadWalletBalance(), newBalance);

        // Verify holding creation
        final holdings = container.read(holdingsProvider);
        expect(holdings.length, 1);
        expect(holdings.first.symbol, symbol);
        expect(holdings.first.quantity, quantity);
        expect(holdings.first.totalCostPaise, expectedTotalValuePaise);
        expect(holdings.first.avgCostPaise, sampledPricePaise);

        // Verify order recorded
        final orders = container.read(ordersProvider);
        expect(orders.length, 1);
        expect(orders.first.id, result.order!.id);
      },
    );

    test(
      'updates existing holding with weighted average cost when buying more shares',
      () async {
        // First buy: 10 shares @ ₹2,000 (200,000 paise) = total cost ₹20,000 (2,000,000 paise)
        await tradingService.executeMarketOrder(
          symbol: 'TCS',
          side: OrderSide.buy,
          quantity: 10,
          sampledPricePaise: 200000,
        );

        // Second buy: 10 shares @ ₹4,000 (400,000 paise) = total cost ₹40,000 (4,000,000 paise)
        await tradingService.executeMarketOrder(
          symbol: 'TCS',
          side: OrderSide.buy,
          quantity: 10,
          sampledPricePaise: 400000,
        );

        // Total: 20 shares, total cost = ₹60,000 (6,000,000 paise) -> weighted avg = ₹3,000 (300,000 paise)
        final holding = container.read(holdingForSymbolProvider('TCS'))!;
        expect(holding.quantity, 20);
        expect(holding.totalCostPaise, 6000000);
        expect(holding.avgCostPaise, 300000); // exactly ₹3,000
      },
    );

    test(
      'blocks BUY when order value exceeds available wallet balance without touching state',
      () async {
        // Set wallet balance to ₹1,000 (100,000 paise)
        await container.read(walletProvider.notifier).setBalance(100000);

        // Try buying order worth ₹2,000 (200,000 paise)
        final result = await tradingService.executeMarketOrder(
          symbol: 'INFY',
          side: OrderSide.buy,
          quantity: 2,
          sampledPricePaise: 100000,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Insufficient margin'));

        // Verify state was completely unmodified
        expect(container.read(walletProvider), 100000);
        expect(container.read(holdingsProvider), isEmpty);
        expect(container.read(ordersProvider), isEmpty);
      },
    );

    test('blocks orders with non-positive or zero quantities', () async {
      final zeroResult = await tradingService.executeMarketOrder(
        symbol: 'INFY',
        side: OrderSide.buy,
        quantity: 0,
        sampledPricePaise: 150000,
      );
      expect(zeroResult.isSuccess, isFalse);
      expect(zeroResult.errorMessage, contains('greater than zero'));

      final negResult = await tradingService.executeMarketOrder(
        symbol: 'INFY',
        side: OrderSide.buy,
        quantity: -5,
        sampledPricePaise: 150000,
      );
      expect(negResult.isSuccess, isFalse);
    });

    test(
      'executes partial SELL order, reduces holdings and credits proceeds to wallet',
      () async {
        // Buy 10 shares @ ₹1,000 (100,000 paise)
        await tradingService.executeMarketOrder(
          symbol: 'SBIN',
          side: OrderSide.buy,
          quantity: 10,
          sampledPricePaise: 100000,
        );

        final balanceBeforeSell = container.read(walletProvider);

        // Sell 4 shares @ ₹1,200 (120,000 paise) = ₹4,800 (480,000 paise) proceeds
        final sellResult = await tradingService.executeMarketOrder(
          symbol: 'SBIN',
          side: OrderSide.sell,
          quantity: 4,
          sampledPricePaise: 120000,
        );

        expect(sellResult.isSuccess, isTrue);

        // Wallet credited with proceeds
        expect(container.read(walletProvider), balanceBeforeSell + 480000);

        // Holding reduced to 6 shares
        final holding = container.read(holdingForSymbolProvider('SBIN'))!;
        expect(holding.quantity, 6);
        expect(holding.totalCostPaise, 600000); // 6 * 100,000 avg cost
      },
    );

    test('removes holding completely when full quantity is sold', () async {
      await tradingService.executeMarketOrder(
        symbol: 'ITC',
        side: OrderSide.buy,
        quantity: 5,
        sampledPricePaise: 40000,
      );

      expect(container.read(holdingForSymbolProvider('ITC')), isNotNull);

      // Sell all 5 shares
      final sellResult = await tradingService.executeMarketOrder(
        symbol: 'ITC',
        side: OrderSide.sell,
        quantity: 5,
        sampledPricePaise: 42000,
      );

      expect(sellResult.isSuccess, isTrue);
      expect(container.read(holdingForSymbolProvider('ITC')), isNull);
      expect(container.read(holdingsProvider), isEmpty);
    });

    test('blocks SELL when attempting to oversell held quantity', () async {
      // Buy 5 shares
      await tradingService.executeMarketOrder(
        symbol: 'LT',
        side: OrderSide.buy,
        quantity: 5,
        sampledPricePaise: 350000,
      );

      final balanceBeforeOversell = container.read(walletProvider);

      // Attempt to sell 6 shares
      final result = await tradingService.executeMarketOrder(
        symbol: 'LT',
        side: OrderSide.sell,
        quantity: 6,
        sampledPricePaise: 350000,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Insufficient shares held'));

      // State remains unchanged
      expect(container.read(walletProvider), balanceBeforeOversell);
      expect(container.read(holdingForSymbolProvider('LT'))!.quantity, 5);
    });

    test(
      'guarantees decimal precision without IEEE-754 floating point drift',
      () {
        // Simulating 3 shares of a stock at ₹100.10 (10010 paise)
        const qty = 3;
        const pricePaise = 10010;
        const totalPaise = qty * pricePaise;

        expect(
          totalPaise,
          30030,
        ); // ₹300.30 exactly, without 300.30000000000007 drift
        expect(totalPaise % 100, 30);
      },
    );

    test(
      'persists wallet balance, holdings, and order history across container restarts',
      () async {
        await tradingService.executeMarketOrder(
          symbol: 'AXISBANK',
          side: OrderSide.buy,
          quantity: 8,
          sampledPricePaise: 110000,
        );

        final savedBalance = storage.loadWalletBalance();
        final savedHoldings = storage.loadHoldings();
        final savedOrders = storage.loadOrders();

        expect(savedBalance, isNotNull);
        expect(savedHoldings?.length, 1);
        expect(savedOrders?.length, 1);

        // Simulate app restart by instantiating new container from storage
        final newContainer = ProviderContainer(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
        );

        expect(newContainer.read(walletProvider), savedBalance);
        expect(newContainer.read(holdingsProvider).first.symbol, 'AXISBANK');
        expect(newContainer.read(ordersProvider).first.symbol, 'AXISBANK');

        newContainer.dispose();
      },
    );
  });
}
