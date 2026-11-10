const { before, after, beforeEach, test } = require('node:test');
const { readFileSync, existsSync } = require('node:fs');
const { resolve } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc, writeBatch, getDoc, runTransaction, increment, serverTimestamp, Timestamp } = require('firebase/firestore');
const assert = require('node:assert/strict');
let environment;
const databases = new Set();
function track(db) { databases.add(db); return db; }
function dbFor(uid) { return track(environment.authenticatedContext(uid).firestore()); }

function publication(db, version = 1, baseCalendarId = 'unconfigured') {
  const id = `revision-${String(version).padStart(10, '0')}`;
  const batch = writeBatch(db);
  batch.set(doc(db, `organizations/org/calendarRevisions/${id}`), { version, author: 'creator', baseCalendarId,
    calendar: {}, changes: { '2026-12-25': { name: 'Holiday' } }, publishedAt: serverTimestamp() });
  batch.set(doc(db, `organizations/org/calendars/${id}`), { version, scopeId: 'global', immutableRevision: true });
  batch.update(doc(db, 'organizations/org'), { activeCalendarId: id, latestCalendarRevision: version });
  return batch;
}

function protectedEntry(revisionId = 'first', baseRevision = null, actualUnits = 1, history = []) {
  return { organizationId: 'org', scopeId: 'global', date: '2026-05-29', status: actualUnits === 1 ? 'full' : 'half',
    actualUnits, expectedUnits: 1, leaveUnits: 0, policyVersionId: 'p', calendarVersionId: 'c',
    revisionId, baseRevision, history,
    snapshot: { schema: 1, policy: { basis: 'days', fullUnit: 1 }, dayType: 'working',
      physical: actualUnits, leaveCredit: 0, extraCredit: 0, requiredUnits: 1, legacy: false,
      periodStart: '2026-05-01', periodEnd: '2026-05-31' } };
}

test('protected attendance requires a revision and audit and cannot be downgraded by an old client', async () => {
  const db = dbFor('user'), ref = doc(db, 'users/user/attendance/protected');
  const first = protectedEntry();
  await assertSucceeds(setDoc(ref, first));
  await assertFails(updateDoc(ref, { actualUnits: .5 }));
  await assertFails(setDoc(ref, { organizationId: 'org', scopeId: 'global', date: '2026-05-29',
    status: 'absent', actualUnits: 0, expectedUnits: 1, policyVersionId: 'p', calendarVersionId: 'c' }));
  await assertFails(setDoc(ref, protectedEntry('second', 'stale', .5, [first])));
  await assertFails(setDoc(ref, protectedEntry('second', 'first', .5)));
  await assertSucceeds(setDoc(ref, protectedEntry('second', 'first', .5, [first])));
  const second = protectedEntry('second', 'first', .5, [first]);
  const tampered = protectedEntry('third', 'second', .5, [first, { ...second, actualUnits: 0 }]);
  await assertFails(setDoc(ref, tampered));
  await assertFails(setDoc(ref, protectedEntry('third', 'first', .5, [first, first])));
  const changedBasis = protectedEntry('third', 'second', .5, [first, first]);
  changedBasis.snapshot.policy.basis = 'hours';
  await assertFails(setDoc(ref, changedBasis));
  await assertFails(getDoc(doc(dbFor('other'), 'users/user/attendance/protected')));
});

test('legacy attendance can gain protection without changing the saved raw values', async () => {
  const db = dbFor('user'), ref = doc(db, 'users/user/attendance/legacy');
  const legacy = { organizationId: 'org', scopeId: 'global', date: '2026-05-29', status: 'full',
    actualUnits: 1, expectedUnits: 1, policyVersionId: 'p', calendarVersionId: 'c' };
  await assertSucceeds(setDoc(ref, legacy));
  const migrated = protectedEntry();
  migrated.snapshot.legacy = true;
  migrated.snapshot.physical = 0; migrated.snapshot.requiredUnits = 0;
  await assertSucceeds(setDoc(ref, migrated));
  await assertFails(updateDoc(ref, { status: 'absent' }));
});

