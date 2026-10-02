import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

const locationExplanation =
    'Yakınındaki anıları göstermek ve paylaşımlarına konum eklemek için konum erişimine ihtiyacımız var.';
const cameraExplanation =
    'Fotoğraf çekip bulunduğun yere bir anı bırakabilmen için kamera erişimine ihtiyacımız var.';

Future<bool> explainPermission(
  BuildContext context, {
  required String message,
  bool settings = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.mapSurface,
        title: Text(settings ? 'İzni ayarlardan aç' : 'Erişim izni'),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.mapSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Şimdi değil'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.peach,
              foregroundColor: AppColors.mapSurface,
            ),
            child: Text(settings ? 'Ayarları aç' : 'Devam et'),
          ),
        ],
      ),
    ) ??
    false;
