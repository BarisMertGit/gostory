// path: test/features/preview/note_validation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/extensions/string_extensions.dart';

void main() {
  group('Note validation', () {
    group('isValidNote', () {
      test('valid note within limit', () {
        expect('Burada seni son kez gördüm.'.isValidNote, isTrue);
      });

      test('exactly 100 characters is valid', () {
        final note = 'a' * 100;
        expect(note.isValidNote, isTrue);
      });

      test('101 characters is invalid', () {
        final note = 'a' * 101;
        expect(note.isValidNote, isFalse);
      });

      test('empty string is invalid', () {
        expect(''.isValidNote, isFalse);
      });

      test('whitespace-only string is invalid', () {
        expect('   '.isValidNote, isFalse);
        expect('\t'.isValidNote, isFalse);
        expect('\n'.isValidNote, isFalse);
        expect('  \n  '.isValidNote, isFalse);
      });

      test('single character is valid', () {
        expect('x'.isValidNote, isTrue);
      });

      test('string with leading/trailing whitespace is valid after trim', () {
        expect('  hello  '.isValidNote, isTrue);
      });

      test('note with exactly 100 chars after trim is valid', () {
        final note = '  ${'b' * 100}  ';
        // After trim, it's 100 chars.
        expect(note.trim().isValidNote, isTrue);
      });
    });

    group('trimmedOrNull', () {
      test('returns trimmed string for valid input', () {
        expect('  hello  '.trimmedOrNull, equals('hello'));
      });

      test('returns null for empty string', () {
        expect(''.trimmedOrNull, isNull);
      });

      test('returns null for whitespace-only', () {
        expect('   '.trimmedOrNull, isNull);
      });

      test('returns string for single char', () {
        expect('a'.trimmedOrNull, equals('a'));
      });
    });

    group('noteValidationError', () {
      test('returns error for empty string', () {
        expect(''.noteValidationError, isNotNull);
        expect(''.noteValidationError, contains('not'));
      });

      test('returns error for whitespace-only', () {
        expect('   '.noteValidationError, isNotNull);
      });

      test('returns error for > 100 chars', () {
        final note = 'a' * 101;
        expect(note.noteValidationError, isNotNull);
        expect(note.noteValidationError, contains('100'));
      });

      test('returns null for valid note', () {
        expect('Bu geçici bir not.'.noteValidationError, isNull);
      });

      test('returns null for exactly 100 chars', () {
        final note = 'a' * 100;
        expect(note.noteValidationError, isNull);
      });
    });
  });
}
