// path: lib/app/theme/typography.dart

import 'package:flutter/material.dart';

import 'colors.dart';

/// GoStory typography.
///
/// System sans-serif typography for older shared widgets.
abstract final class AppTypography {
  // Use system default sans-serif — clean across iOS and Android.

  // ── Display (Splash / hero text) ──
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ── Title (Section headings) ──
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.0,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ── Note text (the memory note itself) ──
  static const TextStyle noteInput = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  // ── Character counter ──
  static const TextStyle counter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  // ── Button text ──
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  // ── Error text ──
  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ── Hint text ──
  static const TextStyle hint = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.3,
    color: AppColors.textHint,
  );

  // ── Subtitle ──
  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  // ── Label (chips, badges, pills) ──
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  // ── Tiny (metadata, timestamps) ──
  static const TextStyle tiny = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.8,
    color: AppColors.textTertiary,
  );
}
