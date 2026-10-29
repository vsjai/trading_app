import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock.dart';
import '../models/stock_quote.dart';
import '../services/market_feed_service.dart';

final marketFeedServiceProvider = Provider<MarketFeedService>((ref) {
  final service = MarketFeedService();
  service.start();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class TickRateModeNotifier extends StateNotifier<TickRateMode> {
  final MarketFeedService _feedService;

  TickRateModeNotifier(this._feedService) : super(_feedService.currentMode);

  void setMode(TickRateMode mode) {
    state = mode;
    _feedService.setMode(mode);
  }

  void toggleStressMode() {
    if (state == TickRateMode.stress) {
      setMode(TickRateMode.normal);
    } else {
      setMode(TickRateMode.stress);
    }
  }
}

final tickRateModeProvider =
    StateNotifierProvider<TickRateModeNotifier, TickRateMode>((ref) {
      final feed = ref.watch(marketFeedServiceProvider);
      return TickRateModeNotifier(feed);
    });

final allStocksProvider = Provider<List<Stock>>((ref) {
  final feed = ref.watch(marketFeedServiceProvider);
  return feed.allStocks;
});

final stockMetadataProvider = Provider.family<Stock?, String>((ref, symbol) {
  final feed = ref.watch(marketFeedServiceProvider);
  return feed.getStock(symbol);
});

final stockQuoteProvider = StreamProvider.family<StockQuote, String>((
  ref,
  symbol,
) async* {
  final feed = ref.watch(marketFeedServiceProvider);

  final cached = feed.getLatestQuote(symbol);
  if (cached != null) {
    yield cached;
  }

  yield* feed.streamForSymbol(symbol);
});

final marketTickStreamProvider = StreamProvider<StockQuote>((ref) {
  final feed = ref.watch(marketFeedServiceProvider);
  return feed.quoteStream;
});
