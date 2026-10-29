import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../state/market_providers.dart';
import '../../state/portfolio_providers.dart';
import 'order_confirmation_dialog.dart';

class BuySellTicketSheet extends ConsumerStatefulWidget {
  final String symbol;
  final OrderSide initialSide;

  const BuySellTicketSheet({
    super.key,
    required this.symbol,
    this.initialSide = OrderSide.buy,
  });

  static Future<void> show(
    BuildContext context, {
    required String symbol,
    OrderSide initialSide = OrderSide.buy,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          BuySellTicketSheet(symbol: symbol, initialSide: initialSide),
    );
  }

  @override
  ConsumerState<BuySellTicketSheet> createState() => _BuySellTicketSheetState();
}

class _BuySellTicketSheetState extends ConsumerState<BuySellTicketSheet> {
  late OrderSide _side;
  final TextEditingController _qtyController = TextEditingController(text: '1');
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  int get _parsedQuantity {
    final text = _qtyController.text.trim();
    if (text.isEmpty) return 0;
    return int.tryParse(text) ?? 0;
  }

  void _updateQuantity(int delta) {
    final current = _parsedQuantity;
    final next = (current + delta).clamp(1, 100000);
    _qtyController.text = next.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stock = ref.watch(stockMetadataProvider(widget.symbol));
    final quoteAsync = ref.watch(stockQuoteProvider(widget.symbol));
    final walletBalancePaise = ref.watch(walletProvider);
    final holding = ref.watch(holdingForSymbolProvider(widget.symbol));
    final heldQty = holding?.quantity ?? 0;

    final feedService = ref.read(marketFeedServiceProvider);
    final fallbackQuote = feedService.getLatestQuote(widget.symbol);
    final currentLtpPaise =
        quoteAsync.value?.ltpPaise ??
        fallbackQuote?.ltpPaise ??
        stock?.basePricePaise ??
        100000;
    final currentChangePaise =
        quoteAsync.value?.changePaise ?? fallbackQuote?.changePaise ?? 0;
    final currentChangePercent =
        quoteAsync.value?.changePercent ?? fallbackQuote?.changePercent ?? 0.0;

    final qty = _parsedQuantity;
    final int projectedOrderValuePaise = qty * currentLtpPaise;

    String? validationError;
    final rawText = _qtyController.text.trim();
    if (rawText.isEmpty) {
      validationError = 'Please enter a quantity.';
    } else if (rawText.contains('.') ||
        rawText.contains('-') ||
        rawText.contains(',')) {
      validationError = 'Quantity must be a positive whole number.';
    } else if (qty <= 0) {
      validationError = 'Quantity must be at least 1.';
    } else if (_side == OrderSide.buy &&
        projectedOrderValuePaise > walletBalancePaise) {
      validationError =
          'Insufficient margin. Available: ${CurrencyFormatter.formatPaise(walletBalancePaise)}, Order requires: ${CurrencyFormatter.formatPaise(projectedOrderValuePaise)}';
    } else if (_side == OrderSide.sell && qty > heldQty) {
      validationError =
          'Cannot sell $qty shares. You currently hold $heldQty shares of ${widget.symbol}.';
    }

    final isBuy = _side == OrderSide.buy;
    final activeThemeColor = isBuy ? AppTheme.bullGreen : AppTheme.bearRed;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.symbol,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              'NSE',
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stock?.name ?? widget.symbol,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatPaise(currentLtpPaise),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.formatSignedPaise(currentChangePaise)} (${CurrencyFormatter.formatPercentage(currentChangePercent)})',
                        style: TextStyle(
                          color: currentChangePaise >= 0
                              ? AppTheme.bullGreen
                              : AppTheme.bearRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _side = OrderSide.buy),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isBuy
                                ? AppTheme.bullGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'BUY',
                            style: TextStyle(
                              color: isBuy
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _side = OrderSide.sell),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isBuy
                                ? AppTheme.bearRed
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'SELL',
                            style: TextStyle(
                              color: !isBuy
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isBuy
                        ? 'Margin Avail: ${CurrencyFormatter.formatPaise(walletBalancePaise)}'
                        : 'Holdings: $heldQty shares',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateQuantity(-1),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.textSecondary,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceCard,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: activeThemeColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateQuantity(1),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickQtyPill('+5', 5),
                  const SizedBox(width: 8),
                  _buildQuickQtyPill('+10', 10),
                  const SizedBox(width: 8),
                  _buildQuickQtyPill('+25', 25),
                  if (!isBuy && heldQty > 0) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        _qtyController.text = heldQty.toString();
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Text(
                          'MAX',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Projected Order Value',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPaise(projectedOrderValuePaise),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (validationError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bearRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.bearRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.bearRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          validationError,
                          style: const TextStyle(
                            color: AppTheme.bearRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (validationError != null || _isSubmitting)
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);

                          final latestQuote = ref
                              .read(marketFeedServiceProvider)
                              .getLatestQuote(widget.symbol);
                          final sampledPrice =
                              latestQuote?.ltpPaise ?? currentLtpPaise;

                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          final result = await ref
                              .read(tradingServiceProvider)
                              .executeMarketOrder(
                                symbol: widget.symbol,
                                side: _side,
                                quantity: qty,
                                sampledPricePaise: sampledPrice,
                              );

                          if (!mounted) return;
                          setState(() => _isSubmitting = false);

                          if (result.isSuccess && result.order != null) {
                            final updatedWallet = ref.read(walletProvider);
                            nav.pop();
                            OrderConfirmationDialog.show(
                              nav.context,
                              order: result.order!,
                              remainingBalancePaise: updatedWallet,
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.errorMessage ?? 'Execution failed',
                                ),
                                backgroundColor: AppTheme.bearRed,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeThemeColor,
                    disabledBackgroundColor: AppTheme.surfaceCard,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppTheme.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '${isBuy ? 'BUY' : 'SELL'} ${widget.symbol} • ${CurrencyFormatter.formatPaise(projectedOrderValuePaise)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQtyPill(String label, int amount) {
    return InkWell(
      onTap: () => _updateQuantity(amount),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
