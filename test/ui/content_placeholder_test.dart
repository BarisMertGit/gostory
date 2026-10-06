import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/shared/widgets/content_placeholder.dart';

void main() {
  for (final entry in <String, Widget>{
    'Profil yükleniyor': const ProfilePlaceholder(),
    'Anılar yükleniyor': const MemoryGridPlaceholder(),
    'Harita ve anılar yükleniyor': const MapPlaceholder(),
  }.entries) {
    testWidgets('${entry.key}: accessible static layout with large text',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(body: SafeArea(child: entry.value)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(entry.key), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  }
}
