import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/holding.dart';
import '../../state/market_providers.dart';
import '../common/price_flash_badge.dart';
import '../trade/buy_sell_ticket_sheet.dart';

class HoldingRowTile extends ConsumerWidget {
  final Holding holding;

  const HoldingRowTile({super.key, required this.holding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockMetadataProvider(holding.symbol));
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
                color: AppTheme.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          holding.symbol,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.border,
                              width: 0.7,
                            ),
                          ),
                          child: const Text(
                            'HOLDING',
                            style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${holding.quantity} shares • Avg: ${CurrencyFormatter.formatPaise(holding.avgCostPaise)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock?.name ?? holding.symbol,
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (quoteAsync.value != null)
                PriceFlashBadge(
                  key: ValueKey('holding_flash_${holding.symbol}'),
                  quote: quoteAsync.value!,
                ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.formatPaise(currentValue),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
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
                          fontSize: 11,
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
