import 'package:flutter/material.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final StockOrder order;
  final int remainingBalancePaise;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.remainingBalancePaise,
  });

  static Future<void> show(
    BuildContext context, {
    required StockOrder order,
    required int remainingBalancePaise,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          order: order,
          remainingBalancePaise: remainingBalancePaise,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final sideColor = isBuy ? AppTheme.bullGreen : AppTheme.bearRed;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Order Status',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: AppTheme.textPrimary),
            tooltip: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppTheme.bullGreen.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.bullGreen.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.bullGreen,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order Completed',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.bullGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Executed on NSE',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instrument',
                                    style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        order.symbol,
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'NSE',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: sideColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sideColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Text(
                                  isBuy ? 'BUY' : 'SELL',
                                  style: TextStyle(
                                    color: sideColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: AppTheme.border.withValues(alpha: 0.5),
                            height: 24,
                          ),
                          _buildDetailRow(
                            label: 'Quantity',
                            value: '${order.quantity} shares',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: 'Executed Price',
                            value: CurrencyFormatter.formatPaise(
                              order.pricePaise,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: 'Order Type',
                            value: 'Market Order',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: isBuy ? 'Total Debited' : 'Total Credited',
                            value: CurrencyFormatter.formatPaise(
                              order.totalValuePaise,
                            ),
                            valueColor: isBuy
                                ? AppTheme.textPrimary
                                : AppTheme.bullGreen,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            label: 'Order ID',
                            value: order.id,
                            isMonospace: true,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: 'Execution Time',
                            value: _formatTimestamp(order.timestamp),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: 'Available Wallet Cash',
                            value: CurrencyFormatter.formatPaise(
                              remainingBalancePaise,
                            ),
                            valueColor: AppTheme.textPrimary,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Okay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            fontFeatures: isMonospace
                ? const [FontFeature.tabularFigures()]
                : null,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute:$second';
  }
}
