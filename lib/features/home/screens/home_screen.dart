import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/inventory/models/inventory_item.dart';
import '../../../features/inventory/providers/inventory_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home Screen — Dashboard
// ─────────────────────────────────────────────────────────────────────────────

/// The first tab the user lands on after signing in.
///
/// Shows a high-level overview of the user's inventory:
/// - Greeting with the user's name
/// - Three stat cards: total items, low-stock count, category count
/// - A "Recent Additions" horizontal list of the last 5 items added
/// - A "Low Stock" section for items with quantity ≤ 2
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final displayName = profileAsync.when(
      data: (data) => data?['full_name'] as String? ?? 'there',
      loading: () => '...',
      error: (_, __) => 'there',
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: itemsAsync.when(
          loading: () => _buildShimmer(),
          error: (e, _) => _buildError(e, ref),
          data: (items) => _buildDashboard(context, displayName, items),
        ),
      ),
    );
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────

  Widget _buildDashboard(
      BuildContext context, String name, List<InventoryItem> items) {
    final lowStock = items
        .where((i) => i.quantity <= 2 && i.quantity >= 0)
        .toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));
    final now = DateTime.now();
    final threeDays = now.add(const Duration(days: 3));
    final expiringSoon = items
        .where((i) => i.expiryDate != null && i.expiryDate!.isAfter(now) && i.expiryDate!.isBefore(threeDays))
        .toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    final recent   = items
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentFive = recent.take(5).toList();
    final categoryCount =
        items.map((i) => i.category).toSet().length;

    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.surfaceDark,
      onRefresh: () async {}, // inventory provider auto-refreshes via realtime
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // ── Greeting ──
          _buildGreeting(name),
          const SizedBox(height: 24),

          // ── Stat cards ──
          _buildStatRow(items.length, lowStock.length, categoryCount),
          const SizedBox(height: 28),


          // ── Expiring Soon ──
          if (expiringSoon.isNotEmpty) ...[
            _buildSectionHeader('Expiring Soon 🗓️', AppColors.error),
            const SizedBox(height: 12),
            SizedBox(
              height: expiringSoon.length > 5 ? 290 : expiringSoon.length * 58.0,
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: expiringSoon.length,
                itemBuilder: (_, i) => _ExpiringTile(item: expiringSoon[i]),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Low stock section ──
          if (lowStock.isNotEmpty) ...[
            _buildSectionHeader('Low Stock', AppColors.warning),
            const SizedBox(height: 12),
            SizedBox(
              height: lowStock.length > 5 ? 290 : lowStock.length * 58.0,
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: lowStock.length,
                itemBuilder: (_, i) => _LowStockTile(item: lowStock[i]),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Recent additions ──
          if (recentFive.isNotEmpty) ...[
            _buildSectionHeader('Recently Added', AppColors.green),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentFive.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _RecentItemCard(item: recentFive[i]),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Empty state ──
          if (items.isEmpty) _buildEmptyState(context),
        ],
      ),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────────────────

  Widget _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$timeGreeting,', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
              Text(name, style: AppTextStyles.headlineLarge),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.greenSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.green.withAlpha(80)),
          ),
          child: const Icon(Icons.inventory_2_rounded,
              color: AppColors.green, size: 22),
        ),
      ],
    );
  }

  // ── Stat cards ─────────────────────────────────────────────────────────────

  Widget _buildStatRow(int total, int lowStock, int categories) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Total Items', value: '$total',
          icon: Icons.inventory_2_outlined, color: AppColors.green)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Low Stock', value: '$lowStock',
          icon: Icons.warning_amber_rounded,
          color: lowStock > 0 ? AppColors.warning : AppColors.textMuted)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Categories', value: '$categories',
          icon: Icons.category_outlined, color: AppColors.teal)),
      ],
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, Color accent) { // The was an Error Here
    return Row(
      children: [
        Container(width: 3, height: 18,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: accent)),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.headlineMedium),
      ],
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: AppColors.surfaceDark, shape: BoxShape.circle),
            child: const Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text('Your pantry is empty!', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text('Tap the Scan tab to add your first items.',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 180, height: 28, color: AppColors.surfaceDark,
                margin: const EdgeInsets.only(bottom: 8)),
            Container(width: 120, height: 20, color: AppColors.surfaceDark,
                margin: const EdgeInsets.only(bottom: 28)),
            Row(children: [
              Expanded(child: Container(height: 90, color: AppColors.surfaceDark)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 90, color: AppColors.surfaceDark)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 90, color: AppColors.surfaceDark)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text('Failed to load inventory',
              style: AppTextStyles.headlineMedium),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ref.read(inventoryProvider.notifier).reload(),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green, foregroundColor: AppColors.black),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineLarge
                  .copyWith(color: color, fontSize: 24)),
          Text(label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Low stock tile
// ─────────────────────────────────────────────────────────────────────────────

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.quantity == 0 ? AppColors.error : AppColors.warning,
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.quantity == 0
                ? Icons.remove_circle_outline
                : Icons.warning_amber_rounded,
            color: item.quantity == 0 ? AppColors.error : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.name,
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.quantity == 0
                  ? AppColors.errorLight.withAlpha(30)
                  : AppColors.warningLight.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Qty: ${item.quantity}',
              style: AppTextStyles.labelSmall.copyWith(
                color: item.quantity == 0 ? AppColors.error : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent item card (horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _RecentItemCard extends StatelessWidget {
  const _RecentItemCard({required this.item});
  final InventoryItem item;

  static const _categoryColors = <String, Color>{
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
    final color = _categoryColors[item.category] ?? AppColors.textMuted;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_rounded, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            item.name,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Qty: ${item.quantity}',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}


class _ExpiringTile extends StatelessWidget {
  const _ExpiringTile({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.expiryDate!.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.name,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.errorLight.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysLeft == 0 ? 'Today!' : 'In $daysLeft day${daysLeft == 1 ? '' : 's'}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
