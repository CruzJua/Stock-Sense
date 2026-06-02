import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../models/inventory_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter model
// ─────────────────────────────────────────────────────────────────────────────

/// The set of active filters and sort options for the inventory list.
///
/// [category] — when null, all categories are shown.
/// [sortBy]   — the Supabase column name to order by.
/// [ascending]— true = A→Z / low→high / oldest first.
class InventoryFilter {
  const InventoryFilter({
    this.category,
    this.sortBy = 'item_name',
    this.ascending = true,
  });

  final String? category;
  final String sortBy;
  final bool ascending;

  InventoryFilter copyWith({
    Object? category = _sentinel,
    String? sortBy,
    bool? ascending,
  }) {
    return InventoryFilter(
      category: category == _sentinel ? this.category : category as String?,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryFilter &&
      other.category == category &&
      other.sortBy == sortBy &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(category, sortBy, ascending);
}

// Sentinel value used by copyWith to distinguish "set to null" from "unchanged".
const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Exposes the current [InventoryNotifier] and its [AsyncValue] state.
final inventoryProvider = StateNotifierProvider.autoDispose<InventoryNotifier,
    AsyncValue<List<InventoryItem>>>(
  (ref) => InventoryNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the full lifecycle of the inventory item list:
///
/// - Fetches items from Supabase with category filter + sort applied.
/// - Subscribes to Supabase Realtime so the list updates live when items are
///   added, updated, or deleted from any device.
/// - Reads from and writes to a Hive box so the last-known list is shown
///   instantly on startup (before the network response arrives).
/// - Listens for connectivity changes and re-fetches when the device
///   reconnects to the internet.
class InventoryNotifier
    extends StateNotifier<AsyncValue<List<InventoryItem>>> {
  InventoryNotifier() : super(const AsyncValue.loading()) {
    _load();
    _setupRealtime();
    _setupConnectivity();
  }

  InventoryFilter _filter = const InventoryFilter();
  RealtimeChannel? _channel;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Hive box name — opened in main.dart via Hive.openBox.
  static const _boxName = 'inventoryCache';

  // ── Filter / sort control ──────────────────────────────────────────────────

  /// Called by the UI when the user picks a category chip.
  void setCategory(String? category) {
    _filter = _filter.copyWith(category: category);
    _load();
  }

  /// Called by the UI when the user changes the sort option.
  void setSort(String sortBy, {bool ascending = true}) {
    _filter = _filter.copyWith(sortBy: sortBy, ascending: ascending);
    _load();
  }

  InventoryFilter get filter => _filter;

  // ── Optimistic helpers ─────────────────────────────────────────────────────

  /// Adjusts an item's quantity in local state immediately, without waiting
  /// for the Supabase round-trip. The realtime subscription then confirms.
  void adjustQuantityOptimistic(String id, int delta) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.map((item) {
        if (item.id != id) return item;
        final newQty = (item.quantity + delta).clamp(0, 9999);
        return item.copyWith(quantity: newQty);
      }).toList(),
    );
  }

  /// Removes an item from local state immediately (optimistic delete).
  void removeOptimistic(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.where((i) => i.id != id).toList());
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> reload() => _load();

  Future<void> _load() async {
    // Show cached data instantly while the network request is in flight.
    final cached = _readCache();
    if (cached != null && state is! AsyncData) {
      state = AsyncValue.data(cached);
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Build the query — filter and sort are applied server-side.
      var query = supabase
          .from('items')
          .select()
          .eq('user_id', userId);

      if (_filter.category != null) {
        query = query.eq('category', _filter.category!);
      }

      final List<dynamic> rows = await query.order(
        _filter.sortBy,
        ascending: _filter.ascending,
      );

      final items = rows.map((r) => InventoryItem.fromJson(r as Map<String, dynamic>)).toList();
      state = AsyncValue.data(items);
      _writeCache(items);
    } catch (e, st) {
      // If we already have data (from cache or a previous load), keep showing
      // it and surface the error via a separate notification in the UI.
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  // ── Supabase Realtime ──────────────────────────────────────────────────────

  void _setupRealtime() {
    _channel = supabase
        .channel('inventory-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  // ── Connectivity ───────────────────────────────────────────────────────────

  void _setupConnectivity() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      // Re-fetch when the device gains any network access.
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) _load();
    });
  }

  // ── Hive cache ─────────────────────────────────────────────────────────────

  List<InventoryItem>? _readCache() {
    try {
      final box = Hive.box(_boxName);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final raw = box.get('items_$userId') as String?;
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null; // Cache read failure is non-fatal.
    }
  }

  void _writeCache(List<InventoryItem> items) {
    try {
      final box = Hive.box(_boxName);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      box.put('items_$userId', jsonEncode(items.map((i) => i.toJson()).toList()));
    } catch (_) {
      // Cache write failure is non-fatal.
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _channel?.unsubscribe();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
