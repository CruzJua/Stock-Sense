import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/confirmed_item.dart';

/// Manages the mutable list of confirmed items on the AI Results screen.
///
/// The notifier is created as a family so each navigation push gets its
/// own isolated state seeded with the AI-returned items.
class ConfirmedItemsNotifier extends StateNotifier<List<ConfirmedItem>> {
  ConfirmedItemsNotifier(super.state);

  void updateItem(int index, ConfirmedItem updated) {
    final copy = [...state];
    copy[index] = updated;
    state = copy;
  }

  void removeItem(int index) {
    final copy = [...state];
    copy.removeAt(index);
    state = copy;
  }

  void addItem(ConfirmedItem item) {
    state = [...state, item];
  }
}

/// A [StateNotifierProvider.family] keyed by an opaque [Object] token so
/// callers can share state within the same screen without a global singleton.
final confirmedItemsProvider = StateNotifierProvider.family<
    ConfirmedItemsNotifier, List<ConfirmedItem>, List<ConfirmedItem>>(
  (ref, initial) => ConfirmedItemsNotifier(initial),
);
