# StockSense

A Flutter-powered smart home inventory app — snap a photo, let AI do the rest.

StockSense eliminates the friction of manual food inventory management. Users photograph their fridge, pantry, or grocery receipts and the app automatically identifies and catalogues every item using AI vision, with semantic search and intelligent expiry alerts powered throughout.

---

## Team

- Juan Cruz

---

## Technologies

| Layer | Technology |
|---|---|
| Mobile Framework | Flutter (Dart) |
| State Management | Riverpod 2.x |
| Backend / Database | Supabase (PostgreSQL + pgvector) |
| Authentication | Supabase Auth |
| Semantic Search | pgvector + OpenAI Embeddings |
| Backend Functions | Supabase Edge Functions (Deno) |
| AI Vision — Scenes | Google Cloud Vision API |
| AI Vision — Receipts | OpenAI GPT-4o Vision |
| On-Device ML | Google ML Kit |
| Push Notifications | APNs / FCM via Supabase Edge Functions |
| Local Cache | Hive |

---

## Setup

### Prerequisites

- Flutter SDK (≥ 3.19.0)
- Supabase CLI
- Deno (≥ 1.40)
- A Supabase project with the `vector` extension enabled
- Google Cloud project with Cloud Vision API enabled
- OpenAI API key (GPT-4o + Embeddings access)

### Installation

```bash
# Clone the repository
git clone https://github.com/<your-username>/stocksense.git
cd stocksense

# Install Flutter dependencies
flutter pub get

# Copy the environment variable template and fill in your values
cp .env.example .env
```

### Configure Supabase

```bash
# Link to your Supabase project
supabase link --project-ref <your-project-ref>

# Apply database migrations
supabase db push

# Deploy Edge Functions
supabase functions deploy ai-orchestrator
supabase functions deploy generate-embeddings
supabase functions deploy send-alerts

# Set API key secrets on the deployed functions
supabase secrets set OPENAI_API_KEY=<your-key>
supabase secrets set GOOGLE_CLOUD_VISION_API_KEY=<your-key>
```

### Run

```bash
flutter run
```