test('one-visit attendance is protected from older client downgrades', async () => {
  const db = dbFor('user'), ref = doc(db, 'users/user/attendance/once');
  const first = protectedEntry(); first.snapshot.schema = 2;
  first.snapshot.policy.oneVisitFullDay = true;
  await assertSucceeds(setDoc(ref, first));
  const correction = protectedEntry('second', 'first', 0, [first]);
  correction.snapshot.schema = 2; correction.snapshot.policy.oneVisitFullDay = true;
  await assertSucceeds(setDoc(ref, correction));
  const downgrade = protectedEntry('third', 'second', 1, [first, correction]);
  await assertFails(setDoc(ref, downgrade));
  const invalid = protectedEntry(); invalid.snapshot.schema = 2;
  invalid.snapshot.policy.oneVisitFullDay = true; invalid.snapshot.policy.basis = 'hours';
  await assertFails(setDoc(doc(db, 'users/user/attendance/invalid-once'), invalid));
});

test('accepted once-per-day rules can upgrade the schema and cannot be downgraded', async () => {
  const db = dbFor('user');
  await setDoc(doc(db,'users/user/follows/f'),{organizationId:'org',scopeId:'global',status:'active'});
  const ref=doc(db,'users/user/calendarStates/f');
  await assertSucceeds(setDoc(ref,{organizationId:'org',scopeId:'global',state:'{}',ruleSchema:1}));
  await assertSucceeds(updateDoc(ref,{state:'{"ruleSchema":2}',ruleSchema:2}));
  await assertFails(updateDoc(ref,{state:'{}',ruleSchema:1}));
  await assertFails(updateDoc(ref,{ruleSchema:3}));
});

test('client-generated offline revision sequence satisfies the protected history rules', async () => {
  const path = resolve(__dirname,'../../build/fixes-upload-sequence.json');
  const db = dbFor('user'), ref=doc(db,'users/user/attendance/offline-sequence');
  const fixture = existsSync(path) ? JSON.parse(readFileSync(path,'utf8')) : null;
  const first = fixture?.first ?? protectedEntry('first');
  const second = fixture?.sequence[0] ?? protectedEntry('second','first',.5,[first]);
  const third = fixture?.sequence[1] ?? protectedEntry('third','second',0,[first,second]);
  await assertSucceeds(setDoc(ref,first));
  await assertSucceeds(setDoc(ref,second));
  await assertSucceeds(setDoc(ref,third));
  assert.equal((await getDoc(ref)).data().revisionId,third.revisionId);
});

test('client-generated legacy protection and offline correction both synchronize', async () => {
  const path = resolve(__dirname,'../../build/fixes-legacy-upload-sequence.json');
  if (!existsSync(path)) return;
  const fixture = JSON.parse(readFileSync(path,'utf8'));
  const db = dbFor('user'), ref = doc(db,'users/user/attendance/offline-legacy');
  await assertSucceeds(setDoc(ref,fixture.first));
  for (const step of fixture.sequence) await assertSucceeds(setDoc(ref,step));
  assert.equal((await getDoc(ref)).data().status,'half');
});

function sharedRulePayload() {
  return { policy: { organizationId: 'org', scopeId: 'global', basis: 'days', evaluationPeriod: 'monthly',
      minimumPercent: 85, fullUnit: 1, halfUnit: .5, leaveTreatment: 'noCredit', weekOffCredit: true, holidayCredit: false,
      startDate: null, endDate: null },
    calendar: { organizationId: 'org', scopeId: 'global', weeklyOffs: [6, 7], offSaturdays: [], holidays: [], isConfigured: true } };
}
function rulePublication(db, version = 1, author = 'creator', rules = sharedRulePayload()) {
  const id = `rules-${String(version).padStart(10, '0')}`;
  const schema = rules.policy.oneVisitFullDay ? 2 : 1;
  const batch = writeBatch(db);
  batch.set(doc(db, `organizations/org/ruleRevisions/${id}`), { schema, version, baseVersion: version - 1,
    author, rules, before: {}, changes: { weekOffCredit: true },
    effectiveAt: Timestamp.fromDate(new Date(Date.now() + 86400000)), publishedAt: serverTimestamp() });
  batch.update(doc(db, 'organizations/org'), { latestRuleRevision: version, latestRuleId: id, sharedRulesSchema: schema });
  return batch;
}
test('full rules are creator-only, immutable and atomically published without changing legacy pointers', async () => {
  await assertFails(rulePublication(dbFor('user'), 1, 'user').commit());
  const db = dbFor('creator');
  await assertFails(updateDoc(doc(db, 'organizations/org'), { latestRuleRevision: 1, latestRuleId: 'missing', sharedRulesSchema: 1 }));
  await assertSucceeds(rulePublication(db).commit());
  const ref = doc(db, 'organizations/org/ruleRevisions/rules-0000000001');
  await assertSucceeds(getDoc(doc(dbFor('user'), 'organizations/org/ruleRevisions/rules-0000000001')));
  await assertFails(updateDoc(ref, { changes: {} })); await assertFails(deleteDoc(ref));
  await assertFails(rulePublication(db, 1).commit());
  await assertFails(rulePublication(db, 3).commit());
  assert.equal((await getDoc(doc(db, 'organizations/org'))).data().activePolicyId, undefined);
});

