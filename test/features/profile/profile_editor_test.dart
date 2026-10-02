import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/features/profile/presentation/screens/profile_screen.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import '../../test_helpers/empty_memory_store.dart';

class _EditableProfile extends AuthService {
  LocalUser user = const LocalUser(uid: 'author', username: 'deniz');
  int updates = 0;
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
    updates++;
    return user = LocalUser(
      uid: user.uid,
      username: username,
      bio: bio ?? '',
      socialLinks: socialLinks,
    );
  }
}

void main() {
  testWidgets('profile editor validates before saving and refreshes profile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _EditableProfile();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          memoryStoreProvider.overrideWithValue(EmptyMemoryStore()),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profili düzenle'));
    await tester.pumpAndSettle();
    expect(find.text('Fotoğraf seç'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'a');
    await tester.ensureVisible(find.text('Değişiklikleri kaydet'));
    await tester.tap(find.text('Değişiklikleri kaydet'));
    await tester.pumpAndSettle();
    expect(auth.updates, 0);
    expect(
      find.text('3–24 karakter; harf, rakam ve alt çizgi kullan.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).first, 'deniz_yolda');
    await tester.tap(find.text('Değişiklikleri kaydet'));
    await tester.pumpAndSettle();
    expect(auth.updates, 1);
    expect(find.text('@deniz_yolda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile only lists own memories without bookmark controls',
      (tester) async {
    final mine = Memory(
      id: 'mine',
      creatorId: 'author',
      creatorUsername: 'deniz',
      photoUrl: '',
      textNote: 'Kendi anım',
      latitude: 41,
      longitude: 29,
      city: 'İstanbul',
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_EditableProfile()),
          personalMemoriesProvider.overrideWith(
            (ref) async => [
              mine,
              mine.copyWith(
                id: 'other',
                creatorId: 'other-user',
                textNote: 'Başkasının anısı',
                isPublic: true,
              ),
            ],
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Kendi anım'), 300);
    expect(find.text('Başkasının anısı'), findsNothing);
    expect(find.text('Kaydedilenler'), findsNothing);
    expect(find.byTooltip('Anıyı kaydet'), findsNothing);
    expect(find.byTooltip('Kaydedilenlerden çıkar'), findsNothing);
    await tester.ensureVisible(find.byTooltip('Anı seçenekleri'));
    await tester.tap(find.byTooltip('Anı seçenekleri'));
    await tester.pumpAndSettle();
    expect(find.text('Anıyı sil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
