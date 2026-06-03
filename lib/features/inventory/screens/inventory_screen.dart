import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../services/search_service.dart';
import 'item_detail_screen.dart';
import 'barcode_scanner.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Inventory Screen
// ─────────────────────────────────────────────────────────────────────────────

/// The main screen users return to daily.
///
/// Features:
/// - Live search bar (hybrid semantic + full-text via [SearchService])
/// - Category filter chips (horizontal scroll)
/// - Sort dropdown (name / quantity / date)
/// - Animated item list with swipe-to-delete and quantity +/− buttons
/// - Shimmer skeleton while loading
/// - Illustrated empty state
/// - FAB to add an item manually
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  List<InventoryItem>? _searchResults;
  bool _isSearching = false;

  static const _categories = [
    'All',
    'produce',
    'dairy',
    'meat',
    'bakery',
    'frozen',
    'pantry',
    'beverage',
    'snack',
    'other',
  ];

  static const _sortOptions = {
    'Name (A–Z)':        ('item_name', true),
    'Name (Z–A)':        ('item_name', false),
    'Qty (Low–High)':    ('quantity',  true),
    'Qty (High–Low)':    ('quantity',  false),
    'Newest First':      ('created_at', false),
    'Oldest First':      ('created_at', true),
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = null; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    final results = await searchService.search(query);
    setState(() { _searchResults = results; _isSearching = false; });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() { _searchResults = null; _isSearching = false; });
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _deleteItem(InventoryItem item) async {
    // Optimistic: remove from UI immediately.
    ref.read(inventoryProvider.notifier).removeOptimistic(item.id);
    try {
      await supabase.from('items').delete().eq('id', item.id);
    } catch (_) {
      // If the delete fails, reload to restore the item.
      ref.read(inventoryProvider.notifier).reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to delete item. Please try again.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ── Quantity ───────────────────────────────────────────────────────────────

  Future<void> _adjustQuantity(InventoryItem item, int delta) async {
    final newQty = (item.quantity + delta).clamp(0, 9999);
    ref.read(inventoryProvider.notifier).adjustQuantityOptimistic(item.id, delta);
    try {
      await supabase.from('items').update({'quantity': newQty}).eq('id', item.id);
    } catch (_) {
      ref.read(inventoryProvider.notifier).reload();
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _openDetail(InventoryItem item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ItemDetailScreen(item: item),
    )).then((_) => ref.read(inventoryProvider.notifier).reload());
  }

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ItemDetailScreen(item: null),
    )).then((_) => ref.read(inventoryProvider.notifier).reload());
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);
    final filter = notifier.filter;

    final activeCategory = filter.category;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(activeCategory, notifier),
            _buildSortBar(filter, notifier),
            Expanded(
              child: _buildBody(itemsAsync),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.black,
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 12,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.edit_note_rounded),
            backgroundColor: AppColors.surfaceDark,
            foregroundColor: AppColors.green,
            label: 'Manual Input',
            labelStyle: const TextStyle(color: AppColors.textPrimary),
            labelBackgroundColor: AppColors.surfaceDark,
            onTap: () {
               // Open Item Detail screen completely blank
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const ItemDetailScreen(item: null)),
               );
            },
          ),
          if (!kIsWeb)
            SpeedDialChild(
              child: const Icon(Icons.qr_code_scanner_rounded),
              backgroundColor: AppColors.surfaceDark,
              foregroundColor: AppColors.green,
              label: 'Scan Barcode',
              labelStyle: const TextStyle(color: AppColors.textPrimary),
              labelBackgroundColor: AppColors.surfaceDark,
              onTap: () async {
                 // 1. Open scanner
                 final result = await Navigator.push(
                   context,
                   MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                 );

                 // 2. If barcode found, open Item Detail screen pre-filled!
                 if (result != null && context.mounted) {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => ItemDetailScreen(
                       item: null, // null means "Add Mode"
                       initialName: result['name'],
                       initialCategory: result['category'],
                     )),
                   );
                 }
              },
            ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Text('Inventory', style: AppTextStyles.headlineLarge),
          const Spacer(),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.read(inventoryProvider.notifier).reload(),
          ),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search items…',
          hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
          prefixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.green),
                  ),
                )
              : const Icon(Icons.search_rounded, color: AppColors.textMuted),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────

  Widget _buildCategoryChips(String? active, InventoryNotifier notifier) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isActive = (cat == 'All' && active == null) ||
              cat == active;
          return FilterChip(
            label: Text(
              _capitalize(cat),
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.black : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: isActive,
            onSelected: (_) =>
                notifier.setCategory(cat == 'All' ? null : cat),
            selectedColor: AppColors.green,
            backgroundColor: AppColors.surfaceDark,
            checkmarkColor: AppColors.black,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  // ── Sort bar ───────────────────────────────────────────────────────────────

  Widget _buildSortBar(InventoryFilter filter, InventoryNotifier notifier) {
    // Find current sort label.
    String currentLabel = 'Name (A–Z)';
    for (final entry in _sortOptions.entries) {
      if (entry.value.$1 == filter.sortBy &&
          entry.value.$2 == filter.ascending) {
        currentLabel = entry.key;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Text('Sort:', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            child: Row(
              children: [
                Text(currentLabel,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 18),
              ],
            ),
            color: AppColors.surfaceDark,
            itemBuilder: (_) => _sortOptions.keys
                .map((label) => PopupMenuItem(
                      value: label,
                      child: Text(label,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary)),
                    ))
                .toList(),
            onSelected: (label) {
              final (col, asc) = _sortOptions[label]!;
              notifier.setSort(col, ascending: asc);
            },
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(AsyncValue<List<InventoryItem>> itemsAsync) {
    // If we're in search mode, show search results instead.
    if (_searchResults != null) {
      return _searchResults!.isEmpty
          ? _buildEmptyState(isSearch: true)
          : _buildList(_searchResults!);
    }

    return itemsAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => _buildError(e),
      data: (items) =>
          items.isEmpty ? _buildEmptyState() : _buildList(items),
    );
  }

  // ── Item list ──────────────────────────────────────────────────────────────

  Widget _buildList(List<InventoryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ItemCard(
            key: ValueKey(item.id),
            item: item,
            onTap: () => _openDetail(item),
            onDelete: () => _deleteItem(item),
            onAdjustQty: (delta) => _adjustQuantity(item, delta),
          ),
        );
      },
    );
  }

  // ── Shimmer skeleton ───────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceVariant,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearch ? 'No items found' : 'You have no food!',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Try a different search term'
                : 'Tap the Scan tab to add your first items.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Could not load inventory', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(error.toString(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ref.read(inventoryProvider.notifier).reload(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.black,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Item card widget
// ─────────────────────────────────────────────────────────────────────────────

/// A single swipeable item card rendered in the inventory list.
///
/// Swipe left → delete (with red background).
/// Tap → open [ItemDetailScreen].
/// +/− buttons → adjust quantity in-place.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onAdjustQty,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(int delta) onAdjustQty;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        // Ask for confirmation before deleting.
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: Text('Delete item?', style: AppTextStyles.headlineMedium),
            content: Text(
              'Remove "${item.name}" from your inventory?',
              style: AppTextStyles.bodyLarge,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Category color dot
              _CategoryDot(category: item.category),
              const SizedBox(width: 12),
              // Item name + category label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    _CategoryBadge(category: item.category),
                  ],
                ),
              ),
              // Quantity stepper
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: item.quantity > 0 ? () => onAdjustQty(-1) : null,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: item.quantity == 0
                              ? AppColors.error
                              : AppColors.textPrimary),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: () => onAdjustQty(1),
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

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceVariant : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }
}

/// Coloured dot that represents the item's category visually.
class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.category});
  final String category;

  static const _colors = <String, Color>{
    'produce':  AppColors.green,
    'dairy':    AppColors.info,
    'meat':     AppColors.error,
    'bakery':   AppColors.warning,
    'frozen':   AppColors.teal,
    'pantry':   AppColors.purple,
    'beverage': AppColors.infoDark,
    'snack':    AppColors.warningDark,
    'other':    AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category] ?? AppColors.textMuted;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Small pill badge showing the category name.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
