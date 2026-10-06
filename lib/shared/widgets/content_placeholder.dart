import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';
import '../../app/theme/spacing.dart';
import 'app_components.dart';

/// Quiet placeholders reserve content space without perpetual shimmer.
class PlaceholderBlock extends StatelessWidget {
  const PlaceholderBlock({super.key, this.width, required this.height});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
      );
}

class MemoryGridPlaceholder extends StatelessWidget {
  const MemoryGridPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Anılar yükleniyor',
        liveRegion: true,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    MediaQuery.textScalerOf(context).scale(14) > 18.2
                        ? 1
                        : ((constraints.maxWidth + AppSpacing.gap) / 160)
                            .floor()
                            .clamp(1, 3);
                final width =
                    (constraints.maxWidth - (columns - 1) * AppSpacing.gap) /
                        columns;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.gap),
                      SizedBox(
                        width: width,
                        child: Column(
                          children: [
                            PlaceholderBlock(height: width),
                            const SizedBox(height: AppSpacing.gap),
                            const PlaceholderBlock(height: 16),
                            const SizedBox(height: AppSpacing.sm),
                            PlaceholderBlock(height: 12, width: width * .65),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(title: 'Profil'),
            Semantics(
              label: 'Profil yükleniyor',
              liveRegion: true,
              child: const ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PlaceholderBlock(
                            width: AppSizes.avatar,
                            height: AppSizes.avatar,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PlaceholderBlock(height: 20),
                                SizedBox(height: AppSpacing.sm),
                                PlaceholderBlock(width: 80, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      PlaceholderBlock(height: 16),
                      SizedBox(height: AppSpacing.sm),
                      PlaceholderBlock(width: 140, height: 44),
                      SizedBox(height: AppSpacing.lg),
                      SectionHeading(title: 'Anılarım'),
                    ],
                  ),
                ),
              ),
            ),
            const MemoryGridPlaceholder(),
          ],
        ),
      );
}

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Harita ve anılar yükleniyor',
        liveRegion: true,
        child: const ExcludeSemantics(
          child: Column(
            children: [
              PageHeading(
                title: 'Keşfet',
                subtitle: 'Yakınındaki anıları keşfet',
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: PlaceholderBlock(height: 52),
              ),
              Expanded(
                child: ColoredBox(
                  color: AppColors.surface,
                  child: SizedBox.expand(),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: PlaceholderBlock(height: 20),
              ),
            ],
          ),
        ),
      );
}
