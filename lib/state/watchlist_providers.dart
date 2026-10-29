import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/watchlist.dart';
import '../services/storage_service.dart';
import 'storage_providers.dart';

class WatchlistNotifier extends StateNotifier<List<Watchlist>> {
  final StorageService _storageService;

  WatchlistNotifier(this._storageService) : super([]) {
    _loadInitialWatchlists();
  }

  void _loadInitialWatchlists() {
    final persisted = _storageService.loadWatchlists();
    if (persisted != null && persisted.isNotEmpty) {
      state = persisted;
    } else {
      final defaults = [
        const Watchlist(
          id: AppConstants.defaultWatchlistId,
          name: AppConstants.defaultWatchlistName,
          symbols: AppConstants.defaultWatchlistSymbols,
        ),
        const Watchlist(
          id: AppConstants.secondaryWatchlistId,
          name: AppConstants.secondaryWatchlistName,
          symbols: AppConstants.secondaryWatchlistSymbols,
        ),
      ];
      state = defaults;
      _storageService.saveWatchlists(defaults);
    }
  }

  Future<String> createWatchlist(String name) async {
    final trimmed = name.trim();
    final newId = 'wl_${DateTime.now().millisecondsSinceEpoch}';
    if (trimmed.isEmpty) return newId;

    final newWatchlist = Watchlist(id: newId, name: trimmed, symbols: const []);

    final updated = [...state, newWatchlist];
    state = updated;
    await _storageService.saveWatchlists(updated);
    return newId;
  }

  Future<void> renameWatchlist(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = [
      for (final w in state)
        if (w.id == id) w.copyWith(name: trimmed) else w,
    ];

    state = updated;
    await _storageService.saveWatchlists(updated);
  }

  Future<void> deleteWatchlist(String id) async {
    if (state.length <= 1) return;

    final updated = state.where((w) => w.id != id).toList();
    state = updated;
    await _storageService.saveWatchlists(updated);
  }

  Future<void> addStockToWatchlist(String watchlistId, String symbol) async {
    if (!AppConstants.supportedSymbols.contains(symbol)) return;

    final updated = [
      for (final w in state)
        if (w.id == watchlistId)
          if (!w.symbols.contains(symbol))
            w.copyWith(symbols: [...w.symbols, symbol])
          else
            w
        else
          w,
    ];

    state = updated;
    await _storageService.saveWatchlists(updated);
  }

  Future<void> removeStockFromWatchlist(
    String watchlistId,
    String symbol,
  ) async {
    final updated = [
      for (final w in state)
        if (w.id == watchlistId)
          w.copyWith(symbols: w.symbols.where((s) => s != symbol).toList())
        else
          w,
    ];

    state = updated;
    await _storageService.saveWatchlists(updated);
  }

  Future<void> reorderStocks(
    String watchlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final targetIndex = state.indexWhere((w) => w.id == watchlistId);
    if (targetIndex == -1) return;

    final target = state[targetIndex];
    final currentSymbols = List<String>.from(target.symbols);
    if (oldIndex < 0 || oldIndex >= currentSymbols.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0 || newIndex >= currentSymbols.length) return;

    final moved = currentSymbols.removeAt(oldIndex);
    currentSymbols.insert(newIndex, moved);

    final updatedWatchlist = target.copyWith(symbols: currentSymbols);
    final updatedList = List<Watchlist>.from(state);
    updatedList[targetIndex] = updatedWatchlist;

    state = updatedList;
    await _storageService.saveWatchlists(updatedList);
  }
}

final watchlistsProvider =
    StateNotifierProvider<WatchlistNotifier, List<Watchlist>>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return WatchlistNotifier(storage);
    });

final activeWatchlistIdProvider = StateProvider<String>((ref) {
  return AppConstants.defaultWatchlistId;
});

final activeWatchlistProvider = Provider<Watchlist?>((ref) {
  final watchlists = ref.watch(watchlistsProvider);
  final activeId = ref.watch(activeWatchlistIdProvider);
  if (watchlists.isEmpty) return null;
  return watchlists.firstWhere(
    (w) => w.id == activeId,
    orElse: () => watchlists.first,
  );
});
