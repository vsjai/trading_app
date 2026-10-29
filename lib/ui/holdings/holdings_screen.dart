import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/portfolio_providers.dart';
import '../../state/theme_provider.dart';
import 'holding_row_tile.dart';
import 'portfolio_summary_card.dart';

class HoldingsScreen extends ConsumerWidget {
  final VoidCallback? onExploreTap;

  const HoldingsScreen({super.key, this.onExploreTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final sortedHoldings = ref.watch(sortedHoldingsProvider);
    final criteria = ref.watch(holdingsSortCriteriaProvider);
    final isAscending = ref.watch(holdingsSortAscendingProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Portfolio & Holdings')),
      body: Column(
        children: [
          const PortfolioSummaryCard(),
          if (sortedHoldings.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard.withValues(alpha: 0.35),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Sort by:',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSortChip(
                    label: 'P&L',
                    targetCriteria: HoldingsSortCriteria.pnl,
                    currentCriteria: criteria,
                    isAscending: isAscending,
                    ref: ref,
                  ),
                  const SizedBox(width: 6),
                  _buildSortChip(
                    label: 'Symbol',
                    targetCriteria: HoldingsSortCriteria.symbol,
                    currentCriteria: criteria,
                    isAscending: isAscending,
                    ref: ref,
                  ),
                  const SizedBox(width: 6),
                  _buildSortChip(
                    label: 'Value',
                    targetCriteria: HoldingsSortCriteria.currentValue,
                    currentCriteria: criteria,
                    isAscending: isAscending,
                    ref: ref,
                  ),
                  const Spacer(),
                  Text(
                    '${sortedHoldings.length} Positions',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: sortedHoldings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 64,
                            color: AppTheme.textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Holdings Yet',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Execute Buy orders from your Watchlists or the Live Market to build and track your active positions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          if (onExploreTap != null) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: onExploreTap,
                              icon: const Icon(Icons.show_chart, size: 18),
                              label: const Text('Explore Market'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: sortedHoldings.length,
                    itemBuilder: (context, index) {
                      final holding = sortedHoldings[index];
                      return HoldingRowTile(
                        key: ValueKey('holding_row_${holding.symbol}'),
                        holding: holding,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required HoldingsSortCriteria targetCriteria,
    required HoldingsSortCriteria currentCriteria,
    required bool isAscending,
    required WidgetRef ref,
  }) {
    final isSelected = targetCriteria == currentCriteria;

    return InkWell(
      onTap: () {
        if (isSelected) {
          ref.read(holdingsSortAscendingProvider.notifier).state = !isAscending;
        } else {
          ref.read(holdingsSortCriteriaProvider.notifier).state =
              targetCriteria;
          ref.read(holdingsSortAscendingProvider.notifier).state = false;
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.16)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.border,
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 3),
              Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 11,
                color: AppTheme.primaryLight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
