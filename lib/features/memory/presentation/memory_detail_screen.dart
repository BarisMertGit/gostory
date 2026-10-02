import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/cloud_service.dart';
import '../../../core/services/interactions_service.dart';
import '../../../shared/models/memory.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../../shared/providers/memories_provider.dart';
import '../../../shared/widgets/memory_photo.dart';
import '../../profile/presentation/screens/public_profile_screen.dart';

void openMemoryDetail(BuildContext context, Memory memory) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MemoryDetailScreen(memory: memory),
    ),
  );
}

class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({super.key, required this.memory});
  final Memory memory;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  Memory get memory => widget.memory;
  final _comment = TextEditingController();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Anı')),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: MemoryPhoto(path: memory.photoUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () => openPublicProfile(context, memory),
                  child: Text('@${memory.creatorUsername}'),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  memory.textNote,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Text(memory.locationLabel),
                const SizedBox(height: 8),
                Text(
                  '${memory.latitude.toStringAsFixed(5)}, ${memory.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 8),
                Text('$date · $time'),
                const SizedBox(height: 16),
                ref.watch(interactionsProvider(memory.id)).when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => TextButton(
                        onPressed: () =>
                            ref.invalidate(interactionsProvider(memory.id)),
                        child: const Text('Etkileşimleri yeniden yükle'),
                      ),
                      data: (stats) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats.views} görüntüleme · ${stats.likes} beğeni',
                          ),
                          TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _action(() async {
                                      final user = await ref
                                          .read(authServiceProvider)
                                          .signIn();
                                      await ref
                                          .read(interactionsServiceProvider)
                                          .like(
                                            memory.id,
                                            user.uid,
                                            !stats.liked,
                                          );
                                    }),
                            icon: Icon(
                              stats.liked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            label:
                                Text(stats.liked ? 'Beğeniyi kaldır' : 'Beğen'),
                          ),
                          for (final comment in stats.comments)
                            _CommentCard(comment: comment),
                        ],
                      ),
                    ),
                TextField(
                  controller: _comment,
                  maxLength: 500,
                  enabled: !_busy,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  decoration: const InputDecoration(labelText: 'Yorum yaz'),
                ),
                FilledButton.icon(
                  onPressed: _busy || _comment.text.trim().isEmpty
                      ? null
                      : _submitComment,
                  icon: _sendingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _sendingComment ? 'Gönderiliyor…' : 'Yorumu gönder',
                  ),
                ),
              ],
            ),
          ),
        ],
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
