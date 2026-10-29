enum PriceDirection { up, down, none }

class StockQuote {
  final String symbol;
  final int ltpPaise;
  final int previousClosePaise;
  final int changePaise;
  final double changePercent;
  final PriceDirection direction;
  final DateTime timestamp;

  const StockQuote({
    required this.symbol,
    required this.ltpPaise,
    required this.previousClosePaise,
    required this.changePaise,
    required this.changePercent,
    required this.direction,
    required this.timestamp,
  });

  factory StockQuote.compute({
    required String symbol,
    required int ltpPaise,
    required int previousClosePaise,
    required PriceDirection direction,
    DateTime? timestamp,
  }) {
    final int changePaise = ltpPaise - previousClosePaise;
    final double changePercent = previousClosePaise > 0
        ? (changePaise / previousClosePaise) * 100.0
        : 0.0;

    return StockQuote(
      symbol: symbol,
      ltpPaise: ltpPaise,
      previousClosePaise: previousClosePaise,
      changePaise: changePaise,
      changePercent: changePercent,
      direction: direction,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  StockQuote copyWith({
    String? symbol,
    int? ltpPaise,
    int? previousClosePaise,
    int? changePaise,
    double? changePercent,
    PriceDirection? direction,
    DateTime? timestamp,
  }) {
    return StockQuote(
      symbol: symbol ?? this.symbol,
      ltpPaise: ltpPaise ?? this.ltpPaise,
      previousClosePaise: previousClosePaise ?? this.previousClosePaise,
      changePaise: changePaise ?? this.changePaise,
      changePercent: changePercent ?? this.changePercent,
      direction: direction ?? this.direction,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'ltpPaise': ltpPaise,
      'previousClosePaise': previousClosePaise,
      'changePaise': changePaise,
      'changePercent': changePercent,
      'direction': direction.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      symbol: json['symbol'] as String,
      ltpPaise: json['ltpPaise'] as int,
      previousClosePaise: json['previousClosePaise'] as int,
      changePaise: json['changePaise'] as int,
      changePercent: (json['changePercent'] as num).toDouble(),
      direction: PriceDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => PriceDirection.none,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockQuote &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          ltpPaise == other.ltpPaise &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(symbol, ltpPaise, direction);

  @override
  String toString() =>
      'StockQuote($symbol: $ltpPaise paise, $changePercent%, dir: $direction)';
}
