import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/home_screen.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/features/onboarding/onboarding_gate.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:gostory/shared/widgets/app_components.dart';

import '../../test_helpers/empty_memory_store.dart';

class _Auth extends AuthService {
  @override
  Future<LocalUser> signIn() async =>
      const LocalUser(uid: 'onboarding', username: 'deniz');
}

void main() {
  for (final skip in [false, true]) {
    testWidgets(
        'onboarding ${skip ? 'skip' : 'completion'} persists on a short screen with large text',
        (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('gostory-onboarding-'),
      ))!;
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (_) async => directory.path,
      );
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await directory.delete(recursive: true);
      });
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(_Auth()),
            memoryStoreProvider.overrideWithValue(EmptyMemoryStore()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const OnboardingGate(),
          ),
        ),
      );
      Future<void> settleStorage() async {
        for (var attempt = 0; attempt < 12; attempt++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
        }
        await tester.pumpAndSettle();
      }

      await settleStorage();
      expect(find.byType(PageView), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (skip) {
        await tester.tap(find.text('Atla'));
      } else {
        for (var page = 0; page < 2; page++) {
          await tester.tap(
            find.descendant(
              of: find.byType(PrimaryAction),
              matching: find.byType(FilledButton),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Başla').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Başla'));
      }
      await settleStorage();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        await tester.runAsync(
          () => File('${directory.path}/onboarding_complete').readAsString(),
        ),
        '1',
      );
      expect(tester.takeException(), isNull);
      // Unmount before removing the temporary storage directory.
      await tester.pumpWidget(const SizedBox());
    });
  }
}
