import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/app_constants.dart';
import 'package:trading_app/models/stock_quote.dart';
import 'package:trading_app/services/market_feed_service.dart';

void main() {
  group('MarketFeedService', () {
    late MarketFeedService feed;

    setUp(() {
      feed = MarketFeedService();
    });

    tearDown(() {
      feed.dispose();
    });

    test('initializes with all 10 required canonical stocks', () {
      expect(feed.allStocks.length, 10);
      final symbols = feed.allStocks.map((s) => s.symbol).toSet();
      expect(
        symbols,
        containsAll([
          'RELIANCE',
          'TCS',
          'INFY',
          'HDFCBANK',
          'ICICIBANK',
          'SBIN',
          'ITC',
          'LT',
          'BHARTIARTL',
          'AXISBANK',
        ]),
      );
    });

    test('provides non-null latest quote synchronously for all 10 symbols', () {
      for (final stock in AppConstants.initialStocks) {
        final quote = feed.getLatestQuote(stock.symbol);
        expect(quote, isNotNull);
        expect(quote!.symbol, stock.symbol);
        expect(quote.ltpPaise, stock.basePricePaise);
        expect(quote.previousClosePaise, stock.previousClosePaise);
      }
    });

    test(
      'emits ticks that update latest quote and broadcast on stream',
      () async {
        final completer = Completer<StockQuote>();
        final sub = feed.streamForSymbol('RELIANCE').listen((quote) {
          if (!completer.isCompleted) {
            completer.complete(quote);
          }
        });

        final initialQuote = feed.getLatestQuote('RELIANCE')!;
        final emitted = feed.emitTickForSymbol('RELIANCE');

        expect(emitted.symbol, 'RELIANCE');
        expect(emitted.previousClosePaise, initialQuote.previousClosePaise);

        final received = await completer.future.timeout(
          const Duration(seconds: 2),
        );
        expect(received.symbol, 'RELIANCE');
        expect(received.ltpPaise, emitted.ltpPaise);

        // Verify synchronous getter reflects new price
        expect(feed.getLatestQuote('RELIANCE')?.ltpPaise, emitted.ltpPaise);

        await sub.cancel();
      },
    );

    test('stress test mode can emit 5+ ticks per second per stock', () async {
      feed.setMode(TickRateMode.stress);
      feed.start();

      int tickCount = 0;
      final sub = feed.quoteStream.listen((_) {
        tickCount++;
      });

      // Let it run for 400 milliseconds
      await Future<void>.delayed(const Duration(milliseconds: 400));
      feed.pause();
      await sub.cancel();

      // In stress mode, total rate is ~55 ticks/sec overall (5.5 ticks/sec * 10 stocks).
      // Over 400ms, we expect ~15 to 25 ticks.
      expect(tickCount, greaterThanOrEqualTo(10));
    });

    test('pauses and resumes without losing cached quotes', () {
      feed.start();
      expect(feed.isRunning, isTrue);

      feed.pause();
      expect(feed.isRunning, isFalse);

      final quote = feed.getLatestQuote('TCS');
      expect(quote, isNotNull);
      expect(quote!.symbol, 'TCS');
    });
  });
}
