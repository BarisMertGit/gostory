import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';
import '../../app/theme/spacing.dart';

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
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated, outlined;

  @override
  Widget build(BuildContext context) => Material(
        color: elevated ? AppColors.surfaceVariant : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: outlined
              ? const BorderSide(color: AppColors.divider)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      );
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
    return Semantics(
      liveRegion: busy,
      child: busy || icon != null
          ? FilledButton.icon(
              onPressed: action,
              style: FilledButton.styleFrom(
                animationDuration: AppMotion.duration(context),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Icon(icon, size: 20),
              label: text,
            )
          : FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(
                animationDuration: AppMotion.duration(context),
              ),
              child: text,
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
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentGlow,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Icon(icon, size: 28, color: AppColors.peach),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < labels.length; index++)
                  Expanded(
                    child: Semantics(
                      selected: selected == index,
                      inMutuallyExclusiveGroup: true,
                      child: AnimatedContainer(
                        duration: AppMotion.duration(context),
                        decoration: BoxDecoration(
                          color: selected == index
                              ? AppColors.peach
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                        child: TextButton(
                          onPressed: () => onSelected(index),
                          style: TextButton.styleFrom(
                            animationDuration: AppMotion.duration(context),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.sm,
                            ),
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: selected == index
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                            foregroundColor: selected == index
                                ? AppColors.onPeach
                                : AppColors.textSecondary,
                          ),
                          child:
                              Text(labels[index], textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
