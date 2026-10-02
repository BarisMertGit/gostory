import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../core/services/location_service.dart';
import '../providers/location_provider.dart';
import 'location_access.dart';

class LocationPermissionBand extends ConsumerWidget {
  const LocationPermissionBand({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(locationAccessProvider);
    if (access.position != null) return const SizedBox.shrink();
    final issue = access.failure?.problem;
    final settings = issue == LocationProblem.blocked || issue == LocationProblem.servicesDisabled;
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
    final message = access.busy ? 'Konumun bulunuyor…' : 'Yakınındaki anılar için konumunu aç.';
    final action = access.busy ? null : TextButton(
      onPressed: () => settings
          ? ref.read(locationAccessProvider.notifier).openSettings(locationService: issue == LocationProblem.servicesDisabled)
          : requestDeviceLocation(context, ref),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), textStyle: Theme.of(context).textTheme.labelMedium),
      child: Text(settings ? 'Ayarlar' : issue == null || issue == LocationProblem.denied ? 'İzin ver' : 'Tekrar dene'),
    );
    final content = Row(children: [
      if (access.busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
      else const Icon(Icons.location_on_outlined, size: 18, color: AppColors.peach),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
      if (!largeText && action != null) ...[const SizedBox(width: 4), action],
    ]);
    return Semantics(liveRegion: true, child: Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: EdgeInsets.fromLTRB(12, largeText ? 12 : 4, 8, 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: largeText ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [content, if (action != null) action]) : content,
    ));
  }
}