test('one-visit shared rules require a day basis and publish with the compatible schema', async () => {
  const rules=sharedRulePayload(); rules.policy.oneVisitFullDay=true;
  await assertSucceeds(rulePublication(dbFor('creator'),1,'creator',rules).commit());
  const docSnapshot=await getDoc(doc(dbFor('user'),'organizations/org/ruleRevisions/rules-0000000001'));
  assert.equal(docSnapshot.data().schema,2);
  const invalid=sharedRulePayload(); invalid.policy.oneVisitFullDay=true; invalid.policy.basis='hours';
  await assertFails(rulePublication(dbFor('creator'),2,'creator',invalid).commit());
});
test('full rules cannot publish with a missing or disabled rollout gate', async () => {
  await environment.withSecurityRulesDisabled(async context => {
    await deleteDoc(doc(track(context.firestore()), 'configuration/sharedRules'));
  });
  await assertFails(rulePublication(dbFor('creator')).commit());
  await environment.withSecurityRulesDisabled(async context => {
    await setDoc(doc(track(context.firestore()), 'configuration/sharedRules'), { enabled: false });
  });
  await assertFails(rulePublication(dbFor('creator')).commit());
  await assertFails(setDoc(doc(dbFor('creator'), 'configuration/sharedRules'), { enabled: true }));
});
test('shared rules reject invalid units, target, schedules and foreign contexts', async () => {
  for (const change of [{ fullUnit: 0 }, { halfUnit: 2 }, { minimumPercent: 101 },
      { basis: 'invalid' }, { organizationId: 'other' }, { leaveTreatment: 'invalid' }]) {
    const rules = sharedRulePayload(); Object.assign(rules.policy, change);
    await assertFails(rulePublication(dbFor('creator'), 1, 'creator', rules).commit());
  }
  const rules = sharedRulePayload(); rules.calendar.weeklyOffs = [8];
  await assertFails(rulePublication(dbFor('creator'), 1, 'creator', rules).commit());
});
test('an older app cannot strip the schema from an accepted full-rule state', async () => {
  const db = dbFor('user');
  await assertSucceeds(setDoc(doc(db, 'users/user/follows/f'), { organizationId: 'org', scopeId: 'global', status: 'active' }));
  const ref = doc(db, 'users/user/calendarStates/f');
  await assertSucceeds(setDoc(ref, { organizationId: 'org', scopeId: 'global', state: '{}', ruleSchema: 1 }));
  await assertFails(setDoc(ref, { organizationId: 'org', scopeId: 'global', state: '{}' }));
  await assertSucceeds(updateDoc(ref, { state: '{"new":"settings"}', ruleSchema: 1 }));
});

test('private accepted calendars are owner-only and preserve their follow context', async () => {
  const db = dbFor('user');
  await assertSucceeds(setDoc(doc(db, 'users/user/follows/f'), { organizationId: 'org', scopeId: 'global', status: 'active' }));
  const ref = doc(db, 'users/user/calendarStates/f');
  await assertSucceeds(setDoc(ref, { organizationId: 'org', scopeId: 'global', state: '{}' }));
  await assertFails(getDoc(doc(dbFor('other'), 'users/user/calendarStates/f')));
  await assertFails(updateDoc(doc(dbFor('other'), 'users/user/calendarStates/f'), { state: 'changed' }));
  await assertFails(updateDoc(ref, { organizationId: 'other' }));
  await assertFails(setDoc(doc(db, 'users/user/calendarStates/missing-follow'), { organizationId: 'org', scopeId: 'global', state: '{}' }));
  await assertSucceeds(deleteDoc(ref));
});

