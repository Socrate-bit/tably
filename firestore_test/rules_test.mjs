// Security-rule tests for firestore.rules. Run with:
//   cd firestore_test && npm install --legacy-peer-deps && npm test
// (needs the Firebase emulator, so Java). These cover the userType entitlement,
// which only the redeemReferralCode function may write — a rule that merely
// checked the key was absent from a write silently locked admins out of saving
// their own profile, because on an update request.resource.data is the document
// *after* the merge.
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, deleteDoc } from 'firebase/firestore';

// emulators:exec exports this; fall back to the emulator's default port.
const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080').split(':');

const UID = 'user-1';
const OTHER = 'user-2';

// Mirrors UserProfile.toMap() — note it never contains userType.
const profile = (extra = {}) => ({
  name: 'Chef',
  household: 2,
  mealsPerDay: 1,
  budget: 60,
  onboardingComplete: true,
  ...extra,
});

let passed = 0;
let failed = 0;
async function check(name, fn) {
  try {
    await fn();
    console.log(`  PASS  ${name}`);
    passed++;
  } catch (e) {
    console.log(`  FAIL  ${name}\n        ${e.message}`);
    failed++;
  }
}

const env = await initializeTestEnvironment({
  projectId: 'tably-rules-test',
  firestore: { rules: readFileSync('firestore.rules', 'utf8'), host, port: Number(port) },
});

const db = env.authenticatedContext(UID).firestore();
const other = env.authenticatedContext(OTHER).firestore();
const anon = env.unauthenticatedContext().firestore();

console.log('\nusers/{uid} — ownership');
await check('owner can create their profile', () =>
  assertSucceeds(setDoc(doc(db, 'users', UID), profile())));
await check('owner can read their profile', () =>
  assertSucceeds(getDoc(doc(db, 'users', UID))));
await check('a different user cannot read it', () =>
  assertFails(getDoc(doc(other, 'users', UID))));
await check('a different user cannot write it', () =>
  assertFails(setDoc(doc(other, 'users', UID), profile())));
await check('an anonymous client cannot read it', () =>
  assertFails(getDoc(doc(anon, 'users', UID))));

console.log('\nusers/{uid}.userType — server-owned');
await check('client cannot create a profile carrying userType', async () => {
  await env.clearFirestore();
  await assertFails(setDoc(doc(db, 'users', UID), profile({ userType: 'admin' })));
});
await check('client cannot add userType to an existing profile', async () => {
  await env.clearFirestore();
  await assertSucceeds(setDoc(doc(db, 'users', UID), profile()));
  await assertFails(setDoc(doc(db, 'users', UID), { userType: 'admin' }, { merge: true }));
});

// THE REGRESSION: an admin must still be able to save preferences. A rule that
// merely checks `!('userType' in request.resource.data)` denies this, because on
// an update request.resource.data is the post-merge document.
await check('an admin can still save their profile (userType untouched)', async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', UID), profile({ userType: 'admin' }));
  });
  await assertSucceeds(setDoc(doc(db, 'users', UID), profile({ name: 'Renamed' }), { merge: true }));
});
await check('...and the grant survives that save', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const snap = await getDoc(doc(ctx.firestore(), 'users', UID));
    if (snap.data().userType !== 'admin') throw new Error('userType was lost');
    if (snap.data().name !== 'Renamed') throw new Error('name was not saved');
  });
});
await check('an admin cannot change their own userType', async () => {
  await assertFails(setDoc(doc(db, 'users', UID), { userType: 'ugc' }, { merge: true }));
});
await check('an admin cannot remove their userType', async () => {
  await assertFails(setDoc(doc(db, 'users', UID), profile()));
});
await check('replayOnboarding (onboardingComplete:false) is allowed', () =>
  assertSucceeds(setDoc(doc(db, 'users', UID), { onboardingComplete: false }, { merge: true })));

console.log('\nsubcollections');
await check('owner can write their shopping list', () =>
  assertSucceeds(setDoc(doc(db, 'users', UID, 'shopping', 'item-1'), { checked: true })));
await check('a different user cannot', () =>
  assertFails(setDoc(doc(other, 'users', UID, 'shopping', 'item-1'), { checked: true })));

console.log('\nreferralCodes');
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'referralCodes', 'TABLY-ADMIN'), {
    type: 'admin', numUse: 0, maxUse: 10, usedBy: [],
  });
});
await check('a signed-in client can read a code (pre-validation)', () =>
  assertSucceeds(getDoc(doc(db, 'referralCodes', 'TABLY-ADMIN'))));
await check('an anonymous client cannot', () =>
  assertFails(getDoc(doc(anon, 'referralCodes', 'TABLY-ADMIN'))));
await check('no client can burn a use', () =>
  assertFails(setDoc(doc(db, 'referralCodes', 'TABLY-ADMIN'), { numUse: 1 }, { merge: true })));
await check('no client can mint a code', () =>
  assertFails(setDoc(doc(db, 'referralCodes', 'FREEBIE'), {
    type: 'admin', numUse: 0, maxUse: 999, usedBy: [],
  })));
await check('no client can delete a code', () =>
  assertFails(deleteDoc(doc(db, 'referralCodes', 'TABLY-ADMIN'))));

console.log('\nsearchQuota/{uid} — server-owned');
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'searchQuota', UID), { day: '2026-10-05', count: 30 });
});
await check('owner can read their search count', () =>
  assertSucceeds(getDoc(doc(db, 'searchQuota', UID))));
await check('a different user cannot read it', () =>
  assertFails(getDoc(doc(other, 'searchQuota', UID))));
await check('owner cannot reset it', () =>
  assertFails(setDoc(doc(db, 'searchQuota', UID), { day: '2026-10-05', count: 0 })));
await check('owner cannot delete it', () =>
  assertFails(deleteDoc(doc(db, 'searchQuota', UID))));

await env.cleanup();
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
