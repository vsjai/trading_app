import 'package:flutter/material.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';

class OrderConfirmationDialog extends StatelessWidget {
  final StockOrder order;
  final int remainingBalancePaise;

  const OrderConfirmationDialog({
    super.key,
    required this.order,
    required this.remainingBalancePaise,
  });

  static Future<void> show(
    BuildContext context, {
    required StockOrder order,
    required int remainingBalancePaise,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderConfirmationDialog(
        order: order,
        remainingBalancePaise: remainingBalancePaise,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final sideColor = isBuy ? AppTheme.bullGreen : AppTheme.bearRed;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: sideColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: sideColor, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Order Completed',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.id,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _buildReceiptRow(
                  label: 'Instrument',
                  value: order.symbol,
                  valueStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReceiptRow(
                  label: 'Action',
                  value: isBuy ? 'BUY' : 'SELL',
                  valueStyle: TextStyle(
                    color: sideColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReceiptRow(
                  label: 'Quantity',
                  value: '${order.quantity} shares',
                ),
                const SizedBox(height: 8),
                _buildReceiptRow(
                  label: 'Executed Price',
                  value: CurrencyFormatter.formatPaise(order.pricePaise),
                ),
                const Divider(color: AppTheme.border, height: 20),
                _buildReceiptRow(
                  label: isBuy ? 'Total Debited' : 'Total Credited',
                  value: CurrencyFormatter.formatPaise(order.totalValuePaise),
                  valueStyle: TextStyle(
                    color: isBuy ? AppTheme.textPrimary : AppTheme.bullGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReceiptRow(
                  label: 'Wallet Balance',
                  value: CurrencyFormatter.formatPaise(remainingBalancePaise),
                  valueStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style:
              valueStyle ??
              const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}
