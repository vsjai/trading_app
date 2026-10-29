import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/theme/app_theme.dart';
import 'package:trading_app/models/order.dart';
import 'package:trading_app/ui/trade/order_confirmation_screen.dart';

void main() {
  final sampleBuyOrder = StockOrder(
    id: 'ORD-BUY-101',
    symbol: 'RELIANCE',
    side: OrderSide.buy,
    quantity: 10,
    pricePaise: 295050,
    totalValuePaise: 2950500,
    status: OrderStatus.completed,
    timestamp: DateTime(2026, 10, 30, 10, 30, 0),
  );

  final sampleSellOrder = StockOrder(
    id: 'ORD-SELL-202',
    symbol: 'TCS',
    side: OrderSide.sell,
    quantity: 5,
    pricePaise: 384500,
    totalValuePaise: 1922500,
    status: OrderStatus.completed,
    timestamp: DateTime(2026, 10, 30, 11, 15, 0),
  );

  Widget createSubject(StockOrder order, int remainingWallet) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  OrderConfirmationScreen.show(
                    context,
                    order: order,
                    remainingBalancePaise: remainingWallet,
                  );
                },
                child: const Text('Show Receipt'),
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets(
    'OrderConfirmationScreen displays complete Kite/Groww details for BUY order',
    (tester) async {
      await tester.pumpWidget(createSubject(sampleBuyOrder, 47049500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('Order Status'), findsOneWidget);
      expect(find.text('Order Completed'), findsOneWidget);
      expect(find.text('Executed on NSE'), findsOneWidget);
      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('NSE'), findsOneWidget);
      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('10 shares'), findsOneWidget);
      expect(find.text('₹2,950.50'), findsOneWidget);
      expect(find.text('Total Debited'), findsOneWidget);
      expect(find.text('₹29,505.00'), findsOneWidget);
      expect(find.text('ORD-BUY-101'), findsOneWidget);
      expect(find.text('₹4,70,495.00'), findsOneWidget);
      expect(find.text('Okay'), findsOneWidget);
    },
  );

  testWidgets('OrderConfirmationScreen displays SELL order details correctly', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject(sampleSellOrder, 51922500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('TCS'), findsOneWidget);
    expect(find.text('SELL'), findsOneWidget);
    expect(find.text('5 shares'), findsOneWidget);
    expect(find.text('Total Credited'), findsOneWidget);
    expect(find.text('₹19,225.00'), findsOneWidget);
  });

  testWidgets('Dismisses screen on tapping Okay button', (tester) async {
    await tester.pumpWidget(createSubject(sampleBuyOrder, 50000000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Order Completed'), findsOneWidget);

    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();

    expect(find.text('Order Completed'), findsNothing);
    expect(find.text('Show Receipt'), findsOneWidget);
  });

  testWidgets('Dismisses screen on tapping top Cancel button', (tester) async {
    await tester.pumpWidget(createSubject(sampleBuyOrder, 50000000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Order Completed'), findsOneWidget);

    final cancelBtn = find.byTooltip('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    expect(find.text('Order Completed'), findsNothing);
    expect(find.text('Show Receipt'), findsOneWidget);
  });

  testWidgets('Dismisses screen on tapping top Back button', (tester) async {
    await tester.pumpWidget(createSubject(sampleBuyOrder, 50000000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Order Completed'), findsOneWidget);

    final backBtn = find.byTooltip('Back');
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Order Completed'), findsNothing);
    expect(find.text('Show Receipt'), findsOneWidget);
  });
}
