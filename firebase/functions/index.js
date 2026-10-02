const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {getStorage} = require('firebase-admin/storage');
const {onDocumentWritten, onDocumentCreated, onDocumentDeleted} = require('firebase-functions/v2/firestore');
const {distanceKm} = require('./distance');
initializeApp();
const db = getFirestore();
const region = 'europe-west1';

// Firestore delivers events at least once. Apply each counter delta once.
async function count(event, field, delta) {
  if (!delta) return;
  const receipt = db.collection('_events').doc(encodeURIComponent(event.id));
  const memory = db.collection('memories').doc(event.params.memoryId);
  await db.runTransaction(async t => {
    const [seen, parent] = await Promise.all([t.get(receipt), t.get(memory)]);
    if (seen.exists || !parent.exists) return;
    t.update(memory, {[field]: FieldValue.increment(delta)});
    t.create(receipt, {at: FieldValue.serverTimestamp()});
  });
}
exports.views = onDocumentCreated({document:'memories/{memoryId}/views/{uid}', region}, event => count(event, 'viewCount', 1));
exports.likes = onDocumentWritten({document:'memories/{memoryId}/likes/{uid}', region}, event =>
  count(event, 'likeCount', Number(event.data.after.exists) - Number(event.data.before.exists)));
exports.comments = onDocumentWritten({document:'memories/{memoryId}/comments/{commentId}', region}, event =>
  count(event, 'commentCount', Number(event.data.after.exists) - Number(event.data.before.exists)));

async function send(devices, notification, data) {
  // Respect opt-in, discard stale locations, and batch under FCM's 500-token limit.
  for (let i = 0; i < devices.length; i += 500) {
    const batch = devices.slice(i, i + 500);
    const result = await getMessaging().sendEachForMulticast({tokens:batch.map(d => d.data().token), notification, data});
    await Promise.all(result.responses.map((r, n) =>
      ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(r.error?.code)
        ? batch[n].ref.delete() : Promise.resolve()));
  }
}
exports.replyNotification = onDocumentCreated({document:'memories/{memoryId}/comments/{commentId}', region}, async event => {
  const memory = (await db.collection('memories').doc(event.params.memoryId).get()).data();
  if (!memory || memory.ownerId === event.data.data().authorId) return;
  const devices = await db.collection('notificationDevices').where('profileId', '==', memory.creatorId).where('replies', '==', true).get();
  await send(devices.docs, {title:'Anına bir yanıt geldi', body:'Yeni yorumu GoStory’de gör.'}, {type:'reply', memoryId:event.params.memoryId});
});
exports.nearbyNotification = onDocumentWritten({document:'memories/{memoryId}', region}, async event => {
  const memory = event.data.after.data();
  if (!memory?.public || event.data.before.data()?.public) return;
  const range = 0.011; // Candidate latitude range for a 1 km radius.
  const devices = await db.collection('notificationDevices').where('nearby', '==', true)
    .where('latitude', '>=', memory.latitude - range).where('latitude', '<=', memory.latitude + range).get();
  const recent = Date.now() - 24 * 60 * 60 * 1000;
  const nearby = devices.docs.filter(d => {
    const device = d.data();
    return device.ownerId !== memory.ownerId && device.locationUpdatedAt?.toMillis() >= recent && distanceKm(device, memory) <= 1;
  });
  await send(nearby, {title:'Yakınında yeni bir anı var', body:'Haritada keşfet.'}, {type:'nearby', memoryId:event.params.memoryId});
});
exports.cleanupMemory = onDocumentDeleted({document:'memories/{memoryId}', region}, async event => {
  const memory = event.data.data();
  // Delete child data and original photo after owner deletion.
  await Promise.all(['views', 'likes', 'comments'].map(name => db.recursiveDelete(event.data.ref.collection(name))));
  await getStorage().bucket().file(`photos/${memory.ownerId}/${event.params.memoryId}`).delete({ignoreNotFound:true});
});
