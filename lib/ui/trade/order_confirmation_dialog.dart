import 'package:flutter/material.dart';
import '../../models/order.dart';
import 'order_confirmation_screen.dart';

export 'order_confirmation_screen.dart';

class OrderConfirmationDialog {
  OrderConfirmationDialog._();

  static Future<void> show(
    BuildContext context, {
    required StockOrder order,
    required int remainingBalancePaise,
  }) {
    return OrderConfirmationScreen.show(
      context,
      order: order,
      remainingBalancePaise: remainingBalancePaise,
    );
  }
}
