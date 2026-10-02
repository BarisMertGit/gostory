import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';
import '../../app/theme/spacing.dart';

class PageHeading extends StatelessWidget {
  const PageHeading(
      {super.key, required this.title, this.subtitle, this.trailing,});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding, 12, AppSpacing.screenPadding, 16,),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null && MediaQuery.textScalerOf(context).scale(12) <= 18) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),),
                ],
              ],),),
          if (trailing != null) trailing!,
        ],),
      );
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.busy = false,
      this.busyLabel = 'Bekleniyor…',});
  final String label, busyLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: busy,
        child: FilledButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),)
              : icon == null
                  ? const SizedBox.shrink()
                  : Icon(icon, size: 20),
          label: Text(busy ? busyLabel : label, textAlign: TextAlign.center),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.action,});
  final IconData icon;
  final String title, message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),),
            child: Icon(icon, size: 28, color: AppColors.peach),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],),
      );
}

class FilterControl extends StatelessWidget {
  const FilterControl(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onSelected,});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.control),),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(
                  child: Semantics(
                selected: selected == index,
                button: true,
                child: AnimatedContainer(
                  duration: AppMotion.duration(context),
                  decoration: BoxDecoration(
                      color: selected == index
                          ? AppColors.peach
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),),
                  child: TextButton(
                    onPressed: () => onSelected(index),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12,),
                      textStyle: Theme.of(context).textTheme.labelMedium,
                  foregroundColor: selected == index
                          ? AppColors.onPeach
                          : AppColors.textSecondary,
                    ),
                    child: Text(labels[index], textAlign: TextAlign.center),
                  ),
                ),
              ),),
          ],),
        ),
      );
}
