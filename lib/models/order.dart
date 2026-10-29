enum OrderSide { buy, sell }

enum OrderStatus { completed, rejected }

class StockOrder {
  final String id;
  final String symbol;
  final OrderSide side;
  final int quantity;
  final int pricePaise;
  final int totalValuePaise;
  final OrderStatus status;
  final DateTime timestamp;
  final String? failureReason;

  const StockOrder({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.pricePaise,
    required this.totalValuePaise,
    required this.status,
    required this.timestamp,
    this.failureReason,
  });

  StockOrder copyWith({
    String? id,
    String? symbol,
    OrderSide? side,
    int? quantity,
    int? pricePaise,
    int? totalValuePaise,
    OrderStatus? status,
    DateTime? timestamp,
    String? failureReason,
  }) {
    return StockOrder(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      quantity: quantity ?? this.quantity,
      pricePaise: pricePaise ?? this.pricePaise,
      totalValuePaise: totalValuePaise ?? this.totalValuePaise,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'side': side.name,
      'quantity': quantity,
      'pricePaise': pricePaise,
      'totalValuePaise': totalValuePaise,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  factory StockOrder.fromJson(Map<String, dynamic> json) {
    return StockOrder(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: OrderSide.values.firstWhere(
        (e) => e.name == json['side'],
        orElse: () => OrderSide.buy,
      ),
      quantity: json['quantity'] as int,
      pricePaise: json['pricePaise'] as int,
      totalValuePaise: json['totalValuePaise'] as int,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.completed,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      failureReason: json['failureReason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockOrder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StockOrder($id: ${side.name.toUpperCase()} $quantity of $symbol @ ₹${pricePaise / 100})';
}
