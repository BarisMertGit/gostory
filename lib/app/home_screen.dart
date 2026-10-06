import 'dart:ui';

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox.square(
        dimension: 48,
        child: FloatingActionButton(
          heroTag: 'share-camera',
          tooltip: 'Bir anı paylaş',
          onPressed: () => ref.read(selectedTabProvider.notifier).state = 1,
          backgroundColor: AppColors.peach,
          foregroundColor: AppColors.onPeach,
          shape: const CircleBorder(),
          elevation: 3,
          child: _CameraNavigationIcon(selected: index == 1),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              border: const Border(
                top: BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.transparent,
              animationDuration: AppMotion.duration(context),
              selectedIndex: index,
              onDestinationSelected: (value) =>
                  ref.read(selectedTabProvider.notifier).state = value,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: _SelectedNavigationIcon(icon: Icons.map),
                  label: 'Harita',
                ),
                NavigationDestination(
                  icon: SizedBox.square(dimension: 32),
                  selectedIcon: SizedBox.square(dimension: 32),
                  label: 'Paylaş',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: _SelectedNavigationIcon(icon: Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedNavigationIcon extends StatelessWidget {
  const _SelectedNavigationIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: .86, end: 1),
        duration: AppMotion.duration(context, AppMotion.emphasized),
        curve: AppMotion.emphasizedCurve,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            gradient:
                LinearGradient(colors: [AppColors.peachLight, AppColors.peach]),
          ),
          child: Icon(icon, color: AppColors.onPeach),
        ),
      );
}

class _CameraNavigationIcon extends StatelessWidget {
  const _CameraNavigationIcon({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: selected ? 1.06 : 1,
        duration: AppMotion.duration(context, AppMotion.emphasized),
        curve: AppMotion.emphasizedCurve,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.peachLight, AppColors.peach],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.peachGlow,
                blurRadius: selected ? 16 : 8,
              ),
            ],
          ),
          child: Icon(
            selected ? Icons.camera_alt : Icons.camera_alt_outlined,
            color: AppColors.onPeach,
          ),
        ),
      );
}
