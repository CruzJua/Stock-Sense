import 'package:flutter/foundation.dart';

/// Represents one row from the `items` table in Supabase.
///
/// This model is used throughout the inventory feature — from the Riverpod
/// provider that fetches data, to the UI cards that display it, to the Hive
/// offline cache that stores it as JSON.
@immutable
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.category,
    this.description,
    this.itemCode,
    required this.createdAt,
    this.expiryDate,
    this.isExpiryEstimated = false,
  });

  final String id;
  final String userId;

  /// The human-readable item name (maps to `item_name` in the DB).
  final String name;

  final int quantity;

  /// One of: produce, dairy, meat, bakery, frozen, pantry, beverage, snack, other.
  final String category;

  final String? description;

  /// Reserved for future barcode scanning — stores UPC/EAN codes.
  final String? itemCode;

  final DateTime createdAt;

  /// The date this item expires.
  final DateTime? expiryDate;

  final bool isExpiryEstimated;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Constructs an [InventoryItem] from a Supabase row map.
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final days = json['estimated_shelf_life_days'] as int?;
    final computedExpiry = days != null ? DateTime.now().add(Duration(days: days)) : null;
    
    final expiry = json['expiry_date'] != null 
        ? DateTime.parse(json['expiry_date'] as String) 
        : computedExpiry;
        
    return InventoryItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: (json['item_name'] as String?) ?? 'Unknown item',
      quantity: (json['quantity'] as int?) ?? 0,
      category: (json['category'] as String?) ?? 'other',
      description: json['description'] as String?,
      itemCode: json['item_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiryDate: expiry,
      isExpiryEstimated: json['is_expiry_estimated'] as bool? ?? false,
    );
  }

  /// Converts the item to a plain map suitable for JSON encoding (Hive cache).
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'item_name': name,
        'quantity': quantity,
        'category': category,
        'description': description,
        'item_code': itemCode,
        'created_at': createdAt.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
      };

  /// Returns a copy with the given fields replaced.
  InventoryItem copyWith({
    String? name,
    int? quantity,
    String? category,
    String? description,
    DateTime? expiryDate,
  }) {
    return InventoryItem(
      id: id,
      userId: userId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      description: description ?? this.description,
      itemCode: itemCode,
      createdAt: createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InventoryItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
