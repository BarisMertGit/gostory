import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/navigation.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/memory.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/cloud_provider.dart';
import '../../../../shared/providers/memories_provider.dart';
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/content_placeholder.dart';
import '../../../../shared/widgets/memory_tile.dart';
import '../../../../shared/widgets/motion_widgets.dart';
import '../../../../shared/widgets/social_icon.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../../memory/presentation/memory_detail_screen.dart';
import 'notification_settings_screen.dart';

const _socialPlatforms = ['Instagram', 'TikTok', 'X', 'YouTube'];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _visibleCount = 20;
  Future<void> _edit(LocalUser user) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.mapSurface,
        builder: (_) => _ProfileEditor(user: user),
      );
  Future<void> _open(String url) async {
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'profile_screen',
        error: error.runtimeType,
        stackTrace: stack,
      ); /* Display recoverable feedback below. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı. Tekrar dene.')),
      );
    }
  }

  void _settings(LocalUser user) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.mapSurface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SettingsRow(
              icon: Icons.person_outline,
              title: 'Hesap',
              description: 'Yerel profilini düzenle',
              onTap: () {
                Navigator.pop(sheetContext);
                _edit(user);
              },
            ),
            SettingsRow(
              icon: Icons.notifications_outlined,
              title: 'Bildirimler',
              description: 'Anı yanıtları ve yakın anılar',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            SettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Gizlilik ve izinler',
              description:
                  'Kamera, fotoğraf ve konum izinlerini cihaz ayarlarında yönet.',
              onTap: () async {
                final opened = await Geolocator.openAppSettings();
                if (!opened && sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cihaz ayarlarından GoStory izinlerini açabilirsin.',
                      ),
                    ),
                  );
                }
              },
            ),
            SettingsRow(
              icon: Icons.info_outline,
              title: 'Hakkında',
              description: 'Anılarının saklanması ve paylaşılması',
              onTap: () => showDialog<void>(
                context: sheetContext,
                builder: (context) => AlertDialog(
                  title: const Text('GoStory'),
                  content: const Text(
                    'Anıların cihazda saklanır. Bulut bağlantısı etkinse seçtiğin görünürlükle senkronize edilir.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tamam'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authStateProvider);
    final archive = ref.watch(personalMemoriesProvider);
    final sync = ref.watch(syncStatusProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profile.when(
          loading: () => const ProfilePlaceholder(),
          error: (_, __) => AdaptiveStateBody(
            child: EmptyState(
              icon: Icons.person_outline,
              title: 'Profil yüklenemedi',
              message: 'Bağlantını kontrol edip yeniden deneyebilirsin.',
              action: PrimaryAction(
                label: 'Profili yeniden yükle',
                onPressed: () => ref.invalidate(authStateProvider),
              ),
            ),
          ),
          data: (user) {
            final memories = archive.valueOrNull
                ?.where((m) => m.creatorId == user.uid)
                .toList();
            return CustomScrollView(
              key: const PageStorageKey('profile-scroll'),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight:
                      MediaQuery.textScalerOf(context).scale(28) * 1.2 + 16,
                  expandedHeight:
                      MediaQuery.textScalerOf(context).scale(28) * 1.2 + 60,
                  actions: [
                    IconButton(
                      tooltip: 'Ayarlar',
                      onPressed: () => _settings(user),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.fromLTRB(20, 0, 64, 12),
                    expandedTitleScale: 1,
                    title: Text(
                      'Profil',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    background: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.gradientEnd, AppColors.background],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileSummary(
                          user: user,
                          memoryCount: memories?.length,
                          cityCount:
                              memories == null ? 0 : _cityCount(memories),
                          onEdit: () => _edit(user),
                          onOpenLink: _open,
                        ),
                        if (sync != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                sync,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        if (archive.hasError && memories != null)
                          const StatusNotice(
                            message:
                                'Arşiv yenilenemedi. Kayıtlı anıların gösteriliyor.',
                            kind: StatusKind.error,
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        SectionHeading(
                          title: 'Anılarım',
                          count: memories?.length,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (archive.isLoading && memories == null)
                  const SliverToBoxAdapter(
                    child: MemoryGridPlaceholder(),
                  )
                else if (archive.hasError && memories == null)
                  SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Anılar yüklenemedi',
                      message: 'Anılarını yeniden yüklemeyi dene.',
                      action: PrimaryAction(
                        label: 'Tekrar dene',
                        onPressed: () =>
                            ref.invalidate(personalMemoriesProvider),
                      ),
                    ),
                  )
                else if (memories == null || memories.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: EmptyState(
                          icon: Icons.add_photo_alternate_outlined,
                          title: 'İlk anın burada başlayacak',
                          message:
                              'Bir fotoğraf çek, kısa bir not ekle ve konumuyla sakla.',
                          action: PrimaryAction(
                            label: 'İlk anını paylaş',
                            icon: Icons.add,
                            onPressed: () => ref
                                .read(selectedTabProvider.notifier)
                                .state = 1,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final scale =
                            MediaQuery.textScalerOf(context).scale(14) / 14;
                        final columns = scale > 1.3
                            ? 1
                            : ((constraints.crossAxisExtent + AppSpacing.gap) /
                                    160)
                                .floor()
                                .clamp(1, 3);
                        return SliverMasonryGrid.count(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childCount: memories.length.clamp(0, _visibleCount),
                          itemBuilder: (context, index) => Entrance(
                            order: index,
                            child: _ProfileMemoryCard(
                              memory: memories[index],
                              canDelete: true,
                              photoAspectRatio: columns == 1
                                  ? 1
                                  : (index % 3 == 0 ? .82 : 1.12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (memories != null && memories.length > _visibleCount)
                  SliverToBoxAdapter(
                    child: TextButton(
                      onPressed: () => setState(() => _visibleCount += 20),
                      child: const Text('Daha fazla anı'),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  int _cityCount(List<Memory> memories) {
    final cities =
        memories.map((m) => m.city.trim()).where((c) => c.isNotEmpty).toSet();
    return cities.length;
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.user,
    required this.memoryCount,
    required this.cityCount,
    required this.onEdit,
    required this.onOpenLink,
  });
  final LocalUser user;
  final int? memoryCount;
  final int cityCount;
  final VoidCallback onEdit;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final avatar = Tooltip(
      message: 'Profil fotoğrafını değiştir',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onEdit,
        child: Semantics(
          button: true,
          label: 'Profil fotoğrafını değiştir',
          child: _Avatar(
            path: user.photoPath,
            username: user.username,
            size: AppSizes.avatar,
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileIdentity(username: user.username, avatar: avatar),
          if (memoryCount != null) ...[
            const SizedBox(height: AppSpacing.gap),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                AnimatedCounter(
                  value: memoryCount!,
                  label: 'anı',
                  icon: Icons.photo_library_outlined,
                ),
                if (cityCount > 0)
                  AnimatedCounter(
                    value: cityCount,
                    label: 'şehir',
                    icon: Icons.location_city_outlined,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            user.bio.isEmpty ? 'Kendinden kısaca bahset' : user.bio,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            label: const Text('Profili düzenle'),
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: onEdit,
          ),
          if (user.socialLinks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final link in user.socialLinks.entries)
                    PressFeedback(
                      child: IconButton(
                        tooltip: link.key,
                        onPressed: () => onOpenLink(link.value),
                        icon: SocialIcon(link.key),
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

class _ProfileMemoryCard extends ConsumerWidget {
  const _ProfileMemoryCard({
    required this.memory,
    required this.canDelete,
    this.photoAspectRatio = 1,
  });
  final Memory memory;
  final bool canDelete;
  final double photoAspectRatio;
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anı silinsin mi?'),
        content: const Text(
          'Fotoğraf ve not cihazdaki arşivden silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final user = await ref.read(authServiceProvider).signIn();
      if (!context.mounted) return;
      await ref
          .read(memoryStoreProvider)
          .delete(memory.id, creatorId: user.uid);
      if (!context.mounted) return;
      ref.invalidate(personalMemoriesProvider);
      ref.invalidate(mapProvider);
    } catch (error, stack) {
      AppLogger.error(
        'Anı silinemedi.',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anı silinemedi. Tekrar dene.')),
        );
      }
    }
  }

  Future<void> _visibility(BuildContext context, WidgetRef ref) async {
    try {
      final user = await ref.read(authServiceProvider).signIn();
      await ref
          .read(memoryStoreProvider)
          .setPublic(memory.id, creatorId: user.uid, value: !memory.isPublic);
      ref.invalidate(personalMemoriesProvider);
      ref.invalidate(mapProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görünürlük değiştirilemedi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => MemoryTile(
        memory: memory,
        photoAspectRatio: photoAspectRatio,
        heroTag: 'profile-memory-${memory.id}',
        onTap: () => openMemoryDetail(
          context,
          memory,
          heroTag: 'profile-memory-${memory.id}',
        ),
        actions: PopupMenuButton<String>(
          tooltip: 'Anı seçenekleri',
          icon: const Icon(Icons.more_horiz, size: 20),
          onSelected: (action) {
            if (action == 'open') openMemoryDetail(context, memory);
            if (action == 'visibility') _visibility(context, ref);
            if (action == 'delete') _delete(context, ref);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'open', child: Text('Anıyı aç')),
            if (canDelete)
              PopupMenuItem(
                value: 'visibility',
                child: Text(memory.isPublic ? 'Özel yap' : 'Herkese açık yap'),
              ),
            if (canDelete)
              const PopupMenuItem(value: 'delete', child: Text('Anıyı sil')),
          ],
        ),
      );
}

class _ProfileEditor extends ConsumerStatefulWidget {
  const _ProfileEditor({required this.user});
  final LocalUser user;
  @override
  ConsumerState<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<_ProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _username = TextEditingController(text: widget.user.username);
  late final _links = {
    for (final name in _socialPlatforms)
      name: TextEditingController(text: widget.user.socialLinks[name] ?? ''),
  };
  late final _bio = TextEditingController(text: widget.user.bio);
  late final Set<String> _visibleLinks = widget.user.socialLinks.keys.toSet();
  String? _newPhoto;
  String? _error;
  bool _removePhoto = false;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    for (final controller in _links.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await markGalleryPurpose('profile');
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (mounted && image != null) {
        setState(() {
          _newPhoto = image.path;
          _removePhoto = false;
        });
      }
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'profile_screen',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (mounted) {
        setState(
          () => _error =
              'Fotoğraf seçilemedi. Fotoğraf erişimini kontrol edip tekrar dene.',
        );
      }
    } finally {
      await clearGalleryPurpose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).updateProfile(
            username: _username.text,
            bio: _bio.text,
            socialLinks: _links
                .map((name, controller) => MapEntry(name, controller.text)),
            newPhotoPath: _newPhoto,
            removePhoto: _removePhoto,
          );
      ref.invalidate(authStateProvider);
      if (mounted) Navigator.pop(context);
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'profile_screen',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Profil kaydedilemedi. Tekrar dene.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom +
                24,
          ),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Profili düzenle',
                        style: TextStyle(fontSize: 23),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Avatar(
                      path: _removePhoto
                          ? null
                          : _newPhoto ?? widget.user.photoPath,
                      username: widget.user.username,
                      size: 64,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        children: [
                          TextButton.icon(
                            onPressed: _busy ? null : _pickPhoto,
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 17,
                            ),
                            label: const Text('Fotoğraf seç'),
                          ),
                          if (!_removePhoto &&
                              (_newPhoto != null ||
                                  widget.user.photoPath != null))
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _newPhoto = null;
                                        _removePhoto = true;
                                      }),
                              child: const Text('Kaldır'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bulut bağlantısı etkin olduğunda kullanıcı adın, biyografin ve sosyal bağlantıların diğer kullanıcılara görünür.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _username,
                  enabled: !_busy,
                  maxLength: 24,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı adı',
                    prefixText: '@',
                  ),
                  validator: (value) => LocalUser.validateUsername(value ?? ''),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bio,
                  enabled: !_busy,
                  maxLength: 160,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Biyografi',
                    hintText: 'Kendinden kısaca bahset',
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Sosyal bağlantı ekle',
                  enabled:
                      !_busy && _visibleLinks.length < _socialPlatforms.length,
                  onSelected: (name) => setState(() => _visibleLinks.add(name)),
                  itemBuilder: (_) => [
                    for (final name in _socialPlatforms)
                      if (!_visibleLinks.contains(name))
                        PopupMenuItem(value: name, child: Text(name)),
                  ],
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: const Row(
                      children: [
                        Icon(Icons.add_link, color: AppColors.peach),
                        SizedBox(width: 8),
                        Text(
                          'Sosyal bağlantı ekle',
                          style: TextStyle(color: AppColors.peach),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final entry in _links.entries
                    .where((e) => _visibleLinks.contains(e.key)))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextFormField(
                      controller: entry.value,
                      enabled: !_busy,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        hintText: 'https://…',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SocialIcon(entry.key),
                        ),
                      ),
                      validator: (value) => AuthService.validateSocialLink(
                        entry.key,
                        value ?? '',
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(
                      _busy ? 'Lütfen bekle…' : 'Değişiklikleri kaydet',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.path,
    required this.username,
    required this.size,
  });
  final String? path;
  final String username;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        username.isEmpty ? '?' : username[0].toUpperCase(),
        style: TextStyle(
          fontSize: size * .38,
          color: AppColors.peach,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.divider),
      ),
      child: path == null
          ? fallback
          : Image.file(
              File(path!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
