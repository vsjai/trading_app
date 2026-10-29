import 'dart:async';
import 'dart:math';
import '../core/constants/app_constants.dart';
import '../models/stock.dart';
import '../models/stock_quote.dart';

enum TickRateMode {
  normal(ticksPerSecondPerStock: 0.2),

  active(ticksPerSecondPerStock: 1.0),

  stress(ticksPerSecondPerStock: 5.5);

  final double ticksPerSecondPerStock;
  const TickRateMode({required this.ticksPerSecondPerStock});
}

class MarketFeedService {
  final Map<String, Stock> _stocksBySymbol = {};
  final Map<String, StockQuote> _latestQuotes = {};
  final StreamController<StockQuote> _tickStreamController =
      StreamController<StockQuote>.broadcast();

  final Random _random;
  Timer? _timer;
  TickRateMode _currentMode = TickRateMode.normal;
  bool _isRunning = false;

  MarketFeedService({List<Stock>? customStocks, Random? random})
    : _random = random ?? Random() {
    final List<Stock> stocks = customStocks ?? AppConstants.initialStocks;
    for (final stock in stocks) {
      _stocksBySymbol[stock.symbol] = stock;
      _latestQuotes[stock.symbol] = StockQuote.compute(
        symbol: stock.symbol,
        ltpPaise: stock.basePricePaise,
        previousClosePaise: stock.previousClosePaise,
        direction: PriceDirection.none,
      );
    }
  }

  Stream<StockQuote> get quoteStream => _tickStreamController.stream;

  Stream<StockQuote> streamForSymbol(String symbol) {
    return _tickStreamController.stream.where((q) => q.symbol == symbol);
  }

  StockQuote? getLatestQuote(String symbol) {
    return _latestQuotes[symbol];
  }

  Map<String, StockQuote> getAllQuotes() {
    return Map<String, StockQuote>.unmodifiable(_latestQuotes);
  }

  Stock? getStock(String symbol) {
    return _stocksBySymbol[symbol];
  }

  List<Stock> get allStocks => _stocksBySymbol.values.toList();

  TickRateMode get currentMode => _currentMode;

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleTimer();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void setMode(TickRateMode mode) {
    _currentMode = mode;
    if (_isRunning) {
      _timer?.cancel();
      _scheduleTimer();
    }
  }

  void _scheduleTimer() {
    final double totalTicksPerSec =
        _stocksBySymbol.length * _currentMode.ticksPerSecondPerStock;
    final int intervalMs = max(10, (1000.0 / totalTicksPerSec).round());

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _emitRandomTick();
    });
  }

  StockQuote _emitRandomTick() {
    final List<String> symbols = _stocksBySymbol.keys.toList();
    final String symbol = symbols[_random.nextInt(symbols.length)];
    return emitTickForSymbol(symbol);
  }

  StockQuote emitTickForSymbol(String symbol) {
    final Stock? stock = _stocksBySymbol[symbol];
    final StockQuote? currentQuote = _latestQuotes[symbol];
    if (stock == null || currentQuote == null) {
      throw ArgumentError('Symbol $symbol not recognized by MarketFeedService');
    }

    final int currentLtp = currentQuote.ltpPaise;
    final int basePrice = stock.basePricePaise;

    final double deviationFromBase = (currentLtp - basePrice) / basePrice;
    double upwardBias = 0.50;
    if (deviationFromBase > 0.08) {
      upwardBias = 0.38;
    } else if (deviationFromBase < -0.08) {
      upwardBias = 0.62;
    }

    final bool isUp = _random.nextDouble() < upwardBias;

    final double deltaRatio = 0.0005 + (_random.nextDouble() * 0.0025);
    int deltaPaise = (currentLtp * deltaRatio).round();
    if (deltaPaise < 5) deltaPaise = 5;

    final int newLtp = isUp
        ? (currentLtp + deltaPaise)
        : max(100, currentLtp - deltaPaise);

    final PriceDirection direction = newLtp > currentLtp
        ? PriceDirection.up
        : (newLtp < currentLtp ? PriceDirection.down : PriceDirection.none);

    final StockQuote newQuote = StockQuote.compute(
      symbol: symbol,
      ltpPaise: newLtp,
      previousClosePaise: stock.previousClosePaise,
      direction: direction,
      timestamp: DateTime.now(),
    );

    _latestQuotes[symbol] = newQuote;
    _tickStreamController.add(newQuote);
    return newQuote;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _tickStreamController.close();
  }
}
