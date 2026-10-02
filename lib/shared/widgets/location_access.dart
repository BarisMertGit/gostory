import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/services/location_service.dart';
import '../../core/widgets/permission_explanation.dart';
import '../providers/location_provider.dart';

Future<void> requestDeviceLocation(BuildContext context, WidgetRef ref) async {
  await ref.read(locationAccessProvider.notifier).locate(
        confirm: () => context.mounted
            ? explainPermission(context, message: locationExplanation)
            : Future.value(false),
      );
  if (!context.mounted) return;
  if (ref.read(locationAccessProvider).failure?.problem ==
      LocationProblem.blocked) {
    await _settings(context, ref);
  }
}

Future<void> _settings(BuildContext context, WidgetRef ref) async {
  if (await explainPermission(
        context,
        settings: true,
        message:
            'Konum erişimi sistem tarafından engellenmiş. İzni cihaz ayarlarından açabilirsin. Haritayı elle kullanmaya devam edebilirsin.',
      ) &&
      context.mounted) {
    await ref.read(locationAccessProvider.notifier).openSettings();
  }
}

class LocationFeedback extends ConsumerWidget {
  const LocationFeedback({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationAccessProvider);
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Konum alınıyor…',
              style: TextStyle(color: AppColors.mapSecondary),
            ),
          ],
        ),
      );
    }
    final failure = state.failure;
    if (failure == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failure.message,
            style: const TextStyle(color: AppColors.mapSecondary, fontSize: 12),
          ),
          Wrap(
            children: [
              if (failure.problem == LocationProblem.blocked)
                TextButton(
                  onPressed: () => _settings(context, ref),
                  child: const Text('Ayarları aç'),
                )
              else
                TextButton(
                  onPressed: () => requestDeviceLocation(context, ref),
                  child: const Text('Tekrar dene'),
                ),
              if (failure.problem == LocationProblem.servicesDisabled)
                TextButton(
                  onPressed: () => ref
                      .read(locationAccessProvider.notifier)
                      .openSettings(locationService: true),
                  child: const Text('Konum ayarları'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
