import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_quote.dart';
import '../../state/market_providers.dart';
import '../common/price_flash_badge.dart';
import '../trade/trade_ticket_stub.dart';

class WatchlistStockRow extends ConsumerWidget {
  final String watchlistId;
  final String symbol;
  final int index;
  final VoidCallback onRemove;

  const WatchlistStockRow({
    super.key,
    required this.watchlistId,
    required this.symbol,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockMetadataProvider(symbol));
    final quoteAsync = ref.watch(stockQuoteProvider(symbol));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TradeTicketStub.show(context, symbol),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.drag_indicator,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          symbol,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 3),
                    Text(
                      stock?.name ?? symbol,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              quoteAsync.when(
                data: (quote) => PriceFlashBadge(
                  key: ValueKey('flash_${watchlistId}_$symbol'),
                  quote: quote,
                ),
                loading: () {
                  final initialQuote = ref
                      .read(marketFeedServiceProvider)
                      .getLatestQuote(symbol);
                  if (initialQuote != null) {
                    return PriceFlashBadge(
                      key: ValueKey('flash_${watchlistId}_$symbol'),
                      quote: initialQuote,
                    );
                  }
                  return const SizedBox(
                    width: 60,
                    height: 24,
                    child: Center(
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  );
                },
                error: (_, _) => PriceFlashBadge(
                  key: ValueKey('flash_${watchlistId}_$symbol'),
                  quote: StockQuote.compute(
                    symbol: symbol,
                    ltpPaise: stock?.basePricePaise ?? 100000,
                    previousClosePaise: stock?.previousClosePaise ?? 100000,
                    direction: PriceDirection.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.textTertiary,
                  size: 19,
                ),
                tooltip: 'Remove from watchlist',
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
