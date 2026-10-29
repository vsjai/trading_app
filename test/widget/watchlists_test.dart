import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/models/watchlist.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/ui/watchlist/watchlists_screen.dart';

void main() {
  late MarketFeedService testFeed;
  late InMemoryStorageService testStorage;

  setUp(() {
    testFeed = MarketFeedService();
    testStorage = InMemoryStorageService();
  });

  tearDown(() {
    testFeed.dispose();
  });

  Widget createSubject({List<Watchlist>? initialWatchlists}) {
    if (initialWatchlists != null) {
      testStorage.saveWatchlists(initialWatchlists);
    }

    return ProviderScope(
      overrides: [
        marketFeedServiceProvider.overrideWithValue(testFeed),
        storageServiceProvider.overrideWithValue(testStorage),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const WatchlistsScreen(),
      ),
    );
  }

  final sampleWatchlists = [
    const Watchlist(
      id: 'wl_1',
      name: 'Nifty Top 10',
      symbols: ['RELIANCE', 'TCS'],
    ),
    const Watchlist(
      id: 'wl_2',
      name: 'Banking & Infra',
      symbols: ['SBIN', 'LT'],
    ),
  ];

  testWidgets('Empty state is shown when no watchlists are created', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Watchlists'), findsOneWidget);
    expect(find.text('No Watchlists Created'), findsOneWidget);
    expect(find.text('Create Watchlist'), findsOneWidget);
  });

  testWidgets('WatchlistsScreen renders active watchlist tabs and stock rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject(initialWatchlists: sampleWatchlists));
    await tester.pumpAndSettle();

    expect(find.text('Watchlists'), findsOneWidget);
    expect(find.text('Nifty Top 10'), findsOneWidget);
    expect(find.text('Banking & Infra'), findsOneWidget);
    expect(find.text('RELIANCE'), findsOneWidget);
    expect(find.text('TCS'), findsOneWidget);
  });

  testWidgets('Switching tabs displays stocks for selected watchlist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject(initialWatchlists: sampleWatchlists));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Banking & Infra'));
    await tester.pumpAndSettle();

    expect(find.text('SBIN'), findsOneWidget);
    expect(find.text('LT'), findsOneWidget);
  });

  testWidgets('Empty watchlist displays empty state with Add Stocks button', (
    WidgetTester tester,
  ) async {
    final emptyWatchlist = [
      const Watchlist(id: 'w_empty', name: 'Empty Portfolio', symbols: []),
    ];

    await tester.pumpWidget(createSubject(initialWatchlists: emptyWatchlist));
    await tester.pumpAndSettle();

    expect(find.text('Watchlist is Empty'), findsOneWidget);
    expect(find.text('Add Stocks'), findsWidgets);
  });

  testWidgets('Removing a stock removes it from screen immediately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject(initialWatchlists: sampleWatchlists));
    await tester.pumpAndSettle();

    expect(find.text('RELIANCE'), findsOneWidget);

    final deleteButtons = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('RELIANCE'), findsNothing);
  });

  testWidgets(
    'Tapping a stock row opens BuySellTicketSheet with pre-selected symbol',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createSubject(initialWatchlists: sampleWatchlists),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TCS'));
      await tester.pumpAndSettle();

      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('SELL'), findsOneWidget);
      expect(find.text('Projected Order Value'), findsOneWidget);
    },
  );

  testWidgets('Opening StockPickerSheet allows adding instruments', (
    WidgetTester tester,
  ) async {
    final singleStockWatchlist = [
      const Watchlist(id: 'w_single', name: 'Single Stock', symbols: ['TCS']),
    ];

    await tester.pumpWidget(
      createSubject(initialWatchlists: singleStockWatchlist),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Stocks'));
    await tester.pumpAndSettle();

    expect(find.text('Add Instruments'), findsOneWidget);
    expect(find.text('RELIANCE'), findsOneWidget);

    final addIcon = find.byIcon(Icons.add_circle_outline).first;
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('RELIANCE'), findsOneWidget);
  });

  testWidgets(
    'Creating a new watchlist switches to it and adding stocks maintains current tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createSubject(initialWatchlists: sampleWatchlists),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.text('New Watchlist'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'My Growth Stocks');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('My Growth Stocks'), findsOneWidget);
      expect(find.text('Watchlist is Empty'), findsOneWidget);

      await tester.tap(find.text('Add Stocks').first);
      await tester.pumpAndSettle();

      expect(find.text('Add Instruments'), findsOneWidget);

      final addIcon = find.byIcon(Icons.add_circle_outline).first;
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('My Growth Stocks'), findsOneWidget);
      expect(find.text('Watchlist is Empty'), findsNothing);
    },
  );

  testWidgets('User can delete any and all watchlists down to zero', (
    WidgetTester tester,
  ) async {
    final singleWatchlist = [
      const Watchlist(id: 'w_only', name: 'Sole Watchlist', symbols: ['TCS']),
    ];

    await tester.pumpWidget(createSubject(initialWatchlists: singleWatchlist));
    await tester.pumpAndSettle();

    expect(find.text('Sole Watchlist'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Delete Watchlist'), findsOneWidget);
    await tester.tap(find.text('Delete Watchlist'));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No Watchlists Created'), findsOneWidget);
  });

  testWidgets('Creating a watchlist from empty state works properly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('No Watchlists Created'), findsOneWidget);
    await tester.tap(find.text('Create Watchlist'));
    await tester.pumpAndSettle();

    expect(find.text('New Watchlist'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tech Leaders');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Tech Leaders'), findsOneWidget);
    expect(find.text('Watchlist is Empty'), findsOneWidget);
  });
}
