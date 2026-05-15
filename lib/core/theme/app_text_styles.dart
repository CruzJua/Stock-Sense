import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text style scale for StockSense using the Inter typeface.
///
/// Weights and letter-spacing values match the pitch document's
/// design language (900 for hero titles, 800 for section headers,
/// 700 for card titles, 400–500 for body copy).
abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // Display — hero / cover titles
  // ---------------------------------------------------------------------------

  /// 52px / Black (900) — cover page app name.
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 52,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  // ---------------------------------------------------------------------------
  // Headline — section and screen titles
  // ---------------------------------------------------------------------------

  /// 26px / ExtraBold (800) — screen-level section titles.
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  /// 20px / Bold (700) — modal sheet headers, large card titles.
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// 15px / Bold (700) — card headings, list section headers.
  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ---------------------------------------------------------------------------
  // Title — navigation, app bar, dialogs
  // ---------------------------------------------------------------------------

  /// 18px / SemiBold (600) — app bar title, dialog title.
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// 15px / SemiBold (600) — list item primary text, button labels.
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// 13px / SemiBold (600) — compact card titles, small button labels.
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ---------------------------------------------------------------------------
  // Body — content / descriptive text
  // ---------------------------------------------------------------------------

  /// 14px / Regular (400) — default body copy, descriptions.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  /// 13px / Regular (400) — secondary body, card content, list subtitles.
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  /// 12px / Regular (400) — fine print, timestamps, helper text.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Label — chips, badges, tags, captions
  // ---------------------------------------------------------------------------

  /// 12px / SemiBold (600) — tag text, badge labels.
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08,
        color: AppColors.textSecondary,
      );

  /// 11px / Bold (700) — ALL-CAPS section overlines, chip text.
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
        color: AppColors.textMuted,
      );

  /// 10px / Medium (500) — micro labels, bottom nav labels.
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04,
        color: AppColors.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Overline — section captions rendered in ALL CAPS
  // ---------------------------------------------------------------------------

  /// 11px / Bold (700) / green — "RECENT ITEMS", "AI DETECTED" headers.
  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
        color: AppColors.green,
      );

  /// Same as [overline] but in muted gray — neutral section labels.
  static TextStyle get overlineMuted => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
        color: AppColors.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Stat — dashboard numeric values
  // ---------------------------------------------------------------------------

  /// 28px / ExtraBold (800) / green — inventory count, items found.
  static TextStyle get statValue => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.green,
      );

  /// 28px / ExtraBold (800) / red — expiring / warning count.
  static TextStyle get statValueWarning => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.error,
      );

  /// 11px / Regular (400) — stat card sub-labels ("Items", "Expiring").
  static TextStyle get statLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.06,
        color: AppColors.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Expiry indicators — inline list item status
  // ---------------------------------------------------------------------------

  /// 7–9px / Regular — "exp soon" orange text in list rows.
  static TextStyle get expiryWarning => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: AppColors.warning,
      );

  /// 7–9px / Regular — "exp!" red text in list rows.
  static TextStyle get expiryDanger => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: AppColors.error,
      );

  /// 7–9px / Regular — days remaining in muted gray.
  static TextStyle get expiryOk => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );
}