test('only the creator can atomically publish an immutable calendar revision', async () => {
  await assertFails(publication(dbFor('user')).commit());
  const db = dbFor('creator');
  await assertSucceeds(publication(db).commit());
  const ref = doc(db, 'organizations/org/calendarRevisions/revision-0000000001');
  await assertFails(updateDoc(ref, { changes: {} }));
  await assertFails(deleteDoc(ref));
  await assertFails(updateDoc(doc(db, 'organizations/org/calendars/revision-0000000001'), { holidays: [] }));
  await assertFails(updateDoc(doc(db, 'organizations/org'), { activeCalendarId: 'legacy' }));
  await assertFails(publication(db, 3, 'revision-0000000001').commit());
  await assertSucceeds(publication(db, 2, 'revision-0000000001').commit());
  await assertSucceeds(getDoc(doc(dbFor('user'), 'organizations/org/calendarRevisions/revision-0000000002')));
});

test('publication supports an organization with a null legacy calendar pointer', async () => {
  await environment.withSecurityRulesDisabled(async context => {
    await updateDoc(doc(track(context.firestore()), 'organizations/org'), { activeCalendarId: null });
  });
  await assertSucceeds(publication(dbFor('creator')).commit());
});

test('optional registration and mobile fields stay private', async () => {
  const db = dbFor('user');
  await assertSucceeds(updateDoc(doc(db, 'users/user'), { registrationNumber: '0012-CSC', mobile: null }));
  await assertFails(getDoc(doc(dbFor('other'), 'users/user')));
  await assertSucceeds(updateDoc(doc(db, 'users/user'), { registrationNumber: null }));
});

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
    await setDoc(doc(db, 'configuration/sharedRules'), { enabled: true });
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
  await assertSucceeds(setDoc(doc(db, 'users/user/follows/follow'), { organizationId: 'org', scopeId: 'global', status: 'active' }));
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

test('following legacy organizations and branches works without ownership or existing counters', async () => {
  const db = dbFor('user');
  for (const [orgId, ownership] of [['legacy-missing-owner', {}], ['legacy-null-owner', { createdBy: null }]]) {
    await environment.withSecurityRulesDisabled(async context => {
      const seed = track(context.firestore());
      await setDoc(doc(seed, `organizations/${orgId}`), { name: 'Legacy College', ...ownership });
      await setDoc(doc(seed, `organizations/${orgId}/scopes/csc`), {
        organizationId: orgId, parentId: null, name: 'CSC', type: 'branch',
      });
    });
    const org = doc(db, `organizations/${orgId}`);
    const member = doc(db, `organizations/${orgId}/members/user`);
    const scope = doc(db, `organizations/${orgId}/scopes/csc`);
    const follower = doc(db, `organizations/${orgId}/scopes/csc/followers/user`);
    const followId = `${orgId}-csc-follow`;
    const follow = doc(db, `users/user/follows/${followId}`);
    const join = () => runTransaction(db, async transaction => {
      const previous = await transaction.get(member);
      if (!previous.exists()) {
        transaction.set(member, { status: 'follower' });
        transaction.update(org, { followerCount: increment(1), updatedAt: serverTimestamp() });
      }
    });
    const followBranch = () => runTransaction(db, async transaction => {
      await transaction.get(follow);
      const group = await transaction.get(scope);
      const previous = await transaction.get(follower);
      transaction.set(follow, { organizationId: orgId, scopeId: 'csc', status: 'active' });
      if (!previous.exists()) {
        transaction.set(follower, { followId });
        transaction.update(scope, { followerCount: (group.data().followerCount ?? 0) + 1, updatedAt: serverTimestamp() });
      }
    });
    await assertSucceeds(join());
    await assertSucceeds(followBranch());
    await assertSucceeds(join());
    await assertSucceeds(followBranch());
    await assertSucceeds(updateDoc(follow, { personalTargetPercent: 80 }));
    assert.equal((await getDoc(org)).data().followerCount, 1);
    assert.equal((await getDoc(scope)).data().followerCount, 1);
    await assertFails(updateDoc(org, { name: 'Unapproved edit' }));
    await assertFails(updateDoc(scope, { name: 'Unapproved edit' }));
  }
});

