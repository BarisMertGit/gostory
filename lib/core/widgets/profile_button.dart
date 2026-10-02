import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../shared/providers/auth_provider.dart';

class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authStateProvider).valueOrNull;
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xDD222B2D),
        foregroundColor: const Color(0xFFE5B68E),
      ),
      onPressed: () => ref.read(selectedTabProvider.notifier).state = 2,
      icon: const Icon(Icons.person_outline, size: 18),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 90),
        child: Text(
          profile == null ? 'Profil' : '@${profile.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
