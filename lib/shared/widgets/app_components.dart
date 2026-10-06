import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';
import '../../app/theme/spacing.dart';
import '../../core/utils/memory_labels.dart';
import '../models/memory.dart';
import 'motion_widgets.dart';

/// Centers short states while allowing all content to scroll on small screens
/// and with larger system text. No fixed height is imposed on the content.
class AdaptiveStateBody extends StatelessWidget {
  const AdaptiveStateBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.screenPadding),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - padding.vertical)
                  .clamp(0.0, double.infinity),
            ),
            child: Align(
              alignment: const Alignment(0, -.25),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            ),
          ),
        ),
      );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (subtitle != null &&
                      MediaQuery.textScalerOf(context).scale(13) <= 20) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      );
}

/// A quiet surface shared by the photo starter, profile and form sections.
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.elevated = false,
    this.outlined = false,
    this.glass = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated, outlined, glass;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    if (glass) return GlassSurface(child: content);
    return Material(
      color: elevated ? AppColors.surfaceElevated : AppColors.surface,
      elevation: elevated ? 2 : 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: outlined
            ? const BorderSide(color: AppColors.divider)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.busyLabel = 'Bekleniyor…',
  });
  final String label, busyLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Text(busy ? busyLabel : label, textAlign: TextAlign.center);
    final action = busy ? null : onPressed;
    final style = FilledButton.styleFrom(
      backgroundColor:
          action == null ? AppColors.surfaceVariant : Colors.transparent,
      shadowColor: Colors.transparent,
      animationDuration: AppMotion.duration(context),
    );
    return Semantics(
      liveRegion: busy,
      child: PressFeedback(
        enabled: action != null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.control),
            gradient: action == null
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.peachLight, AppColors.peach],
                  ),
          ),
          child: busy || icon != null
              ? FilledButton.icon(
                  onPressed: action,
                  style: style,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textSecondary,),
                        )
                      : Icon(icon, size: 20),
                  label: text,
                )
              : FilledButton(onPressed: action, style: style, child: text),
        ),
      ),
    );
  }
}

class SecondaryAction extends StatelessWidget {
  const SecondaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          animationDuration: AppMotion.duration(context),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label, textAlign: TextAlign.center),
      );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.count});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.gap),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Text(
                '$count anı',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const JournalIllustration(size: 112),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Entrance(
              order: 1,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      );
}

class FilterControl extends StatelessWidget {
  const FilterControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedAlign(
                  alignment: AlignmentDirectional(
                      labels.length == 1
                          ? 0
                          : -1 + 2 * selected / (labels.length - 1),
                      0,),
                  duration: AppMotion.duration(context, AppMotion.emphasized),
                  curve: AppMotion.standardCurve,
                  child: FractionallySizedBox(
                    widthFactor: 1 / labels.length,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.small),
                        gradient: const LinearGradient(
                            colors: [AppColors.peachLight, AppColors.peach],),
                      ),
                    ),
                  ),
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < labels.length; index++)
                      Expanded(
                        child: Semantics(
                          selected: selected == index,
                          inMutuallyExclusiveGroup: true,
                          child: TextButton(
                            onPressed: () => onSelected(index),
                            style: TextButton.styleFrom(
                              animationDuration: AppMotion.duration(context),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.sm,),
                              foregroundColor: selected == index
                                  ? AppColors.onPeach
                                  : AppColors.textSecondary,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: selected == index
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                            child: Text(labels[index],
                                textAlign: TextAlign.center,),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Metadata wraps instead of squeezing location, date and measured distance.
class MemoryInfo extends StatelessWidget {
  const MemoryInfo({super.key, required this.memory, this.distance});
  final Memory memory;
  final double? distance;

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(color: AppColors.textSecondary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary,),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(memory.locationLabel,
                        maxLines: 2, overflow: TextOverflow.ellipsis,),),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.gap,
              runSpacing: AppSpacing.xs,
              children: [
                InfoLabel(
                    icon: Icons.calendar_today_outlined,
                    label: memoryDateLabel(memory.createdAt),),
                if (distance != null)
                  InfoLabel(
                      icon: Icons.near_me_outlined,
                      label: memoryDistanceLabel(distance!),),
              ],
            ),
          ],
        ),
      );
}

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    super.key,
    required this.username,
    required this.avatar,
    this.stats,
  });
  final String username;
  final Widget avatar;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('@$username', style: Theme.of(context).textTheme.titleMedium),
        if (stats != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            stats!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
    return MediaQuery.textScalerOf(context).scale(18) > 27
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarRing(child: avatar),
              const SizedBox(height: AppSpacing.md),
              identity,
            ],
          )
        : Row(
            children: [
              AvatarRing(child: avatar),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: identity),
            ],
          );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title, description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              color: AppColors.accentGlow, shape: BoxShape.circle,),
          child: Icon(icon, color: AppColors.peach, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          description,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      );
}

enum StatusKind { success, error, pending }

class StatusNotice extends StatelessWidget {
  const StatusNotice({
    super.key,
    required this.message,
    this.kind = StatusKind.pending,
  });
  final String message;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.gap),
          child: MediaQuery.textScalerOf(context).scale(14) > 18.2
              ? Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kind == StatusKind.error
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      switch (kind) {
                        StatusKind.success => Icons.check_circle_outline,
                        StatusKind.error => Icons.error_outline,
                        StatusKind.pending => Icons.schedule,
                      },
                      size: 20,
                      color: kind == StatusKind.error
                          ? AppColors.error
                          : AppColors.peach,
                    ),
                    const SizedBox(width: AppSpacing.gap),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: kind == StatusKind.error
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
        ),
      );
}

class InfoLabel extends StatelessWidget {
  const InfoLabel({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(child: Text(label)),
        ],
      );
}
