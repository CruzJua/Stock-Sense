import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// The single source of truth for the StockSense visual theme.
///
/// Only a dark theme is provided — the app uses a dark-first design
/// matching the pitch document (dark navy backgrounds, green accent,
/// red/orange semantic colors for inventory status).
///
/// Usage in main.dart:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.darkTheme,
/// )
/// ```
abstract final class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _colorScheme,
        textTheme: _textTheme,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: _appBarTheme,
        cardTheme: _cardTheme,
        inputDecorationTheme: _inputDecorationTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        bottomNavigationBarTheme: _bottomNavTheme,
        navigationBarTheme: _navigationBarTheme,
        chipTheme: _chipTheme,
        dividerTheme: _dividerTheme,
        listTileTheme: _listTileTheme,
        iconTheme: _iconTheme,
        snackBarTheme: _snackBarTheme,
        floatingActionButtonTheme: _fabTheme,
        dialogTheme: _dialogTheme,
        bottomSheetTheme: _bottomSheetTheme,
        progressIndicatorTheme: _progressIndicatorTheme,
        switchTheme: _switchTheme,
        checkboxTheme: _checkboxTheme,
      );

  // ---------------------------------------------------------------------------
  // Color scheme
  // ---------------------------------------------------------------------------

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // Green primary
    primary: AppColors.green,
    onPrimary: AppColors.black,
    primaryContainer: AppColors.greenDeep,
    onPrimaryContainer: AppColors.greenLight,

    // Teal secondary
    secondary: AppColors.teal,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.tealDark,
    onSecondaryContainer: AppColors.tealLight,

    // Purple tertiary (AI / ML features)
    tertiary: AppColors.purple,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.purpleDark,
    onTertiaryContainer: AppColors.purpleLight,

    // Error / expiry
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorDark,
    onErrorContainer: AppColors.errorLight,

    // Surfaces
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,

    // Outlines
    outline: AppColors.border,
    outlineVariant: AppColors.borderSubtle,

    // Misc
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.white,
    onInverseSurface: AppColors.backgroundDark,
    inversePrimary: AppColors.greenDeep,
  );

  // ---------------------------------------------------------------------------
  // Text theme — Inter via Google Fonts
  // ---------------------------------------------------------------------------

  static TextTheme get _textTheme =>
      GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: AppTextStyles.displayLarge,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      );

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.greenDeep,
    foregroundColor: AppColors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // ---------------------------------------------------------------------------
  // Cards
  // ---------------------------------------------------------------------------

  static const CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surfaceDark,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
  );

  // ---------------------------------------------------------------------------
  // Input / search fields
  // The pitch shows a pill-shaped search bar with green border on focus.
  // ---------------------------------------------------------------------------

  static InputDecorationTheme get _inputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium,
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      );

  // ---------------------------------------------------------------------------
  // Elevated button — primary CTA ("Add to Inventory", "Mark as Used")
  // ---------------------------------------------------------------------------

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.titleSmall,
        ),
      );

  // ---------------------------------------------------------------------------
  // Outlined button — secondary actions ("Edit", "Cancel")
  // ---------------------------------------------------------------------------

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.titleSmall,
        ),
      );

  // ---------------------------------------------------------------------------
  // Text button — tertiary / inline actions ("skip", "Sign in")
  // ---------------------------------------------------------------------------

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green,
          textStyle: AppTextStyles.titleSmall,
        ),
      );

  // ---------------------------------------------------------------------------
  // Bottom navigation bar
  // ---------------------------------------------------------------------------

  static const BottomNavigationBarThemeData _bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceDark,
    selectedItemColor: AppColors.green,
    unselectedItemColor: AppColors.textMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  );

  // ---------------------------------------------------------------------------
  // Navigation bar (Material 3 variant)
  // ---------------------------------------------------------------------------

  static NavigationBarThemeData get _navigationBarTheme =>
      NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.greenSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.green, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall
                .copyWith(color: AppColors.green);
          }
          return AppTextStyles.labelSmall;
        }),
        elevation: 0,
        height: 64,
      );

  // ---------------------------------------------------------------------------
  // Chips — category filters, status tags
  // ---------------------------------------------------------------------------

  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.greenDeep,
        disabledColor: AppColors.surfaceVariant,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.green),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        showCheckmark: false,
      );

  // ---------------------------------------------------------------------------
  // Dividers
  // ---------------------------------------------------------------------------

  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  );

  // ---------------------------------------------------------------------------
  // List tiles — inventory rows
  // ---------------------------------------------------------------------------

  static const ListTileThemeData _listTileTheme = ListTileThemeData(
    tileColor: AppColors.surfaceDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    minVerticalPadding: 8,
    iconColor: AppColors.textMuted,
  );

  // ---------------------------------------------------------------------------
  // Icons
  // ---------------------------------------------------------------------------

  static const IconThemeData _iconTheme = IconThemeData(
    color: AppColors.textSecondary,
    size: 24,
  );

  // ---------------------------------------------------------------------------
  // Snack bars — feedback toasts
  // ---------------------------------------------------------------------------

  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionTextColor: AppColors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      );

  // ---------------------------------------------------------------------------
  // FAB — camera scan button
  // ---------------------------------------------------------------------------

  static const FloatingActionButtonThemeData _fabTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.green,
    foregroundColor: AppColors.black,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    shape: CircleBorder(),
  );

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  static DialogThemeData get _dialogTheme => DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      );

  // ---------------------------------------------------------------------------
  // Bottom sheet — item detail, confirmation panel
  // ---------------------------------------------------------------------------

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.surfaceDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    dragHandleColor: AppColors.border,
    showDragHandle: true,
  );

  // ---------------------------------------------------------------------------
  // Progress indicators — image upload / AI processing
  // ---------------------------------------------------------------------------

  static const ProgressIndicatorThemeData _progressIndicatorTheme =
      ProgressIndicatorThemeData(
    color: AppColors.green,
    linearTrackColor: AppColors.surfaceVariant,
    circularTrackColor: AppColors.surfaceVariant,
  );

  // ---------------------------------------------------------------------------
  // Switch — notification toggles
  // ---------------------------------------------------------------------------

  static SwitchThemeData get _switchTheme => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.green;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.greenSubtle;
          }
          return AppColors.surfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.green;
          return AppColors.border;
        }),
      );

  // ---------------------------------------------------------------------------
  // Checkbox — item selection in confirm screen
  // ---------------------------------------------------------------------------

  static CheckboxThemeData get _checkboxTheme => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.green;
          return AppColors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.black),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      );
}
