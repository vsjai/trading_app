import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/market_providers.dart';
import '../../state/watchlist_providers.dart';

class StockPickerSheet extends ConsumerStatefulWidget {
  final String watchlistId;

  const StockPickerSheet({super.key, required this.watchlistId});

  static Future<void> show(BuildContext context, String watchlistId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StockPickerSheet(watchlistId: watchlistId),
    );
  }

  @override
  ConsumerState<StockPickerSheet> createState() => _StockPickerSheetState();
}

class _StockPickerSheetState extends ConsumerState<StockPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStocks = ref.watch(allStocksProvider);
    final watchlists = ref.watch(watchlistsProvider);
    final currentWatchlist = watchlists.firstWhere(
      (w) => w.id == widget.watchlistId,
      orElse: () => watchlists.first,
    );
    final existingSymbols = currentWatchlist.symbols.toSet();

    final filtered = allStocks.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.symbol.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
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
                      Text(
                        'Add Instruments',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'To "${currentWatchlist.name}" (${existingSymbols.length}/10 added)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val.trim()),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search 10 available stocks...',
                  hintStyle: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
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
                    borderSide: const BorderSide(
                      color: AppTheme.primaryLight,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: AppTheme.border, height: 1),
                  itemBuilder: (context, index) {
                    final stock = filtered[index];
                    final isAdded = existingSymbols.contains(stock.symbol);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      title: Text(
                        stock.symbol,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        stock.name,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isAdded
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: isAdded
                              ? AppTheme.bullGreen
                              : AppTheme.primaryLight,
                          size: 24,
                        ),
                        onPressed: () {
                          if (isAdded) {
                            ref
                                .read(watchlistsProvider.notifier)
                                .removeStockFromWatchlist(
                                  widget.watchlistId,
                                  stock.symbol,
                                );
                          } else {
                            ref
                                .read(watchlistsProvider.notifier)
                                .addStockToWatchlist(
                                  widget.watchlistId,
                                  stock.symbol,
                                );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
