import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/watchlist.dart';
import '../../state/theme_provider.dart';
import '../../state/watchlist_providers.dart';
import 'stock_picker_sheet.dart';
import 'watchlist_stock_row.dart';

class WatchlistsScreen extends ConsumerStatefulWidget {
  const WatchlistsScreen({super.key});

  @override
  ConsumerState<WatchlistsScreen> createState() => _WatchlistsScreenState();
}

class _WatchlistsScreenState extends ConsumerState<WatchlistsScreen> {
  void _showCreateWatchlistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.border),
          ),
          title: Text(
            'New Watchlist',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Bluechip Leaders',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final newId = await ref
                      .read(watchlistsProvider.notifier)
                      .createWatchlist(name);
                  ref.read(activeWatchlistIdProvider.notifier).state = newId;
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(Watchlist watchlist) {
    final controller = TextEditingController(text: watchlist.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.border),
          ),
          title: Text(
            'Rename Watchlist',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(watchlistsProvider.notifier)
                      .renameWatchlist(watchlist.id, name);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteWatchlist(Watchlist watchlist) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.border),
          ),
          title: Text(
            'Delete Watchlist',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${watchlist.name}"? This action cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(watchlistsProvider.notifier)
                    .deleteWatchlist(watchlist.id);
                final remaining = ref.read(watchlistsProvider);
                ref.read(activeWatchlistIdProvider.notifier).state =
                    remaining.isNotEmpty ? remaining.first.id : null;
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bearRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final watchlists = ref.watch(watchlistsProvider);
    final activeId = ref.watch(activeWatchlistIdProvider);

    final activeWatchlist = watchlists.firstWhere(
      (w) => w.id == activeId,
      orElse: () => watchlists.isNotEmpty
          ? watchlists.first
          : const Watchlist(id: 'fallback', name: 'Watchlist', symbols: []),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Watchlists'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.textPrimary),
            tooltip: 'Create New Watchlist',
            onPressed: _showCreateWatchlistDialog,
          ),
          if (watchlists.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
              color: AppTheme.surfaceCard,
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(activeWatchlist);
                } else if (value == 'delete') {
                  _confirmDeleteWatchlist(activeWatchlist);
                } else if (value == 'add_stock') {
                  StockPickerSheet.show(context, activeWatchlist.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'add_stock',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.primaryLight,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add Instruments',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Rename Watchlist',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: AppTheme.bearRed,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delete Watchlist',
                        style: TextStyle(color: AppTheme.bearRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: watchlists.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.format_list_bulleted_add,
                        size: 56,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Watchlists Created',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create custom watchlists to track your favorite stocks in real time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showCreateWatchlistDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Watchlist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard.withValues(alpha: 0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    itemCount: watchlists.length + 1,
                    itemBuilder: (context, index) {
                      if (index == watchlists.length) {
                        return InkWell(
                          onTap: _showCreateWatchlistDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.border.withValues(alpha: 0.7),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 15,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'New',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final watchlist = watchlists[index];
                      final isSelected = watchlist.id == activeWatchlist.id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            ref.read(activeWatchlistIdProvider.notifier).state =
                                watchlist.id;
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.2)
                                  : AppTheme.surfaceCard.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.8)
                                    : AppTheme.border.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              watchlist.name,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryLight
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard.withValues(alpha: 0.4),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${activeWatchlist.symbols.length} Instruments • Drag handle to reorder',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            StockPickerSheet.show(context, activeWatchlist.id),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 14,
                                color: AppTheme.primaryLight,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add Stocks',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: activeWatchlist.symbols.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 56,
                                  color: AppTheme.textTertiary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Watchlist is Empty',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add instruments from the 10 available stocks to track live prices and execute trades.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => StockPickerSheet.show(
                                    context,
                                    activeWatchlist.id,
                                  ),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Stocks'),
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
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: activeWatchlist.symbols.length,
                          onReorder: (oldIndex, newIndex) {
                            ref
                                .read(watchlistsProvider.notifier)
                                .reorderStocks(
                                  activeWatchlist.id,
                                  oldIndex,
                                  newIndex,
                                );
                          },
                          itemBuilder: (context, index) {
                            final symbol = activeWatchlist.symbols[index];
                            return WatchlistStockRow(
                              key: ValueKey(
                                'watchlist_${activeWatchlist.id}_item_$symbol',
                              ),
                              watchlistId: activeWatchlist.id,
                              symbol: symbol,
                              index: index,
                              onRemove: () {
                                ref
                                    .read(watchlistsProvider.notifier)
                                    .removeStockFromWatchlist(
                                      activeWatchlist.id,
                                      symbol,
                                    );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
