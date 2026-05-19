import 'package:flutter/material.dart';

/// Color palette for StockSense.
///
/// All values are taken directly from the design system defined in the
/// project pitch: dark navy backgrounds, green primary, and semantic
/// colors for expiry warnings, errors, and status indicators.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Green — primary brand color
  // ---------------------------------------------------------------------------

  /// Bright action green — buttons, active states, AI badges.
  static const Color green = Color(0xFF22C55E);

  /// Darker green — hover / pressed states.
  static const Color greenDark = Color(0xFF16A34A);

  /// Deep forest green — app bar, header backgrounds, filled chip.
  static const Color greenDeep = Color(0xFF166534);

  /// Light mint — tags, success banners, tinted card backgrounds.
  static const Color greenLight = Color(0xFFDCFCE7);

  /// Darkest green tint — AI search bar background, subtle fills.
  static const Color greenSubtle = Color(0xFF0F2D1A);

  // ---------------------------------------------------------------------------
  // Semantic — error / warning / info / teal
  // ---------------------------------------------------------------------------

  /// Red — expired items, destructive actions, high-risk indicators.
  static const Color error = Color(0xFFEF4444);

  /// Light red — error chip / banner backgrounds.
  static const Color errorLight = Color(0xFFFEE2E2);

  /// Dark red — error chip text, error header backgrounds.
  static const Color errorDark = Color(0xFF991B1B);

  /// Orange — items expiring soon, medium-risk indicators.
  static const Color warning = Color(0xFFF97316);

  /// Light orange — warning chip backgrounds.
  static const Color warningLight = Color(0xFFFFEDD5);

  /// Dark orange — warning chip text.
  static const Color warningDark = Color(0xFF9A3412);

  /// Blue — informational accents, hardware / tech cards.
  static const Color info = Color(0xFF3B82F6);

  /// Light blue — info chip backgrounds.
  static const Color infoLight = Color(0xFFDBEAFE);

  /// Dark blue — deep info accents, scan-mode overlay.
  static const Color infoDark = Color(0xFF1D4ED8);

  /// Teal — AI pipeline indicators, Edge Function cards.
  static const Color teal = Color(0xFF14B8A6);

  /// Light teal — teal chip backgrounds.
  static const Color tealLight = Color(0xFFCCFBF1);

  /// Dark teal — teal chip text.
  static const Color tealDark = Color(0xFF0F766E);

  /// Purple — AI / ML feature accents, vector search badges.
  static const Color purple = Color(0xFF8B5CF6);

  /// Light purple — purple chip backgrounds.
  static const Color purpleLight = Color(0xFFEDE9FE);

  /// Dark purple — purple chip text.
  static const Color purpleDark = Color(0xFF6D28D9);

  // ---------------------------------------------------------------------------
  // Backgrounds — dark theme layers
  // ---------------------------------------------------------------------------

  /// Deepest background — scaffold, camera overlay, hero cover.
  static const Color backgroundDark = Color(0xFF111827); // gray-900

  /// Card / surface background — list tiles, modal sheets, nav bar.
  static const Color surfaceDark = Color(0xFF1F2937); // gray-800

  /// Input borders, dividers, secondary surfaces.
  static const Color surfaceVariant = Color(0xFF374151); // gray-700

  /// Absolute darkest — used for camera viewfinder, deep overlays.
  static const Color overlay = Color(0xFF0F172A);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Primary text — headings, item names, values.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text — subtitles, quantities, secondary labels.
  static const Color textSecondary = Color(0xFF9CA3AF); // gray-400

  /// Muted text — hints, placeholders, timestamps.
  static const Color textMuted = Color(0xFF6B7280); // gray-500

  /// Subtle text — section labels, overlines (uppercase captions).
  static const Color textSubtle = Color(0xFF4B5563); // gray-600

  // ---------------------------------------------------------------------------
  // Borders & dividers
  // ---------------------------------------------------------------------------

  /// Standard border — card outlines, input borders.
  static const Color border = Color(0xFF374151); // gray-700

  /// Subtle border — section separators, inner dividers.
  static const Color borderSubtle = Color(0xFF1F2937); // gray-800

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
}
