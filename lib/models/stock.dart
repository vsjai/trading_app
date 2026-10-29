class Stock {
  final String symbol;
  final String name;
  final String sector;
  final int basePricePaise;
  final int previousClosePaise;

  const Stock({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.basePricePaise,
    required this.previousClosePaise,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'sector': sector,
      'basePricePaise': basePricePaise,
      'previousClosePaise': previousClosePaise,
    };
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String,
      basePricePaise: json['basePricePaise'] as int,
      previousClosePaise: json['previousClosePaise'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => 'Stock($symbol, $name, base: $basePricePaise)';
}
