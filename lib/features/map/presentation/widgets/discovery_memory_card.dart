import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/models/memory.dart';
import '../../../../shared/widgets/memory_photo.dart';

class DiscoveryMemoryCard extends StatelessWidget {
  const DiscoveryMemoryCard({
    super.key,
    required this.memory,
    required this.distance,
    required this.selected,
    required this.onTap,
    this.onAuthorTap,
  });
  final Memory memory;
  final double? distance;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        child: Material(
          color: AppColors.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
              child: Row(
                children: [
                  if (memory.photoUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: MemoryPhoto(
                        path: memory.photoUrl,
                        width: 60,
                        height: 72,
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
                                  child: Text(
                                    '@${memory.creatorUsername}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.peach,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),),),
                        const SizedBox(height: 4),
                        Text(
                          memory.textNote,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          memory.locationLabel,
                          style: const TextStyle(color: AppColors.mapSecondary),
                        ),
                        Text(
                          distance == null
                              ? MaterialLocalizations.of(context)
                                  .formatMediumDate(memory.createdAt.toLocal())
                              : distance! < 1000
                                  ? '${distance!.round()} m uzaklıkta'
                                  : '${(distance! / 1000).toStringAsFixed(1)} km uzaklıkta',
                          style: const TextStyle(
                            color: AppColors.mapSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
