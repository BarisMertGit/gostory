import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../shared/providers/profile_photo_provider.dart';
import 'navigation.dart';
import 'theme/colors.dart';
import 'theme/design.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _visited = <int>{0};
  @override
  Widget build(BuildContext context) {
    ref.watch(recoveredProfilePhotoProvider);
    ref.listen(recoveredProfilePhotoProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profil fotoğrafı geri yüklenemedi. Profilinden tekrar seçebilirsin.',
            ),
          ),
        );
      }
    });
    final index = ref.watch(selectedTabProvider);
    _visited.add(index);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          const MapScreen(embedded: true),
          _visited.contains(1)
              ? CameraScreen(embedded: true, active: index == 1)
              : const SizedBox.shrink(),
          _visited.contains(2)
              ? const ProfileScreen()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),),
        child: NavigationBar(
          animationDuration: AppMotion.duration(context),
          selectedIndex: index,
          onDestinationSelected: (value) =>
              ref.read(selectedTabProvider.notifier).state = value,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_outlined),
                label: 'Harita',),
            NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt_outlined),
                label: 'Paylaş',),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_outline),
                label: 'Profil',),
          ],
        ),
      ),
    );
  }
}
