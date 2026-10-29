class Holding {
  final String symbol;
  final int quantity;
  final int totalCostPaise;

  const Holding({
    required this.symbol,
    required this.quantity,
    required this.totalCostPaise,
  });

  int get avgCostPaise =>
      quantity > 0 ? (totalCostPaise / quantity).round() : 0;

  int currentValuePaise(int ltpPaise) => quantity * ltpPaise;

  int pnlPaise(int ltpPaise) => currentValuePaise(ltpPaise) - totalCostPaise;

  double pnlPercent(int ltpPaise) {
    if (totalCostPaise <= 0) return 0.0;
    return (pnlPaise(ltpPaise) / totalCostPaise) * 100.0;
  }

  Holding applyBuy({required int additionalQty, required int pricePaise}) {
    final int newQty = quantity + additionalQty;
    final int addedCost = additionalQty * pricePaise;
    return Holding(
      symbol: symbol,
      quantity: newQty,
      totalCostPaise: totalCostPaise + addedCost,
    );
  }

  Holding? applySell({required int sellQty}) {
    if (sellQty >= quantity) {
      return null;
    }
    final int newQty = quantity - sellQty;

    final int newTotalCost = ((totalCostPaise * newQty) / quantity).round();
    return Holding(
      symbol: symbol,
      quantity: newQty,
      totalCostPaise: newTotalCost,
    );
  }

  Holding copyWith({String? symbol, int? quantity, int? totalCostPaise}) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      totalCostPaise: totalCostPaise ?? this.totalCostPaise,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'totalCostPaise': totalCostPaise,
    };
  }

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as int,
      totalCostPaise: json['totalCostPaise'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Holding &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          quantity == other.quantity &&
          totalCostPaise == other.totalCostPaise;

  @override
  int get hashCode => Object.hash(symbol, quantity, totalCostPaise);

  @override
  String toString() =>
      'Holding($symbol: $quantity shares, avg: ₹${avgCostPaise / 100}, total: ₹${totalCostPaise / 100})';
}
