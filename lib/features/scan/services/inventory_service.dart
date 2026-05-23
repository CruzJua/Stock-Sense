import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/confirmed_item.dart';

/// Saves a list of confirmed items to the Supabase `items` table and
/// requests a pgvector embedding for each one via the `generate-embedding`
/// Edge Function.
class InventoryService {
  final _supabase = Supabase.instance.client;

  Future<void> saveItems(List<ConfirmedItem> items) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    for (final item in items) {
      // 1. Insert the item row and retrieve the new id.
      final inserted = await _supabase
          .from('items')
          .insert({
            'user_id': userId,
            'name': item.name,
            'quantity': item.quantity,
            'unit': item.unit,
            'category': item.category,
          })
          .select('id')
          .single();

      final newId = inserted['id'] as String;

      // 2. Generate the pgvector embedding for this item name.
      try {
        final embeddingResponse = await _supabase.functions.invoke(
          'generate-embedding',
          body: {'itemName': item.name},
        );

        if (embeddingResponse.status == 200) {
          final data = embeddingResponse.data as Map<String, dynamic>;
          final embedding = data['embedding'] as List<dynamic>;

          // 3. Update the row with the embedding vector.
          await _supabase
              .from('items')
              .update({'embedding': embedding})
              .eq('id', newId);
        }
        // If embedding fails we still keep the item — it just won't be
        // available for semantic search until the embedding is generated.
      } catch (_) {
        // Non-fatal: log silently so the rest of the items still save.
      }
    }
  }
}
