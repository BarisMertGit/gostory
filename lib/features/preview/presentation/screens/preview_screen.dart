import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/location_access.dart';
import '../../../../shared/widgets/location_chip.dart';
import '../../../../shared/widgets/memory_photo.dart';
import '../../../../shared/widgets/motion_widgets.dart';
import '../providers/preview_provider.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({required this.photoPath, super.key});
  final String photoPath;
  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  String get photoPath => widget.photoPath;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(
      text: ref.read(previewProvider(photoPath)).noteText,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(draftLocationProvider) == null) {
        requestDeviceLocation(context, ref);
      }
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final success =
        await ref.read(previewProvider(photoPath).notifier).submit();
    if (!mounted || !success) return;
    // Wait for PopScope to reflect the completed submission.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.peach,
                size: 20,
              ),
              SizedBox(width: AppSpacing.gap),
              Expanded(child: Text('Anın cihazına kaydedildi.')),
            ],
          ),
        ),
      );
    });
    WidgetsBinding.instance.scheduleFrame();
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
        appBar: AppBar(title: const Text('Anını paylaş')),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                  ),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: ParallaxPhoto(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MemoryPhoto(path: photoPath),
                              const IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.center,
                                      colors: [
                                        Color(0x550B1718),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Yeniden çek'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassSurface(
                      child: TextField(
                        controller: _note,
                        maxLength: 100,
                        minLines: 2,
                        maxLines: 4,
                        enabled: !state.isSubmitting,
                        scrollPadding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: const InputDecoration(
                          labelText: 'Kısa bir not',
                          hintText: 'Bu anın hikâyesi ne?',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: ref
                            .read(previewProvider(photoPath).notifier)
                            .updateNote,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Entrance(
                        horizontal: true,
                        child: LocationChip(enabled: !state.isSubmitting),
                      ),
                    ),
                    if (location == null && access.failure != null)
                      const LocationFeedback(),
                    if (state.validationError != null)
                      StatusNotice(
                        message: state.validationError!,
                        kind: StatusKind.error,
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedContainer(
                      duration: AppMotion.duration(context),
                      decoration: BoxDecoration(
                        color: state.isPublic
                            ? AppColors.accentGlow
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        child: SwitchListTile(
                          // Supported by the declared Flutter 3.27 baseline.
                          // ignore: deprecated_member_use
                          activeColor: AppColors.onPeach,
                          activeTrackColor: AppColors.peach,
                          inactiveThumbColor: AppColors.textSecondary,
                          inactiveTrackColor: AppColors.surfaceVariant,
                          thumbIcon: WidgetStateProperty.resolveWith(
                            (states) => Icon(
                              states.contains(WidgetState.selected)
                                  ? Icons.public
                                  : Icons.lock_outline,
                              size: 14,
                              color: states.contains(WidgetState.selected)
                                  ? AppColors.peach
                                  : AppColors.surfaceVariant,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Herkese açık',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            'Fotoğraf, not ve konum diğer kullanıcılara görünür.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          value: state.isPublic,
                          onChanged: state.isSubmitting
                              ? null
                              : ref
                                  .read(previewProvider(photoPath).notifier)
                                  .setPublic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scaffold resizes this footer above the keyboard; only the form scrolls.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.gap,
                  AppSpacing.screenPadding,
                  AppSpacing.gap,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: PrimaryAction(
                  busy: state.isSubmitting,
                  busyLabel: 'Kaydediliyor…',
                  onPressed:
                      state.isSubmitting || !state.isValid || location == null
                          ? null
                          : _submit,
                  icon: Icons.add_location_alt_outlined,
                  label: 'Anıyı paylaş',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
