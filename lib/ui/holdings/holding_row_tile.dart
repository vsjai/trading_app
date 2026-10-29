import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/holding.dart';
import '../../models/stock_quote.dart';
import '../../state/market_providers.dart';
import '../trade/buy_sell_ticket_sheet.dart';

class HoldingRowTile extends ConsumerWidget {
  final Holding holding;

  const HoldingRowTile({super.key, required this.holding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(stockQuoteProvider(holding.symbol));
    final feedService = ref.read(marketFeedServiceProvider);

    final latestQuote = feedService.getLatestQuote(holding.symbol);
    final ltpPaise =
        quoteAsync.value?.ltpPaise ??
        latestQuote?.ltpPaise ??
        holding.avgCostPaise;

    final currentValue = holding.currentValuePaise(ltpPaise);
    final pnl = holding.pnlPaise(ltpPaise);
    final pnlPercent = holding.pnlPercent(ltpPaise);
    final isProfit = pnl >= 0;
    final pnlColor = isProfit ? AppTheme.bullGreen : AppTheme.bearRed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => BuySellTicketSheet.show(context, symbol: holding.symbol),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        holding.symbol,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
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
                        ),
                        child: Text(
                          '${holding.quantity} shares',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.formatPaise(currentValue),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Avg: ${CurrencyFormatter.formatPaise(holding.avgCostPaise)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LTP: ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      HoldingLiveLtpText(
                        key: ValueKey('holding_ltp_${holding.symbol}'),
                        ltpPaise: ltpPaise,
                        direction:
                            quoteAsync.value?.direction ?? PriceDirection.none,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isProfit ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: pnlColor,
                        size: 16,
                      ),
                      Text(
                        '${CurrencyFormatter.formatSignedPaise(pnl)} (${CurrencyFormatter.formatPercentage(pnlPercent)})',
                        style: TextStyle(
                          color: pnlColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoldingLiveLtpText extends StatefulWidget {
  final int ltpPaise;
  final PriceDirection direction;

  const HoldingLiveLtpText({
    super.key,
    required this.ltpPaise,
    required this.direction,
  });

  @override
  State<HoldingLiveLtpText> createState() => _HoldingLiveLtpTextState();
}

class _HoldingLiveLtpTextState extends State<HoldingLiveLtpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1850),
    );
    _colorAnimation = ColorTween(
      begin: AppTheme.textPrimary,
      end: AppTheme.textPrimary,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(HoldingLiveLtpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ltpPaise != widget.ltpPaise) {
      final Color flashColor = widget.direction == PriceDirection.up
          ? AppTheme.bullGreen
          : (widget.direction == PriceDirection.down
                ? AppTheme.bearRed
                : AppTheme.textPrimary);

      _colorAnimation = ColorTween(begin: flashColor, end: AppTheme.textPrimary)
          .animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.81, 1.0, curve: Curves.easeOut),
            ),
          );

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          CurrencyFormatter.formatPaise(widget.ltpPaise),
          style: TextStyle(
            color: _controller.isAnimating
                ? (_colorAnimation.value ?? AppTheme.textPrimary)
                : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
