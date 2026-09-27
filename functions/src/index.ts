import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

/** Deployed next to the eur3 Firestore instance; the client must match. */
const REGION = "europe-west1";

/** The only grants a referral code may hand out. */
const GRANTABLE_TYPES = ["admin", "ugc"];

/**
 * Atomically redeems a referral code. Codes are the document id, uppercased,
 * so they are case-insensitive for the user:
 * 1. Validates the code exists with required fields (type, numUse, maxUse)
 * 2. Checks the type is grantable and the code is not exhausted
 * 3. Checks the caller hasn't already used this code
 * 4. Increments numUse, appends the uid to usedBy
 * 5. Sets userType on the user document — the only writer of that field
 */
export const redeemReferralCode = onCall({region: REGION}, async (request) => {
  // Require authentication — Tably signs in anonymously before any UI renders.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const uid = request.auth.uid;
  const code = request.data?.code;
  if (typeof code !== "string" || code.trim().length === 0) {
    throw new HttpsError("invalid-argument", "A referral code is required.");
  }

  const codeRef = db.collection("referralCodes").doc(code.trim().toUpperCase());
  const userRef = db.collection("users").doc(uid);

  const userType = await db.runTransaction(async (tx) => {
    const codeSnap = await tx.get(codeRef);
    if (!codeSnap.exists) {
      throw new HttpsError("not-found", "Referral code does not exist.");
    }
    const data = codeSnap.data()!;
    const type = data.type as string | undefined;
    const numUse = data.numUse as number | undefined;
    const maxUse = data.maxUse as number | undefined;

    if (type === undefined || numUse === undefined || maxUse === undefined) {
      throw new HttpsError("failed-precondition", "Invalid referral code.");
    }
    // A typo'd type would otherwise burn a use and grant nothing.
    if (!GRANTABLE_TYPES.includes(type)) {
      throw new HttpsError("failed-precondition", "Invalid referral code.");
    }
    if (numUse >= maxUse) {
      throw new HttpsError(
        "resource-exhausted",
        "This code has reached its usage limit."
      );
    }
    const usedBy = (data.usedBy as string[]) || [];
    if (usedBy.includes(uid)) {
      throw new HttpsError(
        "already-exists",
        "You have already used this code."
      );
    }

    // Atomic updates
    tx.update(codeRef, {
      numUse: FieldValue.increment(1),
      usedBy: FieldValue.arrayUnion(uid),
    });
    // merge:true so redeeming before onboarding finishes creates the document
    // without clobbering the profile written later.
    tx.set(userRef, {userType: type}, {merge: true});

    return type;
  });

  return {userType};
});
