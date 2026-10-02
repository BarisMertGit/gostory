import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/location_access.dart';
import '../../../../shared/widgets/location_chip.dart';
import '../providers/preview_provider.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({required this.photoPath, super.key});
  final String photoPath;
  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  String get photoPath => widget.photoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(draftLocationProvider) == null) {
        requestDeviceLocation(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(previewProvider(photoPath));
    final location = ref.watch(draftLocationProvider);
    final access = ref.watch(locationAccessProvider);
    ref.listen(locationAccessProvider, (_, next) {
      final position = next.position;
      if (position != null && ref.read(draftLocationProvider) == null) {
        ref.read(draftLocationProvider.notifier).state =
            LatLng(position.latitude, position.longitude);
      }
    });
    return PopScope(
      canPop: !state.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.mapSurface,
        appBar: AppBar(title: const Text('Anını paylaş')),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom,),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    semanticLabel: 'Paylaşılacak anı fotoğrafı',
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        'Fotoğraf açılamadı. Yeniden çekebilirsin.',
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      state.isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Yeniden çek'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLength: 100,
                minLines: 2,
                maxLines: 4,
                enabled: !state.isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Bu anın hikâyesi ne?',
                  labelStyle: TextStyle(color: AppColors.mapSecondary),
                  hintStyle: TextStyle(color: AppColors.mapSecondary),
                ),
                onChanged:
                    ref.read(previewProvider(photoPath).notifier).updateNote,
              ),
              const SizedBox(height: 12),
              const Align(
                  alignment: Alignment.centerLeft, child: LocationChip(),),
              if (location == null && access.failure != null)
                const LocationFeedback(),
              if (state.validationError != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.validationError!,
                    style: const TextStyle(color: Color(0xFFF3A29A)),
                  ),
                ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Herkese açık'),
                subtitle: const Text(
                  'Fotoğraf, not ve konum diğer kullanıcılara görünür.',
                ),
                value: state.isPublic,
                onChanged: state.isSubmitting
                    ? null
                    : ref.read(previewProvider(photoPath).notifier).setPublic,
              ),
              const SizedBox(height: 20),
              PrimaryAction(
                busy: state.isSubmitting,
                busyLabel: 'Kaydediliyor…',
                onPressed:
                    state.isSubmitting || !state.isValid || location == null
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            final success = await ref
                                .read(previewProvider(photoPath).notifier)
                                .submit();
                            if (context.mounted && success) {
                              // Pop after PopScope has reflected the completed submission.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Anın cihazına kaydedildi.'),
                                  ),
                                );
                              });
                              WidgetsBinding.instance.scheduleFrame();
                            }
                          },
                icon: Icons.add_location_alt_outlined,
                label: 'Anıyı paylaş',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
