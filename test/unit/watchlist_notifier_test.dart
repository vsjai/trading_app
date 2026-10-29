import 'package:flutter_test/flutter_test.dart';
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

    test('initializes with empty watchlists if storage is empty', () {
      expect(notifier.state, isEmpty);
      expect(storage.loadWatchlists()?.isEmpty, isTrue);
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
      final id = await notifier.createWatchlist('Bluechips');

      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, id);
      expect(notifier.state.first.name, 'Bluechips');
      expect(notifier.state.first.symbols, isEmpty);

      final persisted = storage.loadWatchlists()!;
      expect(persisted.length, 1);
      expect(persisted.first.name, 'Bluechips');
    });

    test('renames existing watchlist and persists it', () async {
      final id = await notifier.createWatchlist('Initial Name');
      await notifier.renameWatchlist(id, 'Nifty Prime');

      expect(notifier.state.first.name, 'Nifty Prime');
      expect(storage.loadWatchlists()!.first.name, 'Nifty Prime');
    });

    test(
      'deletes any watchlist including the last one down to empty',
      () async {
        final firstId = await notifier.createWatchlist('List 1');
        final secondId = await notifier.createWatchlist('List 2');

        await notifier.deleteWatchlist(firstId);
        expect(notifier.state.length, 1);
        expect(notifier.state.first.id, secondId);

        await notifier.deleteWatchlist(secondId);
        expect(notifier.state, isEmpty);
        expect(storage.loadWatchlists(), isEmpty);
      },
    );

    test('adds stock to watchlist without duplicate symbols', () async {
      final targetId = await notifier.createWatchlist('My Watchlist');

      await notifier.addStockToWatchlist(targetId, 'ITC');
      expect(notifier.state.first.symbols.contains('ITC'), isTrue);

      final countBefore = notifier.state.first.symbols.length;
      await notifier.addStockToWatchlist(targetId, 'ITC');
      expect(notifier.state.first.symbols.length, countBefore);
    });

    test(
      'removing stock from one watchlist preserves it in other watchlists',
      () async {
        final w1Id = await notifier.createWatchlist('List 1');
        final w2Id = await notifier.createWatchlist('List 2');

        await notifier.addStockToWatchlist(w1Id, 'HDFCBANK');
        await notifier.addStockToWatchlist(w2Id, 'HDFCBANK');

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
      final targetId = await notifier.createWatchlist('Reorder Test');
      await notifier.addStockToWatchlist(targetId, 'RELIANCE');
      await notifier.addStockToWatchlist(targetId, 'TCS');
      await notifier.addStockToWatchlist(targetId, 'INFY');

      expect(notifier.state.first.symbols, ['RELIANCE', 'TCS', 'INFY']);

      await notifier.reorderStocks(targetId, 0, 3);

      final updated = notifier.state.first.symbols;
      expect(updated[2], 'RELIANCE');
      expect(storage.loadWatchlists()!.first.symbols[2], 'RELIANCE');
    });
  });
}
