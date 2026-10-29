import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/app_constants.dart';
import 'package:trading_app/models/watchlist.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/watchlist_providers.dart';

void main() {
  group('WatchlistNotifier', () {
    late InMemoryStorageService storage;
    late WatchlistNotifier notifier;

    setUp(() {
      storage = InMemoryStorageService();
      notifier = WatchlistNotifier(storage);
    });

    test('initializes with default watchlists if storage is empty', () {
      expect(notifier.state.length, 2);
      expect(notifier.state[0].id, AppConstants.defaultWatchlistId);
      expect(notifier.state[0].name, AppConstants.defaultWatchlistName);
      expect(notifier.state[0].symbols, AppConstants.defaultWatchlistSymbols);
      expect(storage.loadWatchlists()?.length, 2);
    });

    test('restores watchlists from storage if available', () {
      final customStorage = InMemoryStorageService();
      customStorage.saveWatchlists([
        const Watchlist(
          id: 'w_saved',
          name: 'Saved List',
          symbols: ['ITC', 'LT'],
        ),
      ]);

      final customNotifier = WatchlistNotifier(customStorage);
      expect(customNotifier.state.length, 1);
      expect(customNotifier.state.first.name, 'Saved List');
      expect(customNotifier.state.first.symbols, ['ITC', 'LT']);
    });

    test('creates new watchlist and persists it', () async {
      await notifier.createWatchlist('Bluechips');

      expect(notifier.state.length, 3);
      expect(notifier.state.last.name, 'Bluechips');
      expect(notifier.state.last.symbols, isEmpty);

      final persisted = storage.loadWatchlists()!;
      expect(persisted.length, 3);
      expect(persisted.last.name, 'Bluechips');
    });

    test('renames existing watchlist and persists it', () async {
      final initialId = notifier.state.first.id;
      await notifier.renameWatchlist(initialId, 'Nifty Prime');

      expect(notifier.state.first.name, 'Nifty Prime');
      expect(storage.loadWatchlists()!.first.name, 'Nifty Prime');
    });

    test('deletes watchlist while preserving at least one watchlist', () async {
      final firstId = notifier.state.first.id;
      final secondId = notifier.state[1].id;

      await notifier.deleteWatchlist(firstId);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, secondId);

      // Attempt to delete last watchlist should be blocked
      await notifier.deleteWatchlist(secondId);
      expect(notifier.state.length, 1);
    });

    test('adds stock to watchlist without duplicate symbols', () async {
      final targetId = notifier.state.first.id;

      await notifier.addStockToWatchlist(targetId, 'ITC');
      expect(notifier.state.first.symbols.contains('ITC'), isTrue);

      final countBefore = notifier.state.first.symbols.length;
      await notifier.addStockToWatchlist(targetId, 'ITC');
      expect(notifier.state.first.symbols.length, countBefore);
    });

    test(
      'removing stock from one watchlist preserves it in other watchlists',
      () async {
        final w1Id = notifier.state[0].id;

        // Both defaults contain 'HDFCBANK'
        expect(notifier.state[0].symbols.contains('HDFCBANK'), isTrue);
        expect(notifier.state[1].symbols.contains('HDFCBANK'), isTrue);

        await notifier.removeStockFromWatchlist(w1Id, 'HDFCBANK');

        expect(notifier.state[0].symbols.contains('HDFCBANK'), isFalse);
        expect(notifier.state[1].symbols.contains('HDFCBANK'), isTrue);
        expect(
          storage.loadWatchlists()![1].symbols.contains('HDFCBANK'),
          isTrue,
        );
      },
    );

    test('reorders stocks accurately and persists order', () async {
      final targetId = notifier.state.first.id;
      final original = List<String>.from(notifier.state.first.symbols);
      final firstSymbol = original.first;

      // Move first item to position 2
      await notifier.reorderStocks(targetId, 0, 3);

      final updated = notifier.state.first.symbols;
      expect(updated[2], firstSymbol);
      expect(storage.loadWatchlists()!.first.symbols[2], firstSymbol);
    });
  });
}
