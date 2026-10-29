import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/holding.dart';
import '../models/order.dart';
import '../models/watchlist.dart';

abstract class StorageService {
  Future<void> init();

  List<Watchlist>? loadWatchlists();
  Future<void> saveWatchlists(List<Watchlist> watchlists);

  int? loadWalletBalance();
  Future<void> saveWalletBalance(int balancePaise);

  List<Holding>? loadHoldings();
  Future<void> saveHoldings(List<Holding> holdings);

  List<StockOrder>? loadOrders();
  Future<void> saveOrders(List<StockOrder> orders);

  Future<void> clearAll();
}

class SharedPrefsStorageService implements StorageService {
  static const String _keyWatchlists = 'trading_app_watchlists_v1';
  static const String _keyWalletBalance = 'trading_app_wallet_balance_v1';
  static const String _keyHoldings = 'trading_app_holdings_v1';
  static const String _keyOrders = 'trading_app_orders_v1';

  final SharedPreferences? _customPrefs;
  SharedPreferences? _prefs;

  SharedPrefsStorageService({SharedPreferences? prefs}) : _customPrefs = prefs;

  @override
  Future<void> init() async {
    _prefs = _customPrefs ?? await SharedPreferences.getInstance();
  }

  SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'StorageService has not been initialized. Call init() first.',
      );
    }
    return _prefs!;
  }

  @override
  List<Watchlist>? loadWatchlists() {
    final String? raw = _instance.getString(_keyWatchlists);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Watchlist.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveWatchlists(List<Watchlist> watchlists) async {
    final String raw = jsonEncode(watchlists.map((w) => w.toJson()).toList());
    await _instance.setString(_keyWatchlists, raw);
  }

  @override
  int? loadWalletBalance() {
    return _instance.getInt(_keyWalletBalance);
  }

  @override
  Future<void> saveWalletBalance(int balancePaise) async {
    await _instance.setInt(_keyWalletBalance, balancePaise);
  }

  @override
  List<Holding>? loadHoldings() {
    final String? raw = _instance.getString(_keyHoldings);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Holding.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveHoldings(List<Holding> holdings) async {
    final String raw = jsonEncode(holdings.map((h) => h.toJson()).toList());
    await _instance.setString(_keyHoldings, raw);
  }

  @override
  List<StockOrder>? loadOrders() {
    final String? raw = _instance.getString(_keyOrders);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => StockOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveOrders(List<StockOrder> orders) async {
    final String raw = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _instance.setString(_keyOrders, raw);
  }

  @override
  Future<void> clearAll() async {
    await _instance.remove(_keyWatchlists);
    await _instance.remove(_keyWalletBalance);
    await _instance.remove(_keyHoldings);
    await _instance.remove(_keyOrders);
  }
}

class InMemoryStorageService implements StorageService {
  List<Watchlist>? _watchlists;
  int? _walletBalance;
  List<Holding>? _holdings;
  List<StockOrder>? _orders;

  @override
  Future<void> init() async {}

  @override
  List<Watchlist>? loadWatchlists() => _watchlists;

  @override
  Future<void> saveWatchlists(List<Watchlist> watchlists) async {
    _watchlists = List<Watchlist>.from(watchlists);
  }

  @override
  int? loadWalletBalance() => _walletBalance;

  @override
  Future<void> saveWalletBalance(int balancePaise) async {
    _walletBalance = balancePaise;
  }

  @override
  List<Holding>? loadHoldings() => _holdings;

  @override
  Future<void> saveHoldings(List<Holding> holdings) async {
    _holdings = List<Holding>.from(holdings);
  }

  @override
  List<StockOrder>? loadOrders() => _orders;

  @override
  Future<void> saveOrders(List<StockOrder> orders) async {
    _orders = List<StockOrder>.from(orders);
  }

  @override
  Future<void> clearAll() async {
    _watchlists = null;
    _walletBalance = null;
    _holdings = null;
    _orders = null;
  }
}
