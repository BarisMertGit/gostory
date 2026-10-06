// path: lib/app/theme/typography.dart

import 'package:flutter/material.dart';

import 'colors.dart';

/// GoStory typography.
///
/// PlusJakartaSans for headings and display text (geometric, modern).
/// Inter for body and UI text (optimised for readability).
abstract final class AppTypography {
  /// Font family used for headings, display text and buttons.
  static const String heading = 'PlusJakartaSans';

  /// Font family used for body text, inputs and metadata.
  static const String body = 'Inter';

  // ── Display (Splash / hero text) ──
  static const TextStyle display = TextStyle(
    fontFamily: heading,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ── Title (Section headings) ──
  static const TextStyle title = TextStyle(
    fontFamily: heading,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ── Note text (the memory note itself) ──
  static const TextStyle noteInput = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  // ── Character counter ──
  static const TextStyle counter = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  // ── Button text ──
  static const TextStyle button = TextStyle(
    fontFamily: heading,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  // ── Error text ──
  static const TextStyle error = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ── Hint text ──
  static const TextStyle hint = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.3,
    color: AppColors.textHint,
  );

  // ── Subtitle ──
  static const TextStyle subtitle = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  // ── Label (chips, badges, pills) ──
  static const TextStyle label = TextStyle(
    fontFamily: body,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  // ── Tiny (metadata, timestamps) ──
  static const TextStyle tiny = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.8,
    color: AppColors.textTertiary,
  );
}
