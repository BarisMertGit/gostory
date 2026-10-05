import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/features/preview/presentation/providers/preview_provider.dart';
import 'package:gostory/features/preview/presentation/screens/preview_screen.dart';
import 'package:gostory/shared/widgets/location_chip.dart';
import 'package:gostory/shared/widgets/memory_photo.dart';
import 'package:latlong2/latlong.dart';

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'preview at $width / $scale: keyboard, busy guard and draft recovery',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        const path = '/missing-layout-photo.jpg';
        const note = 'Bu anının notu hata olsa da korunmalı.';
        final save = Completer<void>();
        var submissions = 0;
        final notifier = PreviewNotifier(
          photoPath: path,
          saveDraft: (_) {
            submissions++;
            return save.future;
          },
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              previewProvider(path).overrideWith((ref) => notifier),
              draftLocationProvider.overrideWith((ref) => const LatLng(41, 29)),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 44, bottom: 24),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const PreviewScreen(photoPath: path),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), note);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final share = find.widgetWithText(FilledButton, 'Anıyı paylaş');
        expect(share.hitTestable(), findsOneWidget);
        expect(tester.getRect(share).bottom, lessThanOrEqualTo(544));
        expect(tester.takeException(), isNull);
        await tester.tap(share);
        await tester.pump();
        final busy = find.widgetWithText(FilledButton, 'Kaydediliyor…');
        expect(tester.widget<FilledButton>(busy).onPressed, isNull);
        expect(await notifier.submit(), isFalse);
        expect(submissions, 1);
        tester.view.resetViewInsets();
        tester.testTextInput.hide();
        save.completeError(StateError('test storage failure'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          note,
        );
        expect(tester.widget<FilledButton>(share).onPressed, isNotNull);
        await tester.scrollUntilVisible(
          find.textContaining('Anı kaydedilemedi.'),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(notifier.state.validationError, isNotNull);
        expect(
          find.textContaining('Anı kaydedilemedi.').hitTestable(),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.byType(MemoryPhoto),
          -200,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(tester.widget<MemoryPhoto>(find.byType(MemoryPhoto)).path, path);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
