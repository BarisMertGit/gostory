import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/design.dart';
import '../../../core/services/cloud_service.dart';
import '../../../core/services/interactions_service.dart';
import '../../../shared/models/memory.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../../shared/providers/memories_provider.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/memory_photo.dart';
import '../../../shared/widgets/motion_widgets.dart';
import '../../profile/presentation/screens/public_profile_screen.dart';

void openMemoryDetail(BuildContext context, Memory memory, {Object? heroTag}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: AppMotion.duration(context),
      reverseTransitionDuration: AppMotion.duration(context),
      pageBuilder: (_, __, ___) =>
          MemoryDetailScreen(memory: memory, heroTag: heroTag),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}

class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({super.key, required this.memory, this.heroTag});
  final Memory memory;
  final Object? heroTag;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  Memory get memory => widget.memory;
  final _comment = TextEditingController();
  final _scroll = ScrollController();
  bool _revealComments = false;
  bool _busy = false;
  bool _sendingComment = false;
  @override
  void initState() {
    super.initState();
    _comment.addListener(_commentChanged);
    Future.microtask(() async {
      try {
        final user = await ref.read(authServiceProvider).signIn();
        await ref.read(interactionsServiceProvider).view(memory.id, user.uid);
        if (!CloudService.ready && mounted) {
          final stats = await ref
              .read(interactionsServiceProvider)
              .load(memory.id, user.uid);
          await ref
              .read(memoryStoreProvider)
              .updateLocalViews(memory.id, stats.views);
          ref.invalidate(personalMemoriesProvider);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _comment.removeListener(_commentChanged);
    _comment.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlanamadı. Tekrar dene.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ref.invalidate(interactionsProvider(memory.id));
      }
    }
  }

  void _commentChanged() {
    setState(() {});
  }

  Future<void> _submitComment() async {
    final text = _comment.text.trim();
    if (_busy || text.isEmpty) return;
    setState(() => _sendingComment = true);
    await _action(() async {
      final service = ref.read(interactionsServiceProvider);
      final user = await ref.read(authServiceProvider).signIn();
      await service.comment(memory.id, user.uid, user.username, text);
      if (!mounted) return;
      _comment.clear();
      _revealComments = true;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorumun gönderildi')),
      );
    });
    if (mounted) setState(() => _sendingComment = false);
  }

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context)
        .formatFullDate(memory.createdAt.toLocal());
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(memory.createdAt.toLocal()));
    final stats = ref.watch(interactionsProvider(memory.id));
    ref.listen(interactionsProvider(memory.id), (_, next) {
      if (!_revealComments || next.isLoading || !next.hasValue) return;
      _revealComments = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final end = _scroll.position.maxScrollExtent;
        if (MediaQuery.disableAnimationsOf(context)) {
          _scroll.jumpTo(end);
        } else {
          _scroll.animateTo(
            end,
            duration: AppMotion.emphasized,
            curve: AppMotion.standardCurve,
          );
        }
      });
    });
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scroll,
                key: const ValueKey('memory-detail-scroll'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: MediaQuery.sizeOf(context).width * .75,
                    title: const Text('Anı'),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: MediaQuery.disableAnimationsOf(context)
                          ? CollapseMode.none
                          : CollapseMode.parallax,
                      background: MemoryPhotoTransition(
                        tag: widget.heroTag,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  MemoryPhotoViewer(path: memory.photoUrl),
                            ),
                          ),
                          child: Semantics(
                            button: true,
                            label: 'Fotoğrafı tam ekran aç',
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MemoryPhoto(path: memory.photoUrl),
                                const IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.center,
                                        colors: [
                                          AppColors.overlayDarker,
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
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.surfaceVariant,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () => openPublicProfile(context, memory),
                            icon: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.accentMuted,
                              child: Text(
                                memory.creatorUsername.isEmpty
                                    ? '?'
                                    : memory.creatorUsername.characters.first
                                        .toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.peach),
                              ),
                            ),
                            label: Text('@${memory.creatorUsername}'),
                          ),
                          const SizedBox(height: 16),
                          SelectableText(
                            memory.textNote,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _DetailChip(
                                icon: Icons.location_on_outlined,
                                label: memory.locationLabel,
                              ),
                              _DetailChip(
                                icon: Icons.calendar_today_outlined,
                                label: '$date · $time',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            '${memory.latitude.toStringAsFixed(5)}, ${memory.longitude.toStringAsFixed(5)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          stats.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => TextButton(
                              onPressed: () => ref
                                  .invalidate(interactionsProvider(memory.id)),
                              child: const Text('Etkileşimleri yeniden yükle'),
                            ),
                            data: (stats) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    _DetailChip(
                                      icon: Icons.visibility_outlined,
                                      label: '${stats.views} görüntüleme',
                                    ),
                                    _DetailChip(
                                      icon: Icons.favorite_border,
                                      label: '${stats.likes} beğeni',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _action(() async {
                                            final user = await ref
                                                .read(authServiceProvider)
                                                .signIn();
                                            await ref
                                                .read(
                                                  interactionsServiceProvider,
                                                )
                                                .like(
                                                  memory.id,
                                                  user.uid,
                                                  !stats.liked,
                                                );
                                          }),
                                  icon: _AnimatedHeart(
                                    key: ValueKey(stats.liked),
                                    liked: stats.liked,
                                  ),
                                  label: Text(
                                    stats.liked ? 'Beğeniyi kaldır' : 'Beğen',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const SectionHeading(title: 'Yorumlar'),
                                const SizedBox(height: 12),
                                if (stats.comments.isEmpty)
                                  Text(
                                    'Bu anıya ilk yorumu sen yaz.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                for (final comment in stats.comments)
                                  _CommentCard(comment: comment),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GlassSurface(
              radius: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _comment,
                        maxLength: 500,
                        minLines: 1,
                        maxLines: 3,
                        enabled: !_busy,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration:
                            const InputDecoration(labelText: 'Yorum yaz'),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryAction(
                          onPressed: _busy || _comment.text.trim().isEmpty
                              ? null
                              : _submitComment,
                          busy: _sendingComment,
                          busyLabel: 'Gönderiliyor…',
                          icon: Icons.send,
                          label: 'Yorumu gönder',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});
  final MemoryComment comment;

  @override
  Widget build(BuildContext context) {
    final createdAt = comment.createdAt?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${comment.username}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${localizations.formatMediumDate(createdAt)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(createdAt))}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Text(comment.text),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoryPhotoViewer extends StatelessWidget {
  const MemoryPhotoViewer({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Fotoğraf')),
        body: SafeArea(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: SizedBox.expand(
              child: MemoryPhoto(path: path, fit: BoxFit.contain),
            ),
          ),
        ),
      );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodySmall!,
          child: InfoLabel(icon: icon, label: label),
        ),
      );
}

class _AnimatedHeart extends StatelessWidget {
  const _AnimatedHeart({super.key, required this.liked});
  final bool liked;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.duration(context, AppMotion.slow),
        builder: (_, value, __) => SizedBox.square(
          dimension: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (liked && !MediaQuery.disableAnimationsOf(context))
                Transform.scale(
                  scale: .6 + value * 1.4,
                  child: Opacity(
                    opacity: 1 - value,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: .8 + Curves.elasticOut.transform(value) * .2,
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? AppColors.error : AppColors.peach,
                ),
              ),
            ],
          ),
        ),
      );
}
