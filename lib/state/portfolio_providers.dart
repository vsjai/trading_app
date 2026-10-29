import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/holding.dart';
import '../models/order.dart';
import '../services/storage_service.dart';
import 'storage_providers.dart';

class WalletNotifier extends StateNotifier<int> {
  final StorageService _storageService;

  WalletNotifier(this._storageService)
    : super(
        _storageService.loadWalletBalance() ??
            AppConstants.defaultWalletBalancePaise,
      );

  Future<void> setBalance(int balancePaise) async {
    state = balancePaise;
    await _storageService.saveWalletBalance(balancePaise);
  }

  Future<void> resetToDefault() async {
    await setBalance(AppConstants.defaultWalletBalancePaise);
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, int>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WalletNotifier(storage);
});

class HoldingsNotifier extends StateNotifier<List<Holding>> {
  final StorageService _storageService;

  HoldingsNotifier(this._storageService)
    : super(_storageService.loadHoldings() ?? []);

  Future<void> setHoldings(List<Holding> holdings) async {
    state = holdings;
    await _storageService.saveHoldings(holdings);
  }
}

final holdingsProvider = StateNotifierProvider<HoldingsNotifier, List<Holding>>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return HoldingsNotifier(storage);
  },
);

final holdingForSymbolProvider = Provider.family<Holding?, String>((
  ref,
  symbol,
) {
  final holdings = ref.watch(holdingsProvider);
  final index = holdings.indexWhere((h) => h.symbol == symbol);
  if (index == -1) return null;
  return holdings[index];
});

class OrdersNotifier extends StateNotifier<List<StockOrder>> {
  final StorageService _storageService;

  OrdersNotifier(this._storageService)
    : super(_storageService.loadOrders() ?? []);

  Future<void> recordOrder(StockOrder order) async {
    final updated = [order, ...state];
    state = updated;
    await _storageService.saveOrders(updated);
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<StockOrder>>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return OrdersNotifier(storage);
});

class OrderExecutionResult {
  final bool isSuccess;
  final StockOrder? order;
  final String? errorMessage;

  const OrderExecutionResult.success(this.order)
    : isSuccess = true,
      errorMessage = null;

  const OrderExecutionResult.failure(this.errorMessage)
    : isSuccess = false,
      order = null;
}

class TradingService {
  final Ref _ref;

  TradingService(this._ref);

  Future<OrderExecutionResult> executeMarketOrder({
    required String symbol,
    required OrderSide side,
    required int quantity,
    required int sampledPricePaise,
  }) async {
    if (quantity <= 0) {
      return const OrderExecutionResult.failure(
        'Quantity must be greater than zero.',
      );
    }
    if (sampledPricePaise <= 0) {
      return const OrderExecutionResult.failure(
        'Invalid execution price received from market feed.',
      );
    }

    final int totalValuePaise = quantity * sampledPricePaise;
    final int currentBalance = _ref.read(walletProvider);
    final List<Holding> currentHoldings = _ref.read(holdingsProvider);
    final holdingIndex = currentHoldings.indexWhere((h) => h.symbol == symbol);
    final Holding? existingHolding = holdingIndex != -1
        ? currentHoldings[holdingIndex]
        : null;

    if (side == OrderSide.buy) {
      if (currentBalance < totalValuePaise) {
        return OrderExecutionResult.failure(
          'Insufficient margin. Available: ₹${currentBalance / 100}, Required: ₹${totalValuePaise / 100}',
        );
      }

      final int nextBalance = currentBalance - totalValuePaise;
      final List<Holding> nextHoldings = List<Holding>.from(currentHoldings);

      if (existingHolding != null) {
        nextHoldings[holdingIndex] = existingHolding.applyBuy(
          additionalQty: quantity,
          pricePaise: sampledPricePaise,
        );
      } else {
        nextHoldings.add(
          Holding(
            symbol: symbol,
            quantity: quantity,
            totalCostPaise: totalValuePaise,
          ),
        );
      }

      final order = StockOrder(
        id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        side: OrderSide.buy,
        quantity: quantity,
        pricePaise: sampledPricePaise,
        totalValuePaise: totalValuePaise,
        status: OrderStatus.completed,
        timestamp: DateTime.now(),
      );

      await _ref.read(walletProvider.notifier).setBalance(nextBalance);
      await _ref.read(holdingsProvider.notifier).setHoldings(nextHoldings);
      await _ref.read(ordersProvider.notifier).recordOrder(order);

      return OrderExecutionResult.success(order);
    } else {
      if (existingHolding == null || existingHolding.quantity < quantity) {
        final held = existingHolding?.quantity ?? 0;
        return OrderExecutionResult.failure(
          'Insufficient shares held. You hold $held shares of $symbol, tried to sell $quantity.',
        );
      }

      final int nextBalance = currentBalance + totalValuePaise;
      final List<Holding> nextHoldings = List<Holding>.from(currentHoldings);
      final updatedHolding = existingHolding.applySell(sellQty: quantity);

      if (updatedHolding == null) {
        nextHoldings.removeAt(holdingIndex);
      } else {
        nextHoldings[holdingIndex] = updatedHolding;
      }

      final order = StockOrder(
        id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        side: OrderSide.sell,
        quantity: quantity,
        pricePaise: sampledPricePaise,
        totalValuePaise: totalValuePaise,
        status: OrderStatus.completed,
        timestamp: DateTime.now(),
      );

      await _ref.read(walletProvider.notifier).setBalance(nextBalance);
      await _ref.read(holdingsProvider.notifier).setHoldings(nextHoldings);
      await _ref.read(ordersProvider.notifier).recordOrder(order);

      return OrderExecutionResult.success(order);
    }
  }
}

final tradingServiceProvider = Provider<TradingService>((ref) {
  return TradingService(ref);
});
