// path: test/features/camera/camera_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/widgets/error_view.dart';
import 'package:gostory/features/camera/domain/camera_state.dart';
import 'package:gostory/features/camera/presentation/providers/camera_provider.dart';

void main() {
  group('CameraState', () {
    test('CameraLoading is correct type', () {
      const state = CameraLoading();
      expect(state, isA<CameraLoading>());
      expect(state, isA<CameraState>());
    });

    test('CameraReady is correct type', () {
      const state = CameraReady();
      expect(state, isA<CameraReady>());
    });

    test('CameraCaptured holds photo path', () {
      const state = CameraCaptured(photoPath: '/tmp/test.jpg');
      expect(state.photoPath, equals('/tmp/test.jpg'));
    });

    test('CameraError holds message', () {
      const state = CameraError(message: 'Test error');
      expect(state.message, equals('Test error'));
    });

    test('CameraPermissionDenied is correct type', () {
      const state = CameraPermissionDenied();
      expect(state, isA<CameraPermissionDenied>());
    });

    test('exhaustive pattern matching works', () {
      const CameraState state = CameraReady();
      final result = switch (state) {
        CameraIdle() => 'idle',
        CameraLoading() => 'loading',
        CameraReady() => 'ready',
        CameraCaptured() => 'captured',
        CameraError() => 'error',
        CameraPermissionDenied() => 'denied',
      };
      expect(result, equals('ready'));
    });
  });

  group('ErrorView widget', () {
    testWidgets('shows message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorView(message: 'Kameraya erişilemiyor.'),
        ),
      );

      expect(find.text('Kameraya erişilemiyor.'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorView(
            message: 'Kameraya erişilemiyor.',
            subtitle: 'Lütfen ayarlarınızı kontrol edin.',
          ),
        ),
      );

      expect(find.text('Lütfen ayarlarınızı kontrol edin.'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorView(
            message: 'Hata',
            onRetry: () => retryCount++,
          ),
        ),
      );

      expect(find.text('TEKRAR DENE'), findsOneWidget);

      await tester.tap(find.text('TEKRAR DENE'));
      expect(retryCount, equals(1));
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorView(message: 'Hata'),
        ),
      );

      expect(find.text('TEKRAR DENE'), findsNothing);
    });
  });

  group('CameraNotifier', () {
    test('initial state is CameraIdle', () {
      final notifier = CameraNotifier();
      expect(notifier.state, isA<CameraIdle>());
      notifier.dispose();
    });

    test('initialize with empty cameras sets error', () async {
      final notifier = CameraNotifier();
      await notifier.initialize([]);
      expect(notifier.state, isA<CameraError>());
      notifier.dispose();
    });
  });
}
