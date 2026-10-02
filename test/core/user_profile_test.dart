import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/features/preview/domain/memory_draft.dart';
import 'package:gostory/shared/models/memory.dart';

void main() {
  test('photo and social links survive reload and username updates', () async {
    final directory = await Directory.systemTemp.createTemp('gostory-avatar-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/profile.json');
    final source = File('${directory.path}/picked.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final service = AuthService(profileFile: () async => file);
    await service.updateProfile(
      username: 'deniz',
      bio: 'Yolda hikâyeler biriktiriyorum.',
      socialLinks: {'Instagram': 'https://instagram.com/deniz'},
      newPhotoPath: source.path,
    );
    await source.delete();
    await service.updateUsername('deniz_yolda');
    final restored = await AuthService(profileFile: () async => file).signIn();
    expect(restored.username, 'deniz_yolda');
    expect(restored.bio, 'Yolda hikâyeler biriktiriyorum.');
    expect(restored.socialLinks['Instagram'], 'https://instagram.com/deniz');
    expect(await File(restored.photoPath!).readAsBytes(), [1, 2, 3]);
    await service.updateProfile(
      username: restored.username,
      socialLinks: {},
      removePhoto: true,
    );
    final cleared = await AuthService(profileFile: () async => file).signIn();
    expect(cleared.photoPath, isNull);
    expect(cleared.socialLinks, isEmpty);
  });

  test('social links reject incorrect platforms and non-https URLs', () {
    expect(
      AuthService.validateSocialLink(
        'Instagram',
        'https://instagram.com/deniz',
      ),
      isNull,
    );
    for (final link in [
      'http://instagram.com/deniz',
      'https://instagram.com.evil.com/deniz',
      'javascript:alert(1)',
      'https://x.com/deniz',
    ]) {
      expect(AuthService.validateSocialLink('Instagram', link), isNotNull);
    }
    expect(AuthService.validateSocialLink('Instagram', ''), isNull);
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
