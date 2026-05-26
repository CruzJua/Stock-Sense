/// A single item detected by the AI and pending user confirmation.
///
/// This is a mutable plain-Dart class so the AI Results Confirmation Screen
/// can edit fields inline before the user saves to Supabase.
class ConfirmedItem {
  String name;
  double quantity;
  String unit;
  String category;

  ConfirmedItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
  });

  /// Allowed category values — must match the Supabase items table constraint.
  static const List<String> categories = [
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

  /// Build from the raw JSON shape returned by the Edge Function.
  factory ConfirmedItem.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'] as String? ?? 'other';
    final safeCategory =
        categories.contains(rawCategory) ? rawCategory : 'other';

    return ConfirmedItem(
      name: (json['name'] as String?) ?? 'Unknown item',
      quantity: ((json['quantity'] as num?) ?? 1).toDouble(),
      unit: (json['unit'] as String?) ?? 'each',
      category: safeCategory,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category,
      };

  ConfirmedItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    String? category,
  }) {
    return ConfirmedItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }
}