test('any signed-in creator can publish only their own group and scoped rules atomically', async () => {
  const db = dbFor('user');
  const batch = writeBatch(db);
  batch.set(doc(db, 'organizations/org/scopes/csc'), {
    organizationId: 'org', parentId: null, type: 'branch', name: 'CSC', createdBy: 'user',
    followerCount: 0, activePolicyId: 'p-csc', activeCalendarId: 'c-csc', isArchived: false,
  });
  batch.set(doc(db, 'organizations/org/policies/p-csc'), { scopeId: 'csc', minimumPercent: 75 });
  batch.set(doc(db, 'organizations/org/calendars/c-csc'), { scopeId: 'csc', weeklyOffs: [7] });
  await assertSucceeds(batch.commit());
  await assertFails(setDoc(doc(db, 'organizations/org/policies/p-global'), { scopeId: 'global', minimumPercent: 0 }));
  await assertFails(setDoc(doc(dbFor('other'), 'organizations/org/policies/p-csc'), { scopeId: 'csc', minimumPercent: 0 }));
  await assertFails(updateDoc(doc(db, 'organizations/org/policies/p-csc'), { scopeId: 'global' }));
  await assertFails(updateDoc(doc(db, 'organizations/org/scopes/csc'), { followerCount: 100 }));
  await assertFails(updateDoc(doc(db, 'organizations/org/scopes/csc'), { createdBy: 'other' }));
});

async function seedGroup() {
  await environment.withSecurityRulesDisabled(async context => {
    await setDoc(doc(track(context.firestore()), 'organizations/org/scopes/csc'), {
      organizationId: 'org', parentId: null, type: 'branch', name: 'CSC', createdBy: 'creator', followerCount: 0, isArchived: false,
    });
  });
}

async function followGroup(db, count = 1) {
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/user/follows/csc-follow'), { organizationId: 'org', scopeId: 'csc', status: 'active' });
  batch.set(doc(db, 'organizations/org/scopes/csc/followers/user'), { followId: 'csc-follow' });
  batch.update(doc(db, 'organizations/org/scopes/csc'), { followerCount: count, updatedAt: serverTimestamp() });
  return batch.commit();
}

