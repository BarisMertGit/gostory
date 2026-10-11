import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/features/preview/domain/memory_draft.dart';
import 'package:gostory/shared/models/memory.dart';

void main() {
  group('profile persistence regression', () {
    late Directory directory;
    late File file;
    late AuthService service;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('gostory-profile-');
      file = File('${directory.path}/profile.json');
      service = AuthService(profileFile: () async => file);
    });
    tearDown(() => directory.delete(recursive: true));

    test('new and edited profiles persist only supported fields', () async {
      final original = await service.signIn();
      expect(
        (jsonDecode(await file.readAsString()) as Map).keys,
        unorderedEquals(['uid', 'username', 'bio', 'photo']),
      );
      await service.updateProfile(
        username: '  çağrı_34  ',
        bio: '  Yoldayım  ',
      );
      expect(jsonDecode(await file.readAsString()), {
        'uid': original.uid,
        'username': 'çağrı_34',
        'bio': 'Yoldayım',
        'photo': null,
      });
    });

    test('older profiles load and obsolete fields disappear on save', () async {
      await file.writeAsString(
        jsonEncode({
          'uid': 'stable-user',
          'username': 'deniz',
          'photo': 'avatar.jpg',
          'obsoleteMetadata': {'unused': 'value'},
        }),
      );
      final photo =
          await File('${directory.path}/avatar.jpg').writeAsBytes([1, 2, 3]);
      final user = await service.signIn();
      expect(user.uid, 'stable-user');
      expect(user.bio, isEmpty);
      expect(user.photoPath, photo.path);
      await service.updateProfile(username: 'deniz_yolda');
      expect(jsonDecode(await file.readAsString()), {
        'uid': 'stable-user',
        'username': 'deniz_yolda',
        'bio': '',
        'photo': 'avatar.jpg',
      });
      expect(await photo.readAsBytes(), [1, 2, 3]);
    });

    test('omitted bio preserves it and an empty bio clears it', () async {
      await service.updateProfile(username: 'deniz', bio: 'Bir yolculuk');
      await service.updateProfile(username: 'deniz_yolda');
      expect(service.currentUser!.bio, 'Bir yolculuk');
      await service.updateProfile(username: 'deniz_yolda', bio: '  ');
      final restored =
          await AuthService(profileFile: () async => file).signIn();
      expect(restored.bio, isEmpty);
      expect(restored.uid, service.uid);
    });

    test('invalid edits leave the profile and persisted bytes intact',
        () async {
      await service.updateProfile(
        username: 'deniz',
        bio: 'Korunacak biyografi',
      );
      final before = await file.readAsString();
      final uid = service.uid;
      for (final name in ['', 'ab', 'a b', 'a' * 25]) {
        await expectLater(
          service.updateProfile(username: name, bio: 'Değişmemeli'),
          throwsArgumentError,
        );
        expect(await file.readAsString(), before);
        expect(service.currentUser!.bio, 'Korunacak biyografi');
        expect(service.uid, uid);
      }
    });

    test('photo replacement and removal preserve identity and bio', () async {
      final first = await File('${directory.path}/first.jpg').writeAsBytes([1]);
      final second =
          await File('${directory.path}/second.png').writeAsBytes([2]);
      final user = await service.updateProfile(
        username: 'deniz',
        bio: 'Gezgin',
        newPhotoPath: first.path,
      );
      final replaced = await service.updateProfile(
        username: user.username,
        newPhotoPath: second.path,
      );
      expect(replaced.photoPath, isNot(user.photoPath));
      expect(replaced.photoPath, endsWith('.png'));
      await second.delete();
      expect(await File(replaced.photoPath!).readAsBytes(), [2]);
      await service.updateProfile(username: user.username, removePhoto: true);
      final restored =
          await AuthService(profileFile: () async => file).signIn();
      expect(restored.uid, user.uid);
      expect(restored.bio, 'Gezgin');
      expect(restored.photoPath, isNull);
    });

    test('failed photo copy leaves the last saved profile unchanged', () async {
      final user =
          await service.updateProfile(username: 'deniz', bio: 'Gezgin');
      final before = await file.readAsString();
      await expectLater(
        service.updateProfile(
          username: 'yeni_isim',
          bio: 'Değişmemeli',
          newPhotoPath: '${directory.path}/missing.jpg',
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(service.currentUser, same(user));
      expect(await file.readAsString(), before);
      await service.updateProfile(username: 'deniz_yolda');
      expect(service.currentUser!.bio, 'Gezgin');
    });
  });

  test('photo and bio survive reload and username updates', () async {
    final directory = await Directory.systemTemp.createTemp('gostory-avatar-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/profile.json');
    final source = File('${directory.path}/picked.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final service = AuthService(profileFile: () async => file);
    await service.updateProfile(
      username: 'deniz',
      bio: 'Yolda hikâyeler biriktiriyorum.',
      newPhotoPath: source.path,
    );
    await source.delete();
    await service.updateUsername('deniz_yolda');
    final restored = await AuthService(profileFile: () async => file).signIn();
    expect(restored.username, 'deniz_yolda');
    expect(restored.bio, 'Yolda hikâyeler biriktiriyorum.');
    expect(await File(restored.photoPath!).readAsBytes(), [1, 2, 3]);
    await service.updateProfile(
      username: restored.username,
      removePhoto: true,
    );
    final cleared = await AuthService(profileFile: () async => file).signIn();
    expect(cleared.photoPath, isNull);
  });

  test('username persists across service instances and keeps the same user ID',
      () async {
    final directory = await Directory.systemTemp.createTemp('gostory-profile-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/profile.json');
    final service = AuthService(profileFile: () async => file);
    final original = await service.signIn();
    final renamed = await service.updateUsername('  deniz_istanbul  ');
    expect(renamed.uid, original.uid);
    expect(renamed.username, 'deniz_istanbul');
    final restored = await AuthService(profileFile: () async => file).signIn();
    expect(restored.uid, original.uid);
    expect(restored.username, 'deniz_istanbul');
    await expectLater(service.updateUsername('a b'), throwsArgumentError);
    expect(service.currentUser?.username, 'deniz_istanbul');
  });

  test('username validates supported characters and length', () {
    expect(LocalUser.validateUsername('çağrı_34'), isNull);
    for (final name in ['', 'ab', 'a b', '@deniz', 'a' * 25]) {
      expect(LocalUser.validateUsername(name), isNotNull);
    }
  });

  test('memory copies and drafts retain author identity', () {
    final memory = Memory(
      id: '1',
      creatorId: 'user-1',
      creatorUsername: 'deniz',
      photoUrl: '',
      textNote: 'Bir anı',
      latitude: 41,
      longitude: 29,
      city: 'İstanbul',
      createdAt: DateTime(2026),
    );
    expect(memory.copyWith(viewCount: 2).creatorUsername, 'deniz');
    expect(memory.copyWith(viewCount: 2).creatorId, 'user-1');
    final draft = MemoryDraft(
      photoPath: 'demo://istanbul',
      note: 'Bir anı',
      creatorId: memory.creatorId,
      creatorUsername: memory.creatorUsername,
    );
    expect(draft.creatorUsername, 'deniz');
    expect(draft.creatorId, 'user-1');
  });
}
