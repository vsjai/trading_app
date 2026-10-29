import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/market_feed_service.dart';
import '../../state/market_providers.dart';

class TickRateControlSheet extends ConsumerWidget {
  const TickRateControlSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const TickRateControlSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(tickRateModeProvider);
    final feedService = ref.watch(marketFeedServiceProvider);

    return SafeArea(
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
                const Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: AppTheme.primaryLight,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Market Feed Simulation Speed',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Control the live tick rate to evaluate performance, high-throughput reactivity, and UI frame stability under stress.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              context: context,
              ref: ref,
              mode: TickRateMode.normal,
              title: 'Standard Market Pace',
              subtitle: 'Realistic simulation (~1-2 ticks/sec distributed)',
              badgeText: 'Default',
              badgeColor: AppTheme.primaryLight,
              isSelected: currentMode == TickRateMode.normal,
            ),
            const SizedBox(height: 10),
            _buildOptionTile(
              context: context,
              ref: ref,
              mode: TickRateMode.active,
              title: 'Active Trading Day',
              subtitle: 'Moderate volume (~10 ticks/sec overall)',
              badgeText: '10 ticks/s',
              badgeColor: Colors.amber,
              isSelected: currentMode == TickRateMode.active,
            ),
            const SizedBox(height: 10),
            _buildOptionTile(
              context: context,
              ref: ref,
              mode: TickRateMode.stress,
              title: 'Stress Test (High Load)',
              subtitle: '5+ ticks/sec/stock (55+ ticks/sec total throughput)',
              badgeText: 'Stress 55+/s',
              badgeColor: AppTheme.bearRed,
              isSelected: currentMode == TickRateMode.stress,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    feedService.isRunning
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    color: feedService.isRunning
                        ? AppTheme.bullGreen
                        : Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Feed Status: ${feedService.isRunning ? "Emitting live ticks across 10 stocks" : "Paused"}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required WidgetRef ref,
    required TickRateMode mode,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(tickRateModeProvider.notifier).setMode(mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
