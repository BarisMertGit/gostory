import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Small vector platform marks, without an icon-font dependency.
class SocialIcon extends StatelessWidget {
  const SocialIcon(this.platform, {super.key});
  final String platform;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(painter: _MarkPainter(platform)),
      );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.platform);
  final String platform;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = AppColors.peach
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fill = Paint()..color = AppColors.peach;
    switch (platform) {
      case 'Instagram':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(2, 2, 20, 20),
            const Radius.circular(6),
          ),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 12), 4.5, stroke);
        canvas.drawCircle(const Offset(18, 6), 1.2, fill);
      case 'X':
        canvas.drawPath(
          Path()
            ..moveTo(3, 2)
            ..lineTo(8, 2)
            ..lineTo(21, 22)
            ..lineTo(16, 22)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(20, 2), const Offset(3, 22), stroke);
      case 'YouTube':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(1, 4, 22, 16),
            const Radius.circular(5),
          ),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 8)
            ..lineTo(16, 12)
            ..lineTo(10, 16)
            ..close(),
          Paint()..color = AppColors.mapSurface,
        );
      default:
        canvas.drawPath(
          Path()
            ..moveTo(14, 3)
            ..lineTo(14, 16)
            ..cubicTo(14, 23, 3, 23, 4, 16)
            ..cubicTo(4, 12, 8, 12, 10, 13),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(14, 3)
            ..quadraticBezierTo(16, 9, 21, 8),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.platform != platform;
}
