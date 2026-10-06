import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'design.dart';
import 'typography.dart' as app_type;

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: app_type.AppTypography.body,
    );
    const text = TextTheme(
      headlineMedium: TextStyle(
        fontFamily: app_type.AppTypography.heading,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -.5,
      ),
      headlineSmall: TextStyle(
        fontFamily: app_type.AppTypography.heading,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: app_type.AppTypography.heading,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontFamily: app_type.AppTypography.heading,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleSmall: TextStyle(
        fontFamily: app_type.AppTypography.heading,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontFamily: app_type.AppTypography.body,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: app_type.AppTypography.body,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: app_type.AppTypography.body,
        fontSize: 12,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontFamily: app_type.AppTypography.heading,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontFamily: app_type.AppTypography.body,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: app_type.AppTypography.body,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: const BorderSide(color: AppColors.divider),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        surfaceContainer: AppColors.surfaceVariant,
        primary: AppColors.peach,
        onPrimary: AppColors.onPeach,
        secondary: AppColors.peach,
        onSecondary: AppColors.onPeach,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.divider,
        error: AppColors.error,
        onError: AppColors.onPeach,
      ),
      textTheme: base.textTheme.merge(text).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          fontFamily: app_type.AppTypography.heading,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          animationDuration: AppMotion.standard,
          backgroundColor: AppColors.peach,
          foregroundColor: AppColors.onPeach,
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size(AppSizes.touchTarget, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: app_type.AppTypography.heading,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          animationDuration: AppMotion.standard,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider),
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: app_type.AppTypography.heading,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.peach,
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          textStyle: const TextStyle(
            fontFamily: app_type.AppTypography.heading,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          shape: shape,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.peach.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.all(16),
        hintStyle: const TextStyle(
          fontFamily: app_type.AppTypography.body,
          color: AppColors.textSecondary,
        ),
        labelStyle: const TextStyle(
          fontFamily: app_type.AppTypography.body,
          color: AppColors.textSecondary,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.peach, width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.peach,
        selectionColor: AppColors.accentMuted,
        selectionHandleColor: AppColors.peach,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navigation,
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.peachGlow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: app_type.AppTypography.body,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.peach
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.peach
                : AppColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(
          fontFamily: app_type.AppTypography.body,
          color: AppColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
