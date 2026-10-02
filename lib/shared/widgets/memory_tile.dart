import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';
import '../models/memory.dart';
import 'memory_photo.dart';

/// Photo-led archive card; actions come from the owning screen.
class MemoryTile extends StatelessWidget {
  const MemoryTile(
      {super.key, required this.memory, required this.onTap, this.actions,});
  final Memory memory;
  final VoidCallback onTap;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Stack(fit: StackFit.expand, children: [
              Semantics(
                  label: '${memory.textNote} fotoğrafı',
                  child: MemoryPhoto(path: memory.photoUrl),),
              if (actions != null)
                Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.control),
                      child: actions!,
                    ),),
            ],),),
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(memory.textNote,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,),
                      const SizedBox(height: 8),
                      Text(memory.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),),
                      const SizedBox(height: 4),
                      Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(memory.createdAt.toLocal()),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),),
                      if (memory.syncPending) ...[
                        const SizedBox(height: 4),
                        const Text('Yükleme bekliyor',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary,),),
                      ],
                    ],),),
          ],),
        ),
      );
}