test('group follow and unfollow require exact atomic count changes and private ledgers', async () => {
  await seedGroup();
  const db = dbFor('user');
  await assertSucceeds(followGroup(db));
  const scope = doc(db, 'organizations/org/scopes/csc');
  assert.equal((await getDoc(scope)).data().followerCount, 1);
  await assertFails(followGroup(db, 2));
  await assertFails(getDoc(doc(dbFor('other'), 'organizations/org/scopes/csc/followers/user')));
  await assertFails(deleteDoc(doc(db, 'organizations/org/scopes/csc/followers/user')));
  let batch = writeBatch(db);
  batch.update(doc(db, 'users/user/follows/csc-follow'), { status: 'archived' });
  batch.delete(doc(db, 'organizations/org/scopes/csc/followers/user'));
  batch.update(scope, { followerCount: 0, updatedAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
});

test('group count inflation, identity swaps and archived group follows are denied', async () => {
  await seedGroup();
  const db = dbFor('user');
  await assertFails(followGroup(db, 10));
  await assertSucceeds(followGroup(db));
  await assertFails(updateDoc(doc(db, 'users/user/follows/csc-follow'), { scopeId: 'another' }));
  await environment.withSecurityRulesDisabled(async context => {
    const seed = track(context.firestore());
    await deleteDoc(doc(seed, 'organizations/org/scopes/csc/followers/user'));
    await updateDoc(doc(seed, 'organizations/org/scopes/csc'), { followerCount: 0, isArchived: true });
  });
  await assertFails(followGroup(db));
});

test('organization creators cannot inflate counts, transfer ownership or verify themselves', async () => {
  const db = dbFor('creator');
  await assertFails(updateDoc(doc(db, 'organizations/org'), { followerCount: 100 }));
  await assertFails(updateDoc(doc(db, 'organizations/org'), { createdBy: 'user' }));
  await assertFails(updateDoc(doc(db, 'organizations/org'), { isVerified: true }));
  await assertFails(setDoc(doc(db, 'organizations/new'), { createdBy: 'creator', followerCount: 1 }));
  await assertSucceeds(setDoc(doc(db, 'organizations/new'), { createdBy: 'creator', followerCount: 0 }));
});

test('members cannot join or leave without the matching organization count change', async () => {
  const db = dbFor('user');
  const member = doc(db, 'organizations/org/members/user');
  await assertFails(setDoc(member, { status: 'follower' }));
  const batch = writeBatch(db);
  batch.set(member, { status: 'follower' });
  batch.update(doc(db, 'organizations/org'), { followerCount: 1 });
  await assertSucceeds(batch.commit());
  await assertFails(deleteDoc(member));
});

test('plans are private, editable, removable, and cannot move to a different context', async () => {
  const db = dbFor('user');
  const reference = doc(db, 'users/user/plans/plan');
  await assertSucceeds(setDoc(reference, { organizationId: 'org', scopeId: 'csc', date: '2026-12-01',
    status: 'full', units: 1, isDeleted: false, policyVersionId: 'p', calendarVersionId: 'c' }));
  await assertSucceeds(updateDoc(reference, { status: 'half', units: 0.5, policyVersionId: 'new-p' }));
  await assertFails(updateDoc(reference, { units: -1 }));
  await assertFails(updateDoc(reference, { scopeId: 'other' }));
  await assertFails(getDoc(doc(dbFor('other'), 'users/user/plans/plan')));
  await assertFails(deleteDoc(doc(dbFor('other'), 'users/user/plans/plan')));
  await assertSucceeds(updateDoc(reference, { isDeleted: true }));
  await assertSucceeds(deleteDoc(reference));
});

test('an organization and branch follow is accepted together, or neither counter changes', async () => {
  await seedGroup();
  const db = dbFor('user');
  const follow = (scopeId) => {
    const batch = writeBatch(db);
    batch.set(doc(db, 'organizations/org/members/user'), { status: 'follower' });
    batch.update(doc(db, 'organizations/org'), { followerCount: 1 });
    batch.set(doc(db, 'users/user/follows/combined'), { organizationId: 'org', scopeId, status: 'active' });
    batch.set(doc(db, `organizations/org/scopes/${scopeId}/followers/user`), { followId: 'combined' });
    batch.update(doc(db, `organizations/org/scopes/${scopeId}`), { followerCount: 1 });
    return batch.commit();
  };
  await environment.withSecurityRulesDisabled(async context => {
    await updateDoc(doc(track(context.firestore()), 'organizations/org/scopes/csc'), { isArchived: true });
  });
  await assertFails(follow('csc'));
  assert.equal((await getDoc(doc(db, 'organizations/org'))).data().followerCount, 0);
  assert.equal((await getDoc(doc(db, 'organizations/org/scopes/csc'))).data().followerCount, 0);
  assert.equal((await getDoc(doc(db, 'organizations/org/members/user'))).exists(), false);
  await environment.withSecurityRulesDisabled(async context => {
    await updateDoc(doc(track(context.firestore()), 'organizations/org/scopes/csc'), { isArchived: false });
  });
  await assertSucceeds(follow('csc'));
  assert.equal((await getDoc(doc(db, 'organizations/org'))).data().followerCount, 1);
  assert.equal((await getDoc(doc(db, 'organizations/org/scopes/csc'))).data().followerCount, 1);
});

test('standalone calculations stay private and cannot use another account namespace', async () => {
  const db = dbFor('user');
  const reference = doc(db, 'users/user/follows/personal-calculation');
  await assertSucceeds(setDoc(reference, { organizationId: 'personal:user', scopeId: 'global', status: 'active', personalTargetPercent: 80 }));
  await assertSucceeds(updateDoc(reference, { personalTargetPercent: 90 }));
  await assertFails(getDoc(doc(dbFor('other'), 'users/user/follows/personal-calculation')));
  await assertFails(setDoc(doc(db, 'users/user/follows/spoof'), { organizationId: 'personal:other', scopeId: 'global', status: 'active' }));
  await assertFails(setDoc(doc(db, 'organizations/personal:user'), { createdBy: 'user', followerCount: 0 }));
  assert.equal((await getDoc(doc(db, 'organizations/org'))).data().followerCount, 0);
});
