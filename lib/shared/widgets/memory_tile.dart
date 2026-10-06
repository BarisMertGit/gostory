import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';
import '../../app/theme/spacing.dart';
import '../../core/utils/memory_labels.dart';
import '../models/memory.dart';
import 'app_components.dart';
import 'memory_photo.dart';
import 'motion_widgets.dart';

class MemoryTile extends StatelessWidget {
  const MemoryTile({
    super.key,
    required this.memory,
    required this.onTap,
    this.actions,
    this.heroTag,
    this.photoAspectRatio = 1,
  });
  final Memory memory;
  final VoidCallback onTap;
  final Widget? actions;
  final Object? heroTag;
  final double photoAspectRatio;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final note = Text(
      memory.textNote,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(fontWeight: FontWeight.w500, height: 1.5),
    );
    return PressFeedback(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: photoAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MemoryPhotoTransition(
                      tag: heroTag,
                      child: MemoryPhoto(path: memory.photoUrl),
                    ),
                    if (!largeText) ...[
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xE60B1718)],
                              stops: [.35, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(left: 12, right: 12, bottom: 12, child: note),
                    ],
                    if (actions != null)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Material(
                          color: AppColors.overlayDarker,
                          borderRadius: BorderRadius.circular(AppRadii.control),
                          child: actions,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (largeText) ...[
                      note,
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    DefaultTextStyle(
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: AppColors.textSecondary),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoLabel(
                            icon: Icons.location_on_outlined,
                            label: memory.locationLabel,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          InfoLabel(
                            icon: Icons.calendar_today_outlined,
                            label: memoryDateLabel(memory.createdAt),
                          ),
                        ],
                      ),
                    ),
                    if (memory.syncPending) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Yükleme bekliyor',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
