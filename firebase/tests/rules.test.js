import {after, before, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, setDoc, getDoc, updateDoc, deleteDoc, collection, query, where, orderBy, limit, getDocs, serverTimestamp} from 'firebase/firestore';
import {ref, uploadBytes, getBytes} from 'firebase/storage';
let env;
const memory = (id, publicValue, ownerId = 'alice') => ({
  id, ownerId, creatorId:'profile-alice', creatorUsername:'alice', photoUrl:`storage://photos/${ownerId}/${id}`,
  textNote:'Bir anı', latitude:41, longitude:29, city:'İstanbul', createdAt:'2026-09-30T00:00:00.000Z',
  public:publicValue, revision:0, viewCount:0, likeCount:0, commentCount:0,
});
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-gostory',
    firestore:{rules:await readFile(new URL('../firestore.rules',import.meta.url),'utf8')},
    storage:{rules:await readFile(new URL('../storage.rules',import.meta.url),'utf8')},
  });
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(),'profiles/profile-alice'),{ownerId:'alice',username:'alice',bio:'',socialLinks:{}});
  });
});
after(async () => env?.cleanup());
test('owner-only writes, public query, private access and protected counters', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  await assertSucceeds(getDoc(doc(alice,'memories/new-upload')));
  await assertSucceeds(setDoc(doc(alice,'memories/private'),memory('private',false)));
  await assertSucceeds(setDoc(doc(alice,'memories/public'),memory('public',true)));
  await assertSucceeds(getDoc(doc(alice,'memories/private')));
  await assertFails(getDoc(doc(bob,'memories/private')));
  await assertSucceeds(getDoc(doc(bob,'memories/public')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'memories/public')));
  await assertFails(getDocs(collection(bob,'memories')));
  await assertSucceeds(getDocs(query(collection(bob,'memories'),where('public','==',true),orderBy('createdAt','desc'),limit(40))));
  await assertFails(updateDoc(doc(bob,'memories/public'),{public:false}));
  await assertFails(updateDoc(doc(alice,'memories/public'),{viewCount:999}));
  await assertFails(updateDoc(doc(alice,'memories/public'),{ownerId:'bob'}));
  await assertFails(setDoc(doc(bob,'memories/spoof-profile'),memory('spoof-profile',true,'bob')));
  await assertSucceeds(updateDoc(doc(alice,'memories/public'),{public:false, revision:1}));
  await assertFails(getDoc(doc(bob,'memories/public')));
  await assertSucceeds(deleteDoc(doc(alice,'memories/public')));
});
test('visitors cannot spoof visit, like or comment authors', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  await setDoc(doc(alice,'memories/social'),memory('social',true));
  await setDoc(doc(bob,'profiles/profile-bob'),{ownerId:'bob',username:'bob',bio:'',socialLinks:{}});
  await assertSucceeds(setDoc(doc(bob,'memories/social/views/bob'),{createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(bob,'memories/social/views/alice'),{createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(bob,'memories/social/views/bob'),{createdAt:serverTimestamp()}));
  await assertSucceeds(setDoc(doc(bob,'memories/social/likes/bob'),{createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(bob,'memories/social/likes/alice'),{createdAt:serverTimestamp()}));
  await assertSucceeds(setDoc(doc(bob,'memories/social/comments/good'),{authorId:'bob',profileId:'profile-bob',username:'bob',text:'Güzel',createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(bob,'memories/social/comments/spoof'),{authorId:'alice',profileId:'profile-alice',username:'alice',text:'Güzel',createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(bob,'memories/social/comments/long'),{authorId:'bob',profileId:'profile-bob',username:'bob',text:'a'.repeat(501),createdAt:serverTimestamp()}));
});
test('storage photos follow visibility and owner path', async () => {
  const alice = env.authenticatedContext('alice');
  const bob = env.authenticatedContext('bob');
  await setDoc(doc(alice.firestore(),'memories/photo-private'),memory('photo-private',false));
  await setDoc(doc(alice.firestore(),'memories/photo-public'),memory('photo-public',true));
  for (const id of ['photo-private','photo-public']) {
    await assertSucceeds(uploadBytes(ref(alice.storage(),`photos/alice/${id}`),new Uint8Array([1,2,3]),{contentType:'image/jpeg'}));
  }
  await assertFails(getBytes(ref(bob.storage(),'photos/alice/photo-private')));
  await assertSucceeds(getBytes(ref(bob.storage(),'photos/alice/photo-public')));
  await assertFails(uploadBytes(ref(bob.storage(),'photos/alice/photo-public'),new Uint8Array([1]),{contentType:'image/jpeg'}));
  await assertFails(uploadBytes(ref(alice.storage(),'photos/alice/bad-type'),new Uint8Array([1]),{contentType:'text/plain'}));
});

test('first device registration can check a missing token and is owner-protected', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  await setDoc(doc(alice,'profiles/profile-alice'),{ownerId:'alice',username:'alice',bio:'',socialLinks:{}});
  await assertSucceeds(getDoc(doc(alice,'notificationDevices/new-token')));
  await assertSucceeds(setDoc(doc(alice,'notificationDevices/new-token'),{
    ownerId:'alice',profileId:'profile-alice',token:'new-token',replies:true,nearby:false,updatedAt:serverTimestamp(),
  }));
  await assertFails(getDoc(doc(bob,'notificationDevices/new-token')));
  await assertFails(setDoc(doc(bob,'notificationDevices/spoof-token'),{
    ownerId:'bob',profileId:'profile-alice',token:'spoof-token',replies:true,nearby:false,updatedAt:serverTimestamp(),
  }));
});
