import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/colors.dart';

void main() {
  double contrast(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
  }

  test('body, hint, secondary and error text pass AA on app surfaces', () {
    for (final background in [
      AppColors.mapSurface,
      AppColors.background,
      AppColors.surface,
      AppColors.card,
      AppColors.surfaceVariant,
    ]) {
      for (final foreground in [
        AppColors.textPrimary,
        AppColors.textSecondary,
        AppColors.textTertiary,
        AppColors.textHint,
        AppColors.error,
      ]) {
        expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
      }
    }
    expect(
      contrast(AppColors.onPeach, AppColors.peach),
      greaterThanOrEqualTo(4.5),
    );
  });
}
