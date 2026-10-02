import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cloud_service.dart';
import '../../../../shared/models/memory.dart';
import '../../../../shared/providers/cloud_provider.dart';
import '../../../../shared/widgets/social_icon.dart';
import '../../../memory/presentation/memory_detail_screen.dart';

final publicProfileProvider =
    FutureProvider.autoDispose.family<LocalUser?, String>((ref, id) async {
  if (!CloudService.ready) return null;
  final cloud = ref.read(cloudServiceProvider);
  await cloud.authenticate();
  final data = (await cloud.db.collection('profiles').doc(id).get()).data();
  if (data == null) return null;
  return LocalUser(
    uid: id,
    username: data['username'] as String,
    bio: data['bio'] as String? ?? '',
    socialLinks: Map<String, String>.from(data['socialLinks'] as Map? ?? {}),
  );
});

void openPublicProfile(BuildContext context, Memory memory) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PublicProfileScreen(memory: memory),
    ),
  );
}

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.memory});
  final Memory memory;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(memory.creatorId));
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı profili')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () =>
                ref.invalidate(publicProfileProvider(memory.creatorId)),
            child: const Text('Profili yeniden yükle'),
          ),
        ),
        data: (user) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '@${user?.username ?? memory.creatorUsername}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user != null) ...[
              if (user.bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(user.bio),
                ),
              for (final entry in user.socialLinks.entries)
                if (AuthService.validateSocialLink(entry.key, entry.value) ==
                    null)
                  ListTile(
                    leading: SocialIcon(entry.key),
                    title: Text(entry.key),
                    subtitle: Text(entry.value),
                    onTap: () async {
                      var opened = false;
                      try {
                        opened = await launchUrl(
                          Uri.parse(entry.value),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {}
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bağlantı açılamadı.'),
                          ),
                        );
                      }
                    },
                  ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Bu kullanıcı için paylaşılmış profil bilgisi yok.',
                ),
              ),
            ListTile(
              title: Text(memory.textNote),
              subtitle: Text(memory.locationLabel),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => openMemoryDetail(context, memory),
            ),
          ],
        ),
      ),
    );
  }
}
