import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart' as app_type;
import '../../../../shared/models/memory.dart';
import '../../../../shared/widgets/memory_photo.dart';
import '../../../memory/presentation/memory_detail_screen.dart';

/// Bottom sheet shown when the user taps a memory pin on the map.
///
/// Slides up from the bottom with a spring animation.
///
/// Displays:
/// - Short note excerpt
/// - City + relative time
/// - View count
/// - Photo thumbnail and full detail link
class MemoryBottomSheet extends StatefulWidget {
  const MemoryBottomSheet({
    required this.memory,
    required this.onDismiss,
    super.key,
  });

  final Memory memory;
  final VoidCallback onDismiss;

  @override
  State<MemoryBottomSheet> createState() => _MemoryBottomSheetState();
}

class _MemoryBottomSheetState extends State<MemoryBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Animate in on first build.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          // Swipe down to dismiss.
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 200) {
              _dismiss();
            }
          },
          child: Container(
            margin: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.divider,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${widget.memory.creatorUsername}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (widget.memory.photoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MemoryPhoto(
                            path: widget.memory.photoUrl,
                            height: 120,
                            width: double.infinity,
                          ),
                        ),
                      TextButton(
                        onPressed: () =>
                            openMemoryDetail(context, widget.memory),
                        child: const Text('Anıyı aç'),
                      ),
                      // ── Note text ──
                      Text(
                        widget.memory.textNote,
                        style: app_type.AppTypography.noteInput.copyWith(
                          fontSize: 16,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Divider ──
                      const Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 1,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Meta row ──
                      Row(
                        children: [
                          // City badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.divider,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              widget.memory.locationLabel,
                              style: app_type.AppTypography.tiny,
                            ),
                          ),

                          const SizedBox(width: AppSpacing.sm),

                          Text(
                            _relativeTime(widget.memory.createdAt),
                            style: app_type.AppTypography.tiny,
                          ),

                          const Spacer(),

                          // View count.
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.memory.viewCount}',
                            style: app_type.AppTypography.tiny,
                          ),

                          const SizedBox(width: AppSpacing.md),

                          // Close button.
                          Semantics(
                            label: 'Anı panelini kapat',
                            button: true,
                            child: GestureDetector(
                              onTap: _dismiss,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.divider,
                                    width: 0.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${(diff.inDays / 7).floor()}h önce';
  }
}
