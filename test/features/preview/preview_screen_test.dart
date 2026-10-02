// path: test/features/preview/preview_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/features/preview/domain/memory_draft.dart';
import 'package:gostory/features/preview/presentation/providers/preview_provider.dart';

void main() {
  group('MemoryDraft', () {
    test('creates with required fields', () {
      const draft = MemoryDraft(
        photoPath: '/tmp/test.jpg',
        note: 'Burada seni gördüm.',
      );
      expect(draft.photoPath, equals('/tmp/test.jpg'));
      expect(draft.note, equals('Burada seni gördüm.'));
      expect(draft.latitude, isNull);
      expect(draft.longitude, isNull);
    });

    test('creates with optional location fields', () {
      const draft = MemoryDraft(
        photoPath: '/tmp/test.jpg',
        note: 'Test',
        latitude: 41.0082,
        longitude: 28.9784,
      );
      expect(draft.latitude, equals(41.0082));
      expect(draft.longitude, equals(28.9784));
    });

    test('toString does not expose note content', () {
      const draft = MemoryDraft(
        photoPath: '/tmp/test.jpg',
        note: 'Secret note here',
      );
      // toString should only show note length for privacy.
      expect(draft.toString(), contains('16 chars'));
      expect(draft.toString(), isNot(contains('Secret note here')));
    });
  });

  group('PreviewState', () {
    test('initial state has correct defaults', () {
      const state = PreviewState.initial();
      expect(state.noteText, isEmpty);
      expect(state.isValid, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.isSubmitted, isFalse);
      expect(state.validationError, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const state = PreviewState(
        noteText: 'hello',
        isValid: true,
        isSubmitting: false,
        isSubmitted: false,
      );

      final updated = state.copyWith(isSubmitting: true);
      expect(updated.noteText, equals('hello'));
      expect(updated.isValid, isTrue);
      expect(updated.isSubmitting, isTrue);
      expect(updated.isSubmitted, isFalse);
    });
  });

  group('PreviewNotifier', () {
    test('updateNote with valid text sets isValid to true', () {
      final notifier = PreviewNotifier(photoPath: '/tmp/test.jpg');

      notifier.updateNote('Burada seni gördüm.');
      expect(notifier.state.isValid, isTrue);
      expect(notifier.state.validationError, isNull);

      notifier.dispose();
    });

    test('updateNote with empty text sets isValid to false', () {
      final notifier = PreviewNotifier(photoPath: '/tmp/test.jpg');

      notifier.updateNote('');
      expect(notifier.state.isValid, isFalse);

      notifier.dispose();
    });

    test('updateNote with whitespace-only sets isValid to false', () {
      final notifier = PreviewNotifier(photoPath: '/tmp/test.jpg');

      notifier.updateNote('   ');
      expect(notifier.state.isValid, isFalse);

      notifier.dispose();
    });

    test('updateNote with 100 chars is valid', () {
      final notifier = PreviewNotifier(photoPath: '/tmp/test.jpg');

      notifier.updateNote('a' * 100);
      expect(notifier.state.isValid, isTrue);

      notifier.dispose();
    });

    test('submit with empty note returns false', () async {
      final notifier = PreviewNotifier(photoPath: '/tmp/test.jpg');

      final result = await notifier.submit();
      expect(result, isFalse);
      expect(notifier.state.validationError, isNotNull);

      notifier.dispose();
    });

    test('submit with valid note returns true', () async {
      final notifier =
          PreviewNotifier(photoPath: '/tmp/test.jpg', saveDraft: (_) async {});

      notifier.updateNote('Bu bir test notu.');
      final result = await notifier.submit();
      expect(result, isTrue);
      expect(notifier.state.isSubmitted, isTrue);

      notifier.dispose();
    });

    test('reset returns to initial state', () {
      final notifier = PreviewNotifier(photoPath: '/tmp/test.jpg');

      notifier.updateNote('Something');
      expect(notifier.state.noteText, equals('Something'));

      notifier.reset();
      expect(notifier.state.noteText, isEmpty);
      expect(notifier.state.isValid, isFalse);

      notifier.dispose();
    });
  });
}
