import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/navigation.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/memory.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/cloud_provider.dart';
import '../../../../shared/providers/memories_provider.dart';
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/memory_tile.dart';
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
      backgroundColor: AppColors.mapSurface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Hesap'),
              subtitle: const Text('Yerel profilini düzenle'),
              onTap: () {
                Navigator.pop(sheetContext);
                _edit(user);
              },
            ),
            ListTile(
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Bildirimler'),
              subtitle: const Text(
                'Anı yanıtları ve yakın anılar',
                style: TextStyle(color: AppColors.mapSecondary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Gizlilik ve izinler'),
              subtitle: const Text(
                'Kamera, fotoğraf ve konum izinlerini cihaz ayarlarında yönet.',
                style: TextStyle(color: AppColors.mapSecondary),
              ),
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
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Hakkında'),
              subtitle: Text(
                'Anıların cihazda saklanır. Bulut bağlantısı etkinse seçtiğin görünürlükle senkronize edilir.',
                style: TextStyle(color: AppColors.mapSecondary),
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => EmptyState(
              icon: Icons.person_outline,
              title: 'Profil yüklenemedi',
              message: 'Bağlantını kontrol edip yeniden deneyebilirsin.',
              action: PrimaryAction(
                  label: 'Profili yeniden yükle',
                  onPressed: () => ref.invalidate(authStateProvider),),
            ),
            data: (user) {
              final memories = archive.valueOrNull
                  ?.where((m) => m.creatorId == user.uid)
                  .toList();
              return CustomScrollView(
                  key: const PageStorageKey('profile-scroll'),
                  slivers: [
                    SliverToBoxAdapter(
                        child: PageHeading(
                            title: 'Profil',
                            trailing: IconButton(
                              tooltip: 'Ayarlar',
                              onPressed: () => _settings(user),
                              icon: const Icon(Icons.settings_outlined),
                            ),),),
                    SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: AppColors.divider),),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Semantics(
                                                button: true,
                                                label:
                                                    'Profil fotoğrafını değiştir',
                                                child: GestureDetector(
                                                  onTap: () => _edit(user),
                                                  child: _Avatar(
                                                      path: user.photoPath,
                                                      username: user.username,
                                                      size: 68,),
                                                ),),
                                            const SizedBox(width: 16),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text('@${user.username}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,),
                                                  if (memories != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(_stats(memories),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                                color: AppColors
                                                                    .textSecondary,),),
                                                  ],
                                                ],),),
                                          ],),
                                      const SizedBox(height: 16),
                                      Text(
                                          user.bio.isEmpty
                                              ? 'Kendinden kısaca bahset'
                                              : user.bio,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,),),
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                          onPressed: () => _edit(user),
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 16,),
                                          label: const Text('Profili düzenle'),),
                                      if (user.socialLinks.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Wrap(spacing: 4, children: [
                                            for (final link
                                                in user.socialLinks.entries)
                                              IconButton(
                                                  tooltip: link.key,
                                                  onPressed: () =>
                                                      _open(link.value),
                                                  icon: SocialIcon(link.key),),
                                          ],),
                                        ),
                                    ],),
                              ),
                              if (sync != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Semantics(
                                        liveRegion: true,
                                        child: Text(sync,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,),),),
                              const SizedBox(height: 32),
                              Row(children: [
                                Expanded(
                                    child: Text('Anılarım',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,),),
                                if (memories != null)
                                  Text('${memories.length} anı',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary,),),
                              ],),
                              const SizedBox(height: 16),
                            ],),),),
                    if (archive.isLoading && memories == null)
                      const SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.all(32),
                              child:
                                  Center(child: CircularProgressIndicator()),),)
                    else if (archive.hasError)
                      SliverToBoxAdapter(
                          child: EmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: 'Anılar yüklenemedi',
                              message: 'Anılarını yeniden yüklemeyi dene.',
                              action: PrimaryAction(
                                  label: 'Tekrar dene',
                                  onPressed: () => ref
                                      .invalidate(personalMemoriesProvider),),),)
                    else if (memories == null || memories.isEmpty)
                      SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                              child: Card(
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
                                    .state = 1,),
                          ),),),)
                    else
                      SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverLayoutBuilder(
                              builder: (context, constraints) {
                            final scale =
                                MediaQuery.textScalerOf(context).scale(14) / 14;
                            final columns = scale > 1.3
                                ? 1
                                : (constraints.crossAxisExtent / 160)
                                    .floor()
                                    .clamp(1, 3);
                            final width = (constraints.crossAxisExtent -
                                    (columns - 1) * 12) /
                                columns;
                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: width * .9 + 148 * scale,),
                              delegate: SliverChildBuilderDelegate(
                                  (context, index) => _ProfileMemoryCard(
                                      memory: memories[index], canDelete: true,),
                                  childCount:
                                      memories.length.clamp(0, _visibleCount),),
                            );
                          },),),
                    if (memories != null && memories.length > _visibleCount)
                      SliverToBoxAdapter(
                          child: TextButton(
                              onPressed: () =>
                                  setState(() => _visibleCount += 20),
                              child: const Text('Daha fazla anı'),),),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],);
            },
          ),),
    );
  }

  String _stats(List<Memory> memories) {
    final cities =
        memories.map((m) => m.city.trim()).where((c) => c.isNotEmpty).toSet();
    return '${memories.length} anı${cities.isEmpty ? '' : ' · ${cities.length} şehir'}';
  }
}

class _ProfileMemoryCard extends ConsumerWidget {
  const _ProfileMemoryCard({
    required this.memory,
    required this.canDelete,
  });
  final Memory memory;
  final bool canDelete;
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
            const SnackBar(content: Text('Görünürlük değiştirilemedi.')),);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => MemoryTile(
        memory: memory,
        onTap: () => openMemoryDetail(context, memory),
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
                  child:
                      Text(memory.isPublic ? 'Özel yap' : 'Herkese açık yap'),),
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
            24,
            24,
            24,
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
                  child: const SizedBox(
                    height: 48,
                    child: Row(
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
                      style: const TextStyle(color: Color(0xFFF3A29A)),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE5B68E),
                      foregroundColor: const Color(0xFF29241F),
                      padding: const EdgeInsets.all(16),
                    ),
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
