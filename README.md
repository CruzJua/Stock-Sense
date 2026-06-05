# StockSense

StockSense is an AI-powered mobile and web application for managing household food inventory. Users photograph their fridge, pantry shelves, or a paper grocery receipt and the app automatically identifies every item, assigns quantities and categories, estimates shelf life, and saves everything to a searchable, real-time inventory.

Production deployment: https://stocksense.juancruzdev.com

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Technologies](#technologies)
- [Database Schema](#database-schema)
- [Prerequisites](#prerequisites)
- [Local Setup](#local-setup)
- [Environment Variables](#environment-variables)
- [Supabase Configuration](#supabase-configuration)
- [Running the App](#running-the-app)
- [Author](#author)

---

## Overview

Manual food tracking is tedious enough that most people abandon it entirely, leading to forgotten items, duplicate purchases, and significant food waste. StockSense removes the manual step entirely. A single photo is all that is required — GPT-4o Vision analyses the image and returns a structured list of items which the user can review, edit, and confirm before they are persisted to the database.

Once saved, items are stored with a 1536-dimensional vector embedding (OpenAI `text-embedding-3-small`) that powers a hybrid semantic and full-text search system. The dashboard surfaces low-stock items and recent additions at a glance, and a push notification system alerts users when items are nearing expiry or running low.

---

## Key Features

**AI Photo Scanning** — Three scanning modes are supported: Fridge, Pantry, and Receipt. All three use GPT-4o Vision to return a structured JSON list of items including name, quantity, unit, category, and estimated shelf life in days.

**Review and Edit** — Before anything is saved, users are presented with every detected item on an editable results screen. Names, quantities, units, categories, and expiry dates can all be adjusted or removed. Items can also be added manually at this stage.

**Inventory Management** — The full inventory is displayed as a filterable, sortable list. Users can filter by category (produce, dairy, meat, bakery, frozen, pantry, beverage, snack), sort by name, quantity, or date added, adjust quantities in-place with stepper controls, and swipe to delete with a confirmation prompt.

**Semantic Search** — Search queries are embedded using OpenAI's embedding model and compared against stored item embeddings via pgvector cosine similarity. If the semantic results are insufficient, a PostgreSQL full-text search fallback runs automatically against the `search_vector` tsvector column.

**Dashboard** — The home screen shows total item count, number of low-stock items, category count, a low-stock alert list, and a horizontally scrolling row of recently added items.

**Barcode Scanner** — A product barcode can be scanned using the device camera (powered by Google ML Kit) to pre-fill item name and category on the manual add form.

**Push Notifications** — A Supabase Edge Function (`send-notifications`) dispatches daily FCM and APNs push notifications for items expiring within three days and items with a quantity of two or fewer.

**Offline Cache** — Inventory data is cached locally with Hive so the app remains usable when the device is offline.

---

## Technologies

| Layer | Technology |
|---|---|
| Mobile / Web Framework | Flutter 3.x (Dart) |
| State Management | Riverpod 2.x |
| Routing | Go Router |
| Local Cache | Hive |
| Backend / Database | Supabase (PostgreSQL) |
| Vector Storage | pgvector extension |
| Authentication | Supabase Auth (email / password) |
| Serverless Functions | Supabase Edge Functions (Deno / TypeScript) |
| AI Vision | OpenAI GPT-4o Vision |
| Embeddings | OpenAI text-embedding-3-small |
| On-Device ML | Google ML Kit (barcode scanning) |
| Push Notifications | Firebase Cloud Messaging (FCM) / APNs |
| Image Optimisation | flutter_image_compress |

---

## Database Schema

The database is managed through versioned migrations located in `supabase/migrations/`.

**`public.users`** — Mirror of `auth.users`. Populated automatically on sign-up via a `handle_new_user` trigger.

**`public.items`** — Core inventory table. Each row represents one item belonging to a user.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key to `auth.users` |
| `item_name` | text | Human-readable name |
| `quantity` | int | Current stock level |
| `category` | text | One of: produce, dairy, meat, bakery, frozen, pantry, beverage, snack, other |
| `description` | text | Optional |
| `item_code` | text | UPC / EAN from barcode scanner |
| `expiry_date` | date | Set from GPT-4o estimate or user input |
| `is_expiry_estimated` | boolean | True when date was inferred from shelf-life estimate |
| `embedding` | vector(1536) | OpenAI embedding for semantic search |
| `search_vector` | tsvector | Generated column for full-text search |
| `created_at` | timestamptz | Auto-set |

Row-Level Security is enabled on all tables. Users can only read and write their own rows.

**`public.search_items` (RPC)** — Postgres function that accepts a query embedding vector and returns items ranked by cosine similarity. Used by the Flutter `SearchService`.

---

## Prerequisites

The following must be installed and configured before running the project locally.

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.19.0
- [Dart SDK](https://dart.dev/get-dart) >= 3.9.2 (bundled with Flutter)
- [Supabase CLI](https://supabase.com/docs/guides/cli) >= 1.0.0
- [Deno](https://deno.com) >= 1.40 (required to run Edge Functions locally)
- A [Supabase](https://supabase.com) project with the `vector` extension enabled
- An [OpenAI](https://platform.openai.com) API key with access to GPT-4o and the Embeddings API
- A [Firebase](https://firebase.google.com) project (required only for push notifications)

---

## Local Setup

**1. Clone the repository**

```bash
git clone https://github.com/jucruz/stocksense.git
cd stocksense
```

**2. Install Flutter dependencies**

```bash
flutter pub get
```

**3. Configure environment variables**

```bash
cp .env.example .env
```

Open `.env` and fill in your Supabase project URL and anon key. See [Environment Variables](#environment-variables) for details.

**4. Configure Supabase**

See the [Supabase Configuration](#supabase-configuration) section below.

**5. Run the app**

```bash
flutter run
```

To target a specific platform explicitly:

```bash
flutter run -d chrome       # Web
flutter run -d android
flutter run -d ios
```

---

## Environment Variables

Copy `.env.example` to `.env` and supply the following values. This file must never be committed to version control.

```env
# Supabase — found in: Supabase Dashboard > Project Settings > API
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-public-key
```

The OpenAI and Firebase keys are not stored in the Flutter app. They are set as Supabase Edge Function secrets (see below) and never exposed to the client.

---

## Supabase Configuration

**Link your project**

```bash
supabase link --project-ref <your-project-ref>
```

**Apply all database migrations**

```bash
supabase db push
```

This runs all files under `supabase/migrations/` in order, creating the `users`, `items`, and `scans` tables, enabling Row-Level Security, and setting up the pgvector index and `search_items` RPC.

**Deploy Edge Functions**

```bash
supabase functions deploy analyze-image
supabase functions deploy generate-embedding
supabase functions deploy send-notifications
```

**Set Edge Function secrets**

These secrets are injected at runtime into the deployed Edge Functions and are never stored in the repository.

```bash
supabase secrets set OPENAI_API_KEY=<your-openai-key>
supabase secrets set FIREBASE_PROJECT_ID=<your-firebase-project-id>
supabase secrets set FIREBASE_SERVICE_ACCOUNT='<your-service-account-json>'
```

**Push notifications (optional)**

For Android, place `google-services.json` in `android/app/`. For iOS, place `GoogleService-Info.plist` in `ios/Runner/`. The `send-notifications` function is designed to be invoked by a `pg_cron` job scheduled in the Supabase dashboard. Refer to `supabase/migrations/20260528000002_add_notifications_infrastructure.sql` for the recommended cron schedule.

---

## Running the App

Once setup is complete:

```bash
flutter run
```

The app will connect to your Supabase project using the credentials in `.env`. Create an account via the sign-up screen to get started.

For the web build used in production:

```bash
flutter build web --release
firebase deploy --only hosting
```

---

## Author

Juan Cruz — jucruz@student.neumont.edu
