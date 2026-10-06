import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../shared/models/memory.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/memory_photo.dart';
import '../../../../shared/widgets/motion_widgets.dart';

class DiscoveryMemoryCard extends StatelessWidget {
  const DiscoveryMemoryCard({
    super.key,
    required this.memory,
    required this.distance,
    required this.selected,
    required this.onTap,
    this.onAuthorTap,
    this.availableHeight = 0,
  });
  final double availableHeight;
  final Memory memory;
  final double? distance;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          final note = TextPainter(
            text: TextSpan(
              text: memory.textNote,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            maxLines: 2,
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(
              maxWidth: (constraints.maxWidth - 24).clamp(1, double.infinity),
            );
          final verticalHeight = (constraints.maxWidth - 24) * 9 / 16 +
              note.height +
              scaler.scale(12) * 4.5 +
              92;
          note.dispose();
          final vertical = selected &&
              memory.photoUrl.isNotEmpty &&
              availableHeight >= verticalHeight;
          return Semantics(
            selected: selected,
            child: PressFeedback(
              child: AnimatedContainer(
                duration: AppMotion.duration(context),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: selected
                      ? const [
                          BoxShadow(color: AppColors.peachGlow, blurRadius: 16),
                        ]
                      : const [],
                ),
                child: Material(
                  color: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    side: BorderSide(
                      color: selected ? AppColors.peach : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (vertical) ...[
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.card),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: MemoryPhotoTransition(
                                  tag: 'map-memory-${memory.id}',
                                  child: MemoryPhoto(path: memory.photoUrl),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              if (!vertical && memory.photoUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.card),
                                  child: MemoryPhotoTransition(
                                    tag: 'map-memory-${memory.id}',
                                    child: MemoryPhoto(
                                      path: memory.photoUrl,
                                      width: selected ? 96 : 64,
                                      height: selected ? 112 : 80,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: onAuthorTap,
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(minHeight: 44),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor:
                                                    AppColors.accentMuted,
                                                child: Text(
                                                  memory.creatorUsername.isEmpty
                                                      ? '?'
                                                      : memory.creatorUsername
                                                          .characters.first
                                                          .toUpperCase(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color:
                                                              AppColors.peach,),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '@${memory.creatorUsername}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color:
                                                              AppColors.peach,),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      memory.textNote,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    MemoryInfo(
                                        memory: memory, distance: distance,),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
