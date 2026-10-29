import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/models/holding.dart';
import 'package:trading_app/models/order.dart';
import 'package:trading_app/models/watchlist.dart';
import 'package:trading_app/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
    });

    test('saves and loads watchlists accurately', () async {
      expect(storage.loadWatchlists(), isNull);

      final list = [
        const Watchlist(id: 'w1', name: 'Main', symbols: ['INFY', 'TCS']),
        const Watchlist(
          id: 'w2',
          name: 'Banking',
          symbols: ['SBIN', 'HDFCBANK'],
        ),
      ];

      await storage.saveWatchlists(list);
      final loaded = storage.loadWatchlists();

      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
      expect(loaded[0].name, 'Main');
      expect(loaded[1].symbols, ['SBIN', 'HDFCBANK']);
    });

    test('saves and loads wallet balance', () async {
      expect(storage.loadWalletBalance(), isNull);

      await storage.saveWalletBalance(50000000);
      expect(storage.loadWalletBalance(), 50000000);
    });

    test('saves and loads holdings and orders', () async {
      final holdings = [
        const Holding(symbol: 'RELIANCE', quantity: 5, totalCostPaise: 1500000),
      ];
      final orders = [
        StockOrder(
          id: 'ord_1',
          symbol: 'RELIANCE',
          side: OrderSide.buy,
          quantity: 5,
          pricePaise: 300000,
          totalValuePaise: 1500000,
          status: OrderStatus.completed,
          timestamp: DateTime(2026, 1, 1),
        ),
      ];

      await storage.saveHoldings(holdings);
      await storage.saveOrders(orders);

      expect(storage.loadHoldings()?.length, 1);
      expect(storage.loadOrders()?.length, 1);
      expect(storage.loadHoldings()!.first.symbol, 'RELIANCE');
      expect(storage.loadOrders()!.first.totalValuePaise, 1500000);
    });
  });
}
