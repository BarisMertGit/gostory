import 'dart:async';

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
  bool failNextSave = false;
  Future<void>? pendingSave;
  @override
  Future<LocalUser> signIn() async => user;
  @override
  Future<LocalUser> updateProfile({
    required String username,
    String? newPhotoPath,
    String? bio,
    bool removePhoto = false,
  }) async {
    updates++;
    await pendingSave;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Simulated save failure');
    }
    return user = LocalUser(
      uid: user.uid,
      username: username,
      bio: bio ?? user.bio,
      photoPath: removePhoto ? null : newPhotoPath ?? user.photoPath,
    );
  }
}

void main() {
  Future<void> openEditor(
    WidgetTester tester,
    _EditableProfile auth, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          memoryStoreProvider.overrideWithValue(EmptyMemoryStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Profili düzenle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profili düzenle'));
    await tester.pumpAndSettle();
  }

  testWidgets('editor contains only username and bio and saves both',
      (tester) async {
    final auth = _EditableProfile();
    auth.user = const LocalUser(
      uid: 'author',
      username: 'deniz',
      bio: 'Eski biyografi',
    );
    await openEditor(tester, auth);
    expect(find.byType(TextFormField), findsNWidgets(2));
    final fields =
        tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields[0].controller!.text, 'deniz');
    expect(fields[1].controller!.text, 'Eski biyografi');
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .any((field) => field.keyboardType == TextInputType.url),
      isFalse,
    );
    await tester.enterText(find.byType(TextFormField).first, 'deniz_yolda');
    await tester.enterText(find.byType(TextFormField).last, 'Yeni biyografi');
    await tester.ensureVisible(find.text('Değişiklikleri kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Değişiklikleri kaydet'));
    await tester.pumpAndSettle();
    expect(auth.user.uid, 'author');
    expect(auth.user.bio, 'Yeni biyografi');
    expect(find.text('@deniz_yolda'), findsOneWidget);
    expect(find.text('Yeni biyografi'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel discards changes and reopening restores saved values',
      (tester) async {
    final auth = _EditableProfile();
    await openEditor(tester, auth);
    await tester.enterText(find.byType(TextFormField).first, 'degismemeli');
    await tester.enterText(find.byType(TextFormField).last, 'Kaydedilmedi');
    await tester.ensureVisible(find.byTooltip('Kapat'));
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    expect(auth.updates, 0);
    expect(find.text('@deniz'), findsOneWidget);
    await tester.tap(find.text('Profili düzenle'));
    await tester.pumpAndSettle();
    final fields =
        tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields.first.controller!.text, 'deniz');
    expect(fields.last.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps edits available and retry succeeds',
      (tester) async {
    final auth = _EditableProfile()..failNextSave = true;
    await openEditor(tester, auth);
    await tester.enterText(find.byType(TextFormField).last, 'Tekrar denenecek');
    await tester.ensureVisible(find.text('Değişiklikleri kaydet'));
    await tester.tap(find.text('Değişiklikleri kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Profil kaydedilemedi. Tekrar dene.'), findsOneWidget);
    expect(auth.user.bio, isEmpty);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'Tekrar denenecek',
    );
    await tester.ensureVisible(find.text('Değişiklikleri kaydet'));
    await tester.tap(find.text('Değişiklikleri kaydet'));
    await tester.pumpAndSettle();
    expect(auth.updates, 2);
    expect(find.text('Tekrar denenecek'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending save disables edits, close and duplicate submission',
      (tester) async {
    final completion = Completer<void>();
    final auth = _EditableProfile()..pendingSave = completion.future;
    await openEditor(tester, auth);
    await tester.ensureVisible(find.text('Değişiklikleri kaydet'));
    await tester.tap(find.text('Değişiklikleri kaydet'));
    await tester.pump();
    expect(find.text('Lütfen bekle…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Lütfen bekle…'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Kapat',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .every((field) => field.enabled == false),
      isTrue,
    );
    await tester.tap(find.text('Lütfen bekle…'));
    await tester.pump();
    expect(auth.updates, 1);
    completion.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor saves on a short screen with large text and keyboard',
      (tester) async {
    final auth = _EditableProfile();
    await openEditor(tester, auth, size: const Size(320, 568), scale: 2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.enterText(
      find.byType(TextFormField).last,
      'Küçük ekranda biyografi',
    );
    await tester.ensureVisible(find.text('Değişiklikleri kaydet'));
    await tester.tap(find.text('Değişiklikleri kaydet'));
    await tester.pumpAndSettle();
    expect(auth.updates, 1);
    expect(auth.user.bio, 'Küçük ekranda biyografi');
    expect(tester.takeException(), isNull);
  });

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
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Anı seçenekleri'));
    await tester.pumpAndSettle();
    expect(find.text('Anıyı sil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
