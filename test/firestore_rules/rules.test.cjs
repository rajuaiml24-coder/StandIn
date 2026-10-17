const { before, after, beforeEach, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc, writeBatch, getDoc, serverTimestamp } = require('firebase/firestore');
const assert = require('node:assert/strict');
let environment;
const databases = new Set();
function track(db) { databases.add(db); return db; }
function dbFor(uid) { return track(environment.authenticatedContext(uid).firestore()); }

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-standin',
    firestore: { host: '127.0.0.1', port: 8088, rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8') },
  });
});
after(async () => {
  await Promise.all([...databases].map(db => db.terminate()));
  if (environment) await environment.cleanup();
});
beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async context => {
    const db = track(context.firestore());
    await setDoc(doc(db, 'users/user'), { displayName: 'User', role: 'student', isAdmin: false, createdAt: 1 });
    await setDoc(doc(db, 'users/other'), { displayName: 'Other', role: 'student', isAdmin: false, createdAt: 1 });
    await setDoc(doc(db, 'organizations/org'), { createdBy: 'creator', followerCount: 0, name: 'College' });
  });
});

test('profile creation and updates preserve protected fields', async () => {
  const db = dbFor('new-user');
  const reference = doc(db, 'users/new-user');
  await assertSucceeds(setDoc(reference, { displayName: 'New', role: 'employee', isAdmin: false, createdAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(reference, { displayName: 'Updated', activeFollowId: 'follow', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(reference, { isAdmin: true }));
  await assertFails(updateDoc(reference, { createdAt: 2 }));
  await assertFails(updateDoc(reference, { role: 'student' }));
});

test('ordinary user can atomically join and leave with the exact count change', async () => {
  const db = dbFor('user');
  const member = doc(db, 'organizations/org/members/user');
  const org = doc(db, 'organizations/org');
  let batch = writeBatch(db);
  batch.set(member, { status: 'follower' });
  batch.update(org, { followerCount: 1, updatedAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(org)).data().followerCount, 1);
  batch = writeBatch(db);
  batch.delete(member);
  batch.update(org, { followerCount: 0, updatedAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
});

test('count changes cannot edit policies, inflate counts, or use somebody else membership', async () => {
  const db = dbFor('user');
  const org = doc(db, 'organizations/org');
  await assertFails(updateDoc(org, { followerCount: 1 }));
  let batch = writeBatch(db);
  batch.set(doc(db, 'organizations/org/members/user'), { status: 'follower' });
  batch.update(org, { followerCount: 10 });
  await assertFails(batch.commit());
  batch = writeBatch(db);
  batch.set(doc(db, 'organizations/org/members/user'), { status: 'follower' });
  batch.update(org, { followerCount: 1, name: 'Changed' });
  await assertFails(batch.commit());
  batch = writeBatch(db);
  batch.set(doc(db, 'organizations/org/members/other'), { status: 'follower' });
  batch.update(org, { followerCount: 1 });
  await assertFails(batch.commit());
  await assertFails(setDoc(doc(db, 'organizations/org/policies/policy-global'), { minimumPercent: 0 }));
});

test('owners can delete their profile, username, follow and attendance', async () => {
  const db = dbFor('user');
  await assertSucceeds(setDoc(doc(db, 'usernames/user-name'), { uid: 'user' }));
  await assertSucceeds(setDoc(doc(db, 'users/user/follows/follow'), { organizationId: 'org' }));
  await assertSucceeds(setDoc(doc(db, 'users/user/attendance/day'), {
    organizationId: 'org', scopeId: 'global', date: '2026-01-01', status: 'full', policyVersionId: null,
  }));
  const batch = writeBatch(db);
  for (const path of ['usernames/user-name', 'users/user/follows/follow', 'users/user/attendance/day', 'users/user']) batch.delete(doc(db, path));
  await assertSucceeds(batch.commit());
});

test('one account cannot delete or read another account data', async () => {
  await environment.withSecurityRulesDisabled(async context => {
    await setDoc(doc(track(context.firestore()), 'usernames/other-name'), { uid: 'other' });
  });
  const db = dbFor('user');
  await assertFails(deleteDoc(doc(db, 'users/other')));
  await assertFails(deleteDoc(doc(db, 'usernames/other-name')));
  await assertFails(getDoc(doc(db, 'users/other')));
  await assertFails(getDoc(doc(db, 'users/other/attendance/day')));
});

test('joining before the queued profile has uploaded is allowed without granting admin rights', async () => {
  const db = dbFor('unprofiled-user');
  const batch = writeBatch(db);
  batch.set(doc(db, 'organizations/org/members/unprofiled-user'), { status: 'follower' });
  batch.update(doc(db, 'organizations/org'), { followerCount: 1, updatedAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
  await assertFails(setDoc(doc(db, 'organizations/org/policies/policy-global'), { minimumPercent: 0 }));
});

test('leaving legacy organizations without createdBy never makes a zero count negative', async () => {
  await environment.withSecurityRulesDisabled(async context => {
    const db = track(context.firestore());
    await setDoc(doc(db, 'organizations/legacy'), { name: 'Legacy', followerCount: 0 });
    await setDoc(doc(db, 'organizations/legacy/members/user'), { status: 'follower' });
  });
  const db = dbFor('user');
  const batch = writeBatch(db);
  batch.delete(doc(db, 'organizations/legacy/members/user'));
  batch.update(doc(db, 'organizations/legacy'), { followerCount: 0, updatedAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(db, 'organizations/legacy'))).data().followerCount, 0);
});
