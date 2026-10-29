import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../state/portfolio_providers.dart';
import '../../state/theme_provider.dart';

class PortfolioSummaryCard extends ConsumerWidget {
  const PortfolioSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final summary = ref.watch(portfolioSummaryProvider);
    final isProfit = summary.totalPnlPaise >= 0;
    final pnlColor = isProfit ? AppTheme.bullGreen : AppTheme.bearRed;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total P&L',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pnlColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: pnlColor,
                      size: 16,
                    ),
                    Text(
                      CurrencyFormatter.formatPercentage(
                        summary.totalPnlPercent,
                      ),
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatSignedPaise(summary.totalPnlPaise),
            style: TextStyle(
              color: pnlColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Divider(color: AppTheme.border, height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  label: 'Invested',
                  value: CurrencyFormatter.formatPaise(
                    summary.totalInvestedPaise,
                  ),
                ),
              ),
              Expanded(
                child: _buildMetricCol(
                  label: 'Current Value',
                  value: CurrencyFormatter.formatPaise(
                    summary.totalCurrentValuePaise,
                  ),
                ),
              ),
              Expanded(
                child: _buildMetricCol(
                  label: 'Available Cash',
                  value: CurrencyFormatter.formatPaise(
                    summary.walletBalancePaise,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
