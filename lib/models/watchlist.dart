class Watchlist {
  final String id;
  final String name;
  final List<String> symbols;

  const Watchlist({
    required this.id,
    required this.name,
    required this.symbols,
  });

  Watchlist copyWith({String? id, String? name, List<String>? symbols}) {
    return Watchlist(
      id: id ?? this.id,
      name: name ?? this.name,
      symbols: symbols != null
          ? List<String>.unmodifiable(symbols)
          : this.symbols,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'symbols': symbols};
  }

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: (json['symbols'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Watchlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          symbols.length == other.symbols.length;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Watchlist($id, "$name", count: ${symbols.length})';
}
