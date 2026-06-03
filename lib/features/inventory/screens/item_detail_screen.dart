import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/inventory_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Item Detail / Manual Add Screen
// ─────────────────────────────────────────────────────────────────────────────

/// A form screen that serves two purposes:
///
/// **Edit mode** (when [item] is not null): Pre-fills all fields with the
/// existing item's values. Tapping Save updates the Supabase row and
/// regenerates the pgvector embedding so semantic search stays accurate.
///
/// **Add mode** (when [item] is null): All fields start empty. Tapping Save
/// inserts a new row and generates an embedding for it.
///
/// Reached from [InventoryScreen] via the FAB (add) or by tapping a card (edit).
class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.item,
    this.initialName,
    this.initialCategory,
    this.initialExpiryDate,
  });

  /// The item to edit, or null when adding a new item manually.
  final InventoryItem? item;
  final String? initialName;
  final String? initialCategory;
  final DateTime? initialExpiryDate;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _descCtrl;
  String _category = 'other';
  bool _saving = false;
  DateTime? _expiryDate;
  bool _isEstimated = false;

  bool get _isEdit => widget.item != null;

  static const _categories = [
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

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(
      text: item?.name ?? widget.initialName ?? '',
    );
    _qtyCtrl = TextEditingController(text: item?.quantity.toString() ?? '1');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _category = item?.category ?? widget.initialCategory ?? 'other';
    _expiryDate = item?.expiryDate ?? widget.initialExpiryDate;
    _isEstimated =
        item?.isExpiryEstimated ??
        (widget.initialExpiryDate != null && item == null);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final name = _nameCtrl.text.trim();
      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
      final desc = _descCtrl.text.trim();

      String itemId;

      if (_isEdit) {
        // Update the existing row.
        await supabase
            .from('items')
            .update({
              'item_name': name,
              'quantity': qty,
              'category': _category,
              'description': desc.isEmpty ? null : desc,
              'expiry_date': _expiryDate?.toIso8601String(),
              'is_expiry_estimated': _isEstimated,
            })
            .eq('id', widget.item!.id);
        itemId = widget.item!.id;
      } else {
        // Insert a new row and get back its generated id.
        final result = await supabase
            .from('items')
            .insert({
              'user_id': userId,
              'item_name': name,
              'quantity': qty,
              'category': _category,
              'description': desc.isEmpty ? null : desc,
              'expiry_date': _expiryDate?.toIso8601String(),
              'is_expiry_estimated': _isEstimated,
            })
            .select('id')
            .single();
        itemId = result['id'] as String;
      }

      // Regenerate the embedding so semantic search stays accurate.
      // Non-fatal: if this fails, the item still saves correctly.
      await _regenerateEmbedding(itemId, name);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.white,
              onPressed: _save,
            ),
          ),
        );
      }
    }
  }

  Future<void> _regenerateEmbedding(String itemId, String name) async {
    try {
      final res = await supabase.functions.invoke(
        'generate-embedding',
        body: {'itemName': name},
      );
      if (res.status != 200) return;
      final data = res.data as Map<String, dynamic>;
      final embedding = data['embedding'] as List<dynamic>;
      await supabase
          .from('items')
          .update({'embedding': embedding})
          .eq('id', itemId);
    } catch (_) {
      // Non-fatal — item is saved, just not semantically searchable yet.
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    if (!_isEdit) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Delete item?', style: AppTextStyles.headlineMedium),
        content: Text(
          'Remove "${widget.item!.name}" from your inventory permanently?',
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await supabase.from('items').delete().eq('id', widget.item!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? 'Edit Item' : 'Add Item',
          style: AppTextStyles.headlineMedium,
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                label: 'Item Name',
                controller: _nameCtrl,
                hint: 'e.g. Whole Milk',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Quantity',
                controller: _qtyCtrl,
                hint: '1',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Quantity is required';
                  if (int.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildCategoryDropdown(),
              const SizedBox(height: 20),
              _buildExpiryField(),
              const SizedBox(height: 20),
              _buildField(
                label: 'Description (optional)',
                controller: _descCtrl,
                hint: 'Brand, size, notes…',
                maxLines: 3,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.black,
                    disabledBackgroundColor: AppColors.greenDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.black,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Add to Inventory',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: AppTextStyles.bodyLarge,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: AppColors.surfaceDark,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c[0].toUpperCase() + c.substring(1),
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? 'other'),
        ),
      ],
    );
  }

  Widget _buildExpiryField() {
    final dateStr = _expiryDate == null
        ? 'No Date selected'
        : '${_expiryDate!.month}, ${_expiryDate!.day}, ${_expiryDate!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiration Date',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _expiryDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.green,
                      onPrimary: AppColors.surfaceDark,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              setState(() {
                _expiryDate = picked;
                _isEstimated = false;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDark,
              suffixIcon: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            child: Text(
              dateStr,
              style: AppTextStyles.bodyLarge.copyWith(
                color: _expiryDate == null
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (_isEstimated) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Date is estimated. Tap to set exact date.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
