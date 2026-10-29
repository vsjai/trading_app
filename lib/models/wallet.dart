class Wallet {
  final int balancePaise;

  const Wallet({required this.balancePaise});

  bool canAfford(int costPaise) => balancePaise >= costPaise;

  Wallet deduct(int costPaise) {
    if (!canAfford(costPaise)) {
      throw StateError('Insufficient balance to deduct $costPaise paise');
    }
    return Wallet(balancePaise: balancePaise - costPaise);
  }

  Wallet credit(int proceedPaise) {
    return Wallet(balancePaise: balancePaise + proceedPaise);
  }

  Map<String, dynamic> toJson() {
    return {'balancePaise': balancePaise};
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(balancePaise: json['balancePaise'] as int);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet &&
          runtimeType == other.runtimeType &&
          balancePaise == other.balancePaise;

  @override
  int get hashCode => balancePaise.hashCode;

  @override
  String toString() => 'Wallet(₹${balancePaise / 100})';
}
