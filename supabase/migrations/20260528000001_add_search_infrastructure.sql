-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: Add Search Infrastructure
--
-- Adds two search capabilities to the items table:
--   1. Semantic search  – pgvector cosine-similarity via the search_items() RPC.
--   2. Full-text search – tsvector column with a GIN index for fast keyword
--                         lookups when the semantic score is too low.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Add a generated tsvector column so Postgres does full-text indexing
--    automatically whenever item_name or category changes.
ALTER TABLE public.items
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    to_tsvector('english',
      COALESCE(item_name, '') || ' ' || COALESCE(category, '')
    )
  ) STORED;

-- 2. GIN index makes full-text lookups O(log n) instead of a sequential scan.
CREATE INDEX IF NOT EXISTS items_search_vector_idx
  ON public.items USING gin(search_vector);

-- 3. Semantic search function.
--    Returns items ranked by cosine similarity to a query embedding vector.
--    The <=> operator is pgvector's cosine distance (0 = identical, 2 = opposite).
--    We convert to similarity = 1 - distance so higher is better.
CREATE OR REPLACE FUNCTION public.search_items(
  query_embedding  vector(1536),
  match_threshold  float,
  match_count      int,
  p_user_id        uuid
)
RETURNS TABLE (
  id         uuid,
  item_name  text,
  quantity   int,
  category   text,
  created_at timestamptz,
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    id,
    item_name,
    quantity,
    category,
    created_at,
    1 - (embedding <=> query_embedding) AS similarity
  FROM public.items
  WHERE
    user_id = p_user_id
    AND embedding IS NOT NULL
    AND 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
$$;
