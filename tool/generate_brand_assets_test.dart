import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('generate GoStory brand assets from vector geometry', () async {
    Future<void> render(
      String file,
      int size, {
      bool transparent = false,
    }) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(size / 1024);
      if (!transparent) {
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 1024, 1024),
          ui.Paint()..color = const ui.Color(0xFF14282B),
        );
      }
      final pin = ui.Path()
        ..moveTo(512, 160)
        ..cubicTo(341, 160, 224, 277, 224, 448)
        ..cubicTo(224, 628, 512, 864, 512, 864)
        ..cubicTo(512, 864, 800, 628, 800, 448)
        ..cubicTo(800, 277, 683, 160, 512, 160)
        ..close();
      canvas.drawPath(pin, ui.Paint()..color = const ui.Color(0xFFE5B68E));
      for (final x in [360.0, 548.0]) {
        final quote = ui.Path()
          ..moveTo(x, 360)
          ..lineTo(x + 116, 360)
          ..lineTo(x + 116, 476)
          ..lineTo(x + 60, 476)
          ..cubicTo(x + 60, 516, x + 32, 546, x, 560)
          ..lineTo(x, 506)
          ..cubicTo(x + 18, 495, x + 28, 486, x + 28, 476)
          ..lineTo(x, 476)
          ..close();
        canvas.drawPath(quote, ui.Paint()..color = const ui.Color(0xFF14282B));
      }
      final image = await recorder.endRecording().toImage(size, size);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      {
        final target = File(file);
        await target.parent.create(recursive: true);
        await target.writeAsBytes(bytes.buffer.asUint8List());
      }
      image.dispose();
    }

    final contents = await File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
    ).readAsString();
    final icons = (jsonDecode(contents) as Map)['images'] as List;
    for (final entry in icons) {
      final point = double.parse((entry['size'] as String).split('x').first);
      final scale = int.parse((entry['scale'] as String).substring(0, 1));
      await render(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry['filename']}',
        (point * scale).round(),
      );
    }
    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await render(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
      );
    }
    await render('docs/release/app-icon-512.png', 512);
    await render(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
      120,
      transparent: true,
    );
    await render(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png',
      240,
      transparent: true,
    );
    await render(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      360,
      transparent: true,
    );
  });
}
