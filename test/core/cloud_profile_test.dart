import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/cloud_service.dart';
import 'package:gostory/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:gostory/shared/providers/cloud_provider.dart';
import 'package:mocktail/mocktail.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

// Only used to intercept SDK calls; production code uses the real SDK types.
// ignore: subtype_of_sealed_class
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Document extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Cloud extends CloudService {
  _Cloud(this.firestore);
  final FirebaseFirestore firestore;
  @override
  FirebaseFirestore get db => firestore;
  @override
  Future<String> authenticate() async => 'cloud-owner';
}

void main() {
  late _Document document;
  late _Cloud cloud;
  setUp(() {
    final firestore = _Firestore();
    final collection = _Collection();
    document = _Document();
    when(() => firestore.collection('profiles')).thenReturn(collection);
    when(() => collection.doc('local-user')).thenReturn(document);
    when(() => document.set(any())).thenAnswer((_) async {});
    cloud = _Cloud(firestore);
  });

  test('profile upload replaces the document with public fields only',
      () async {
    await cloud.saveProfile(
      const LocalUser(
        uid: 'local-user',
        username: 'deniz',
        bio: 'Gezgin',
        photoPath: '/private/device/avatar.jpg',
      ),
    );
    // A replacement write also removes obsolete fields in an older document.
    verify(
      () => document.set({
        'ownerId': 'cloud-owner',
        'username': 'deniz',
        'bio': 'Gezgin',
      }),
    ).called(1);
    verifyNoMoreInteractions(document);
  });

  test('empty bio is uploaded so a previous bio can be cleared', () async {
    await cloud
        .saveProfile(const LocalUser(uid: 'local-user', username: 'deniz'));
    verify(
      () => document.set({
        'ownerId': 'cloud-owner',
        'username': 'deniz',
        'bio': '',
      }),
    ).called(1);
  });

  test('failed cloud write reaches the caller for retry', () async {
    when(() => document.set(any())).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    await expectLater(
      cloud.saveProfile(const LocalUser(uid: 'local-user', username: 'deniz')),
      throwsA(isA<FirebaseException>()),
    );
  });

  group('public profile loading', () {
    late ProviderContainer container;
    late bool wasReady;
    late _Snapshot snapshot;
    setUp(() {
      wasReady = CloudService.ready;
      CloudService.ready = true;
      snapshot = _Snapshot();
      when(() => document.get()).thenAnswer((_) async => snapshot);
      container = ProviderContainer(
        overrides: [
          cloudServiceProvider.overrideWithValue(cloud),
        ],
      );
    });
    tearDown(() {
      container.dispose();
      CloudService.ready = wasReady;
    });

    test('supported fields load despite obsolete remote metadata', () async {
      when(() => snapshot.data()).thenReturn({
        'username': 'deniz',
        'bio': 'Gezgin',
        'ownerId': 'cloud-owner',
        'obsoleteMetadata': {'unused': 'value'},
      });
      final user =
          await container.read(publicProfileProvider('local-user').future);
      expect(user!.uid, 'local-user');
      expect(user.username, 'deniz');
      expect(user.bio, 'Gezgin');
      expect(user.photoPath, isNull);
    });

    test('older document without bio defaults to an empty bio', () async {
      when(() => snapshot.data()).thenReturn({'username': 'deniz'});
      final user =
          await container.read(publicProfileProvider('local-user').future);
      expect(user!.bio, isEmpty);
    });

    test('missing document returns no profile', () async {
      when(() => snapshot.data()).thenReturn(null);
      expect(
        await container.read(publicProfileProvider('local-user').future),
        isNull,
      );
    });

    test('disabled cloud does not access Firestore', () async {
      CloudService.ready = false;
      expect(
        await container.read(publicProfileProvider('local-user').future),
        isNull,
      );
      verifyNever(() => document.get());
    });
  });
}
