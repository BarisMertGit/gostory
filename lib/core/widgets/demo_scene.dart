import 'package:flutter/material.dart';

/// Offline illustration shared by the simulator viewfinder and photo preview.
class DemoScene extends StatelessWidget {
  const DemoScene({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF172A42), Color(0xFFBD795F), Color(0xFF152C3D)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_twilight, size: 140, color: Color(0xFFF0CFAC)),
            SizedBox(height: 24),
            Text(
              'İSTANBUL',
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 8,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Bir an, bir yer, bir hikâye.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
