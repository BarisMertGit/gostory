import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';

/// Keep outside map overlays so attribution remains reachable at every extent.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  Future<void> _open(BuildContext context) async {
    try {
      if (await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      )) {
        return;
      }
    } catch (_) {
      // The attribution is still readable when a browser is unavailable.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı. Tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => _open(context),
          style: TextButton.styleFrom(
            animationDuration: AppMotion.duration(context),
            foregroundColor: AppColors.textSecondary,
            textStyle: Theme.of(context).textTheme.labelSmall,
          ),
          child: const Text('© OpenStreetMap contributors'),
        ),
      );
}
