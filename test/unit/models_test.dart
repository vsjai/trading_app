import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/models/holding.dart';
import 'package:trading_app/models/order.dart';
import 'package:trading_app/models/stock.dart';
import 'package:trading_app/models/stock_quote.dart';
import 'package:trading_app/models/wallet.dart';
import 'package:trading_app/models/watchlist.dart';

void main() {
  group('StockQuote Model', () {
    test('computes positive change and percentage accurately', () {
      final quote = StockQuote.compute(
        symbol: 'RELIANCE',
        ltpPaise: 300000,
        previousClosePaise: 290000,
        direction: PriceDirection.up,
      );

      expect(quote.changePaise, 10000);
      expect(quote.changePercent, closeTo(3.448, 0.001));
      expect(quote.direction, PriceDirection.up);
    });

    test('serializes and deserializes StockQuote correctly', () {
      final quote = StockQuote.compute(
        symbol: 'TCS',
        ltpPaise: 380000,
        previousClosePaise: 390000,
        direction: PriceDirection.down,
      );

      final json = quote.toJson();
      final restored = StockQuote.fromJson(json);

      expect(restored.symbol, quote.symbol);
      expect(restored.ltpPaise, quote.ltpPaise);
      expect(restored.previousClosePaise, quote.previousClosePaise);
      expect(restored.changePaise, quote.changePaise);
      expect(restored.direction, PriceDirection.down);
    });

    test('serializes and deserializes Stock model', () {
      const stock = Stock(
        symbol: 'ITC',
        name: 'ITC Ltd',
        sector: 'FMCG',
        basePricePaise: 43500,
        previousClosePaise: 43000,
      );

      final json = stock.toJson();
      final restored = Stock.fromJson(json);
      expect(restored.symbol, 'ITC');
      expect(restored.name, 'ITC Ltd');
      expect(restored.basePricePaise, 43500);
      expect(restored, stock);
    });
  });

  group('Holding Model', () {
    test('computes avg cost, current value, and P&L correctly', () {
      // 10 shares bought at total cost of ₹10,000 (1,000,000 paise) -> avg cost = ₹1,000 (100,000 paise)
      const holding = Holding(
        symbol: 'INFY',
        quantity: 10,
        totalCostPaise: 1000000,
      );

      expect(holding.avgCostPaise, 100000);

      // If LTP is ₹1,200 (120,000 paise)
      expect(holding.currentValuePaise(120000), 1200000);
      expect(holding.pnlPaise(120000), 200000); // +₹2,000
      expect(holding.pnlPercent(120000), 20.0); // +20%

      // If LTP drops to ₹800 (80,000 paise)
      expect(holding.pnlPaise(80000), -200000); // -₹2,000
      expect(holding.pnlPercent(80000), -20.0); // -20%
    });

    test('updates correctly on Buy execution', () {
      const holding = Holding(
        symbol: 'SBIN',
        quantity: 5,
        totalCostPaise: 500000, // 5 shares @ ₹1000 avg
      );

      // Buy 5 more shares @ ₹1200 (120,000 paise)
      final updated = holding.applyBuy(additionalQty: 5, pricePaise: 120000);
      expect(updated.quantity, 10);
      expect(updated.totalCostPaise, 1100000); // 500,000 + 600,000
      expect(updated.avgCostPaise, 110000); // ₹1,100 avg
    });

    test('updates correctly on Sell execution', () {
      const holding = Holding(
        symbol: 'SBIN',
        quantity: 10,
        totalCostPaise: 1000000, // avg 100,000 paise
      );

      // Sell 4 shares
      final updated = holding.applySell(sellQty: 4);
      expect(updated, isNotNull);
      expect(updated!.quantity, 6);
      expect(updated.totalCostPaise, 600000);
      expect(updated.avgCostPaise, 100000);

      // Fully liquidate remaining 6 shares
      final liquidated = updated.applySell(sellQty: 6);
      expect(liquidated, isNull);
    });
  });

  group('Wallet Model', () {
    test(
      'deducts and credits balance correctly with guard against negative balance',
      () {
        const wallet = Wallet(balancePaise: 100000); // ₹1,000

        expect(wallet.canAfford(50000), isTrue);
        expect(wallet.canAfford(150000), isFalse);

        final afterDeduct = wallet.deduct(40000);
        expect(afterDeduct.balancePaise, 60000);

        final afterCredit = afterDeduct.credit(20000);
        expect(afterCredit.balancePaise, 80000);

        expect(() => wallet.deduct(150000), throwsStateError);
      },
    );
  });

  group('StockOrder & Watchlist Models', () {
    test('serializes StockOrder properly', () {
      final order = StockOrder(
        id: 'ord_123',
        symbol: 'HDFCBANK',
        side: OrderSide.buy,
        quantity: 10,
        pricePaise: 168000,
        totalValuePaise: 1680000,
        status: OrderStatus.completed,
        timestamp: DateTime(2026, 1, 1),
      );

      final json = order.toJson();
      final restored = StockOrder.fromJson(json);

      expect(restored.id, 'ord_123');
      expect(restored.side, OrderSide.buy);
      expect(restored.totalValuePaise, 1680000);
      expect(restored.status, OrderStatus.completed);
    });

    test('serializes and copies Watchlist properly', () {
      const watchlist = Watchlist(
        id: 'wl_1',
        name: 'Tech Favorites',
        symbols: ['TCS', 'INFY'],
      );

      final json = watchlist.toJson();
      final restored = Watchlist.fromJson(json);
      expect(restored.id, 'wl_1');
      expect(restored.symbols, ['TCS', 'INFY']);

      final updated = watchlist.copyWith(name: 'IT Leaders');
      expect(updated.name, 'IT Leaders');
      expect(updated.symbols, ['TCS', 'INFY']);
    });
  });
}
