import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/market_feed_service.dart';
import '../../state/market_providers.dart';
import 'live_stock_tile.dart';
import 'tick_rate_control_sheet.dart';

class MarketOverviewScreen extends ConsumerWidget {
  const MarketOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocks = ref.watch(allStocksProvider);
    final tickMode = ref.watch(tickRateModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Live Market'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => TickRateControlSheet.show(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tickMode == TickRateMode.stress
                      ? AppTheme.bearRed.withValues(alpha: 0.18)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tickMode == TickRateMode.stress
                        ? AppTheme.bearRed
                        : AppTheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tickMode == TickRateMode.stress
                          ? Icons.local_fire_department
                          : Icons.speed,
                      size: 14,
                      color: tickMode == TickRateMode.stress
                          ? AppTheme.bearRed
                          : AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tickMode == TickRateMode.stress
                          ? 'STRESS 55/s'
                          : (tickMode == TickRateMode.active
                                ? '10/s'
                                : 'Normal'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tickMode == TickRateMode.stress
                            ? AppTheme.bearRed
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.border.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.bullGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MARKET LIVE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${stocks.length} Instruments',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                return LiveStockTile(
                  key: ValueKey('stock_tile_${stock.symbol}'),
                  stock: stock,
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
