import 'package:flutter/material.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_quote.dart';

class PriceFlashBadge extends StatefulWidget {
  final StockQuote quote;

  const PriceFlashBadge({super.key, required this.quote});

  @override
  State<PriceFlashBadge> createState() => _PriceFlashBadgeState();
}

class _PriceFlashBadgeState extends State<PriceFlashBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _textColorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1850),
    );
    _textColorAnimation = ColorTween(
      begin: AppTheme.textPrimary,
      end: AppTheme.textPrimary,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(PriceFlashBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quote.ltpPaise != widget.quote.ltpPaise) {
      final Color flashColor = widget.quote.direction == PriceDirection.up
          ? AppTheme.bullGreen
          : (widget.quote.direction == PriceDirection.down
                ? AppTheme.bearRed
                : AppTheme.textPrimary);

      _textColorAnimation =
          ColorTween(begin: flashColor, end: AppTheme.textPrimary).animate(
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
    final isUp = widget.quote.changePaise >= 0;
    final changeColor = isUp ? AppTheme.bullGreen : AppTheme.bearRed;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.formatPaise(widget.quote.ltpPaise),
                style: TextStyle(
                  color: _textColorAnimation.value ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: changeColor,
                    size: 16,
                  ),
                  Text(
                    '${CurrencyFormatter.formatSignedPaise(widget.quote.changePaise)} (${CurrencyFormatter.formatPercentage(widget.quote.changePercent)})',
                    style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: -0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
