import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/models/holding.dart';
import 'package:trading_app/services/market_feed_service.dart';
import 'package:trading_app/services/storage_service.dart';
import 'package:trading_app/state/market_providers.dart';
import 'package:trading_app/state/storage_providers.dart';
import 'package:trading_app/ui/trade/buy_sell_ticket_sheet.dart';

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

  Widget createSubject({
    String symbol = 'RELIANCE',
    List<Holding>? initialHoldings,
    int? initialWallet,
  }) {
    if (initialHoldings != null) {
      testStorage.saveHoldings(initialHoldings);
    }
    if (initialWallet != null) {
      testStorage.saveWalletBalance(initialWallet);
    }

    return ProviderScope(
      overrides: [
        marketFeedServiceProvider.overrideWithValue(testFeed),
        storageServiceProvider.overrideWithValue(testStorage),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    BuySellTicketSheet.show(context, symbol: symbol),
                child: const Text('Open Ticket'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets(
    'BuySellTicketSheet displays preselected stock, LTP, and projected value',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject(symbol: 'INFY'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Ticket'));
      await tester.pumpAndSettle();

      expect(find.text('INFY'), findsOneWidget);
      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('SELL'), findsOneWidget);
      expect(find.text('Projected Order Value'), findsOneWidget);
      expect(find.textContaining('Margin Avail:'), findsOneWidget);
    },
  );

  testWidgets('Quantity changes update projected order value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject(symbol: 'SBIN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Ticket'));
    await tester.pumpAndSettle();

    // Increment quantity by 1 via + icon button
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // Input text field should now show '2'
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Displays inline error when BUY value exceeds margin', (
    WidgetTester tester,
  ) async {
    // Starting with small wallet: ₹500 (50,000 paise)
    await tester.pumpWidget(
      createSubject(symbol: 'RELIANCE', initialWallet: 50000),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Ticket'));
    await tester.pumpAndSettle();

    // RELIANCE is ~₹2,950, so 1 share exceeds ₹500
    expect(find.textContaining('Insufficient margin'), findsOneWidget);
  });

  testWidgets('Displays inline error on SELL when user holds 0 shares', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject(symbol: 'TCS', initialHoldings: []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Ticket'));
    await tester.pumpAndSettle();

    // Switch to SELL
    await tester.tap(find.text('SELL'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cannot sell 1 shares. You currently hold 0 shares'),
      findsOneWidget,
    );
  });

  testWidgets('Submitting valid BUY order shows OrderConfirmationDialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createSubject(symbol: 'ITC'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Ticket'));
    await tester.pumpAndSettle();

    // Tap submit button (BUY ITC)
    final submitButton = find.widgetWithText(
      ElevatedButton,
      'BUY ITC • ₹435.25',
    );
    expect(submitButton, findsOneWidget);

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Order Completed'), findsOneWidget);
    expect(find.text('Instrument'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);

    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();

    expect(find.text('Order Completed'), findsNothing);
  });
}
