// path: lib/core/extensions/string_extensions.dart

import '../constants/app_constants.dart';

/// String validation and sanitization extensions for GoStory.
extension StringValidation on String {
  /// Returns the trimmed string, or null if it's empty/whitespace-only.
  String? get trimmedOrNull {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Whether this string is a valid memory note.
  ///
  /// A valid note:
  /// - Is not empty after trimming
  /// - Is not only whitespace
  /// - Is within [AppConstants.maxNoteLength] characters after trimming
  bool get isValidNote {
    final trimmed = trim();
    return trimmed.isNotEmpty && trimmed.length <= AppConstants.maxNoteLength;
  }

  /// Returns a note validation error message, or null if valid.
  String? get noteValidationError {
    final trimmed = trim();
    if (trimmed.isEmpty) {
      return 'Bir not bırakmalısın.';
    }
    if (trimmed.length > AppConstants.maxNoteLength) {
      return 'Not en fazla ${AppConstants.maxNoteLength} karakter olabilir.';
    }
    return null;
  }
}
