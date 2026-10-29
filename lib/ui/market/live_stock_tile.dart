import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock.dart';
import '../../models/stock_quote.dart';
import '../../state/market_providers.dart';
import '../common/price_flash_badge.dart';

class LiveStockTile extends ConsumerWidget {
  final Stock stock;
  final VoidCallback? onTap;

  const LiveStockTile({super.key, required this.stock, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(stockQuoteProvider(stock.symbol));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          stock.symbol,
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
                      stock.name,
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
              const SizedBox(width: 12),
              quoteAsync.when(
                data: (quote) => PriceFlashBadge(
                  key: ValueKey('flash_${stock.symbol}'),
                  quote: quote,
                ),
                loading: () {
                  final initialQuote = ref
                      .read(marketFeedServiceProvider)
                      .getLatestQuote(stock.symbol);
                  if (initialQuote != null) {
                    return PriceFlashBadge(
                      key: ValueKey('flash_${stock.symbol}'),
                      quote: initialQuote,
                    );
                  }
                  return const SizedBox(
                    width: 70,
                    height: 28,
                    child: Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  );
                },
                error: (_, _) => PriceFlashBadge(
                  key: ValueKey('flash_${stock.symbol}'),
                  quote: StockQuote.compute(
                    symbol: stock.symbol,
                    ltpPaise: stock.basePricePaise,
                    previousClosePaise: stock.previousClosePaise,
                    direction: PriceDirection.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
