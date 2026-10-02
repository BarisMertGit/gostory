import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class LeaveMemoryButton extends StatelessWidget {
  const LeaveMemoryButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: const Text('Anı bırak'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.peach,
          foregroundColor: AppColors.onPeach,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
}

class DiscoveryControls extends StatelessWidget {
  const DiscoveryControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
    this.compact = false,
  });
  final VoidCallback onZoomIn, onZoomOut, onLocate;
  final bool compact;

  Widget _button(IconData icon, String label, VoidCallback action) =>
      IconButton(
        tooltip: label,
        onPressed: action,
        icon: Icon(icon, size: 21),
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: AppColors.textPrimary,
        ),
      );

  @override
  Widget build(BuildContext context) => compact ? Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _button(Icons.add, 'Yakınlaştır', onZoomIn),
      _button(Icons.remove, 'Uzaklaştır', onZoomOut),
      _button(Icons.my_location, 'Konumuma dön', onLocate),
    ]),
  ) : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                _button(Icons.add, 'Yakınlaştır', onZoomIn),
                _button(Icons.remove, 'Uzaklaştır', onZoomOut),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: _button(Icons.my_location, 'Konumuma dön', onLocate),
          ),
        ],
      );
}
