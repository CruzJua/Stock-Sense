import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/confirmed_item.dart';
import '../providers/confirmed_items_provider.dart';
import '../services/inventory_service.dart';
import '../../inventory/providers/inventory_provider.dart';

/// Displays AI-detected items and lets the user review, edit, delete, and
/// add items before saving them to Supabase.
class AiResultsScreen extends ConsumerStatefulWidget {
  const AiResultsScreen({
    super.key,
    required this.initialItems,
    required this.mode,
  });

  final List<ConfirmedItem> initialItems;
  final String mode;

  @override
  ConsumerState<AiResultsScreen> createState() => _AiResultsScreenState();
}

class _AiResultsScreenState extends ConsumerState<AiResultsScreen> {
  late final List<ConfirmedItem> _initialItems;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialItems = widget.initialItems;
  }

  // ── Save to Supabase ──────────────────────────────────────────────────────

  Future<void> _saveItems(List<ConfirmedItem> items) async {
    setState(() => _isSaving = true);
    try {
      await InventoryService().saveItems(items);
      if (!mounted) return;
      ref.read(inventoryProvider.notifier).reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items saved to inventory! 🎉'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Pop back to the scan tab.
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: AppColors.white,
            onPressed: () => _saveItems(items),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Add item dialog ───────────────────────────────────────────────────────

  void _showAddItemDialog(
      List<ConfirmedItem> items, List<ConfirmedItem> initial) {
    final notifier = ref.read(confirmedItemsProvider(initial).notifier);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddItemSheet(
        onAdd: (item) {
          notifier.addItem(item);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(confirmedItemsProvider(_initialItems));
    final notifier = ref.read(confirmedItemsProvider(_initialItems).notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text('AI Results', style: AppTextStyles.headlineMedium),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                widget.mode.toUpperCase(),
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.green),
              ),
              backgroundColor: AppColors.green.withValues(alpha: 0.12),
              side: const BorderSide(color: AppColors.green),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'} detected',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.green),
                ),
                const Spacer(),
                Text(
                  'Swipe left to remove',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // ── Item list ─────────────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? _EmptyState(
                    onAdd: () =>
                        _showAddItemDialog(items, _initialItems),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      return Dismissible(
                        key: ValueKey(Object.hash(
                            items[index].name, index)),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:
                              const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error),
                        ),
                        onDismissed: (_) =>
                            notifier.removeItem(index),
                        child: _ItemCard(
                          item: items[index],
                          onChanged: (updated) =>
                              notifier.updateItem(index, updated),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── FAB + Save button ─────────────────────────────────────────────────
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        isSaving: _isSaving,
        itemCount: items.length,
        onAdd: () => _showAddItemDialog(items, _initialItems),
        onSave: items.isEmpty ? null : () => _saveItems(items),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item card — editable inline
// ---------------------------------------------------------------------------

class _ItemCard extends StatefulWidget {
  const _ItemCard({required this.item, required this.onChanged});

  final ConfirmedItem item;
  final ValueChanged<ConfirmedItem> onChanged;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  late String _category;
  late DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(
        text: widget.item.quantity.toString());
    _unitCtrl =
        TextEditingController(text: widget.item.unit);
    _category = widget.item.category;
    _expiryDate = widget.item.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(ConfirmedItem(
      name: _nameCtrl.text,
      quantity: double.tryParse(_qtyCtrl.text) ?? 1,
      unit: _unitCtrl.text,
      category: _category,
      expiryDate: _expiryDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          _FieldLabel(label: 'ITEM NAME'),
          const SizedBox(height: 4),
          _InlineField(
            controller: _nameCtrl,
            onEditingComplete: _notify,
            hintText: 'e.g. Milk',
          ),
          const SizedBox(height: 12),

          // Quantity + Unit row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'QTY'),
                    const SizedBox(height: 4),
                    _InlineField(
                      controller: _qtyCtrl,
                      onEditingComplete: _notify,
                      keyboardType: TextInputType.number,
                      hintText: '1',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'UNIT'),
                    const SizedBox(height: 4),
                    _InlineField(
                      controller: _unitCtrl,
                      onEditingComplete: _notify,
                      hintText: 'each',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category dropdown
          _FieldLabel(label: 'CATEGORY'),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: ConfirmedItem.categories.contains(_category)
                ? _category
                : 'other',
            dropdownColor: AppColors.surfaceVariant,
            style: AppTextStyles.titleSmall,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: ConfirmedItem.categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c[0].toUpperCase() + c.substring(1),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _category = v);
                _notify();
              }
            },
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'EXPIRATION DATE'),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expiryDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _expiryDate = picked);
                _notify();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _expiryDate == null 
                    ? 'Tap to select' 
                    : '${_expiryDate!.month}/${_expiryDate!.day}/${_expiryDate!.year}',
                style: AppTextStyles.titleSmall.copyWith(
                  color: _expiryDate == null ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.overlineMuted);
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.controller,
    required this.onEditingComplete,
    this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final VoidCallback onEditingComplete;
  final String? hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onEditingComplete: onEditingComplete,
      onTapOutside: (_) => onEditingComplete(),
      style: AppTextStyles.titleSmall,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodySmall,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppColors.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.textMuted, size: 52),
          const SizedBox(height: 16),
          Text('No items detected', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Try a clearer photo, or add items manually.',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Item Manually'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar with Add + Save buttons
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isSaving,
    required this.itemCount,
    required this.onAdd,
    required this.onSave,
  });

  final bool isSaving;
  final int itemCount;
  final VoidCallback onAdd;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // Add button
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
            ),
            const SizedBox(width: 12),

            // Save button
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.black,
                  disabledBackgroundColor:
                      AppColors.green.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      )
                    : Text(
                        'Save to Inventory ($itemCount)',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add item bottom sheet
// ---------------------------------------------------------------------------

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.onAdd});
  final ValueChanged<ConfirmedItem> onAdd;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController(text: 'each');
  String _category = 'other';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.onAdd(ConfirmedItem(
      name: _nameCtrl.text.trim(),
      quantity: double.tryParse(_qtyCtrl.text) ?? 1,
      unit: _unitCtrl.text.trim().isEmpty ? 'each' : _unitCtrl.text.trim(),
      category: _category,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Item Manually', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: AppTextStyles.titleSmall,
            decoration: _inputDeco('Item name *'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.titleSmall,
                  decoration: _inputDeco('Quantity'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitCtrl,
                  style: AppTextStyles.titleSmall,
                  decoration: _inputDeco('Unit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: AppColors.surfaceVariant,
            style: AppTextStyles.titleSmall,
            decoration: _inputDeco('Category'),
            items: ConfirmedItem.categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c[0].toUpperCase() + c.substring(1),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Add Item', style: AppTextStyles.titleMedium),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: AppColors.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      );
}
