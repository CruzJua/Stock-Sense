import '../../../features/auth/providers/auth_provider.dart';
import '../models/inventory_item.dart';

/// Provides two complementary search strategies for the inventory:
///
/// 1. **Semantic search** (via `search_items` Postgres RPC):
///    Embeds the user's query using the `generate-embedding` Edge Function,
///    then compares the resulting vector against stored item embeddings using
///    pgvector cosine similarity.
///
/// 2. **Full-text fallback** (via Supabase `.textSearch()`):
///    Used when the semantic search returns fewer than [_semanticThreshold]
///    results, or when the query is very short. Matches against the
///    `search_vector` tsvector column (item_name + category).
///
/// Results are merged and de-duplicated — semantic hits appear first.
class SearchService {
  // Minimum cosine similarity score for a semantic result to be included.
  static const _matchThreshold = 0.5;

  // Maximum results to return from each search strategy.
  static const _maxResults = 20;

  // If semantic search returns fewer than this, run full-text too.
  static const _semanticThreshold = 3;

  /// Runs a hybrid search and returns a ranked, de-duplicated list.
  ///
  /// Returns an empty list (not an error) if the query is blank.
  Future<List<InventoryItem>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final semanticResults = await _semanticSearch(q, userId);

    // Only run full-text if semantic didn't return enough results.
    if (semanticResults.length >= _semanticThreshold) {
      return semanticResults;
    }

    final fullTextResults = await _fullTextSearch(q, userId);

    // Merge: semantic first, then full-text hits that weren't already included.
    final seen = {for (final item in semanticResults) item.id};
    final merged = [
      ...semanticResults,
      ...fullTextResults.where((item) => !seen.contains(item.id)),
    ];
    return merged;
  }

  // ── Semantic search ──────────────────────────────────────────────────────

  Future<List<InventoryItem>> _semanticSearch(
      String query, String userId) async {
    try {
      // Step 1: Generate an embedding vector for the query text.
      final embeddingResponse = await supabase.functions.invoke(
        'generate-embedding',
        body: {'itemName': query},
      );

      if (embeddingResponse.status != 200) return [];

      final data = embeddingResponse.data as Map<String, dynamic>;
      final embedding = (data['embedding'] as List<dynamic>)
          .map((v) => (v as num).toDouble())
          .toList();

      // Step 2: Call the search_items RPC with the embedding.
      final rows = await supabase.rpc('search_items', params: {
        'query_embedding': embedding,
        'match_threshold': _matchThreshold,
        'match_count': _maxResults,
        'p_user_id': userId,
      }) as List<dynamic>;

      return rows
          .map((r) => InventoryItem.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // Semantic failure is non-fatal; full-text will cover it.
    }
  }

  // ── Full-text search ─────────────────────────────────────────────────────

  Future<List<InventoryItem>> _fullTextSearch(
      String query, String userId) async {
    try {
      final rows = await supabase
          .from('items')
          .select()
          .eq('user_id', userId)
          .textSearch('search_vector', query, config: 'english')
          .limit(_maxResults) as List<dynamic>;

      return rows
          .map((r) => InventoryItem.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// A singleton instance used across the inventory feature.
final searchService = SearchService();
