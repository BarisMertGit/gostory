import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/home_screen.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/constants/preview_config.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/features/camera/presentation/screens/camera_screen.dart';
import 'package:gostory/features/map/presentation/screens/map_screen.dart';
import 'package:gostory/features/profile/presentation/screens/profile_screen.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import '../../test_helpers/empty_memory_store.dart';

class _ProfileService extends AuthService {
  LocalUser user = const LocalUser(uid: 'test-1', username: 'deniz');
  @override
  Future<LocalUser> signIn() async => user;
  @override
  Future<LocalUser> updateProfile({
    required String username,
    required Map<String, String> socialLinks,
    String? newPhotoPath,
    String? bio,
    bool removePhoto = false,
  }) async {
    return user = LocalUser(
      uid: user.uid,
      username: username,
      bio: bio ?? '',
      socialLinks: socialLinks,
    );
  }
}

void main() {
  testWidgets(
    'three tabs navigate and profile edits are shown on return',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _ProfileService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(service),
            memoryStoreProvider.overrideWithValue(EmptyMemoryStore()),
          ],
          child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MapScreen), findsOneWidget);
      Future<void> tab(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      await tab('Harita');
      expect(find.byType(MapScreen), findsOneWidget);
      await tab('Profil');
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('@deniz'), findsOneWidget);
      await tester.tap(find.text('Profili düzenle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'deniz_yolda');
      await tester.tap(find.byTooltip('Sosyal bağlantı ekle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'https://instagram.com/deniz_yolda',
      );
      await tester.ensureVisible(find.text('Değişiklikleri kaydet'));
      await tester.tap(find.text('Değişiklikleri kaydet'));
      await tester.pumpAndSettle();
      expect(find.text('@deniz_yolda'), findsOneWidget);
      expect(
        service.user.socialLinks['Instagram'],
        'https://instagram.com/deniz_yolda',
      );
      await tab('Paylaş');
      expect(find.byType(CameraScreen), findsOneWidget);
      await tab('Profil');
      expect(find.text('@deniz_yolda'), findsOneWidget);
      expect(find.text('Anılarım'), findsOneWidget);
      expect(find.text('GoStory her yerde'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    skip: !PreviewConfig.enabled,
  );
}
