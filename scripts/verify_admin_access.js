#!/usr/bin/env node
/* eslint-disable no-console */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT || "take30";
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || "localhost:9099";
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || "localhost:8080";

const ADMIN_UID = "admin_take60";
const ADMIN_EMAIL = "admin@take60.local";
const ADMIN_PASSWORD = "Take60Admin2026!";

async function signInWithPassword(email, password) {
  const url = `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    const message = payload?.error?.message || JSON.stringify(payload);
    throw new Error(`Auth signIn failed: ${message}`);
  }

  return payload;
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function verifyCodeAccessGuards() {
  const routerPath = path.join(__dirname, "..", "take30", "lib", "router", "router.dart");
  const adminPath = path.join(
    __dirname,
    "..",
    "take30",
    "lib",
    "admin",
    "take30_admin_scene_flow.dart"
  );

  const routerCode = fs.readFileSync(routerPath, "utf8");
  const adminCode = fs.readFileSync(adminPath, "utf8");

  assert(
    routerCode.includes("if (!isAdmin)") && routerCode.includes("return AppRouter.home;"),
    "Admin route guard missing in router"
  );
  assert(
    adminCode.includes("title: 'Ajout scène'"),
    "Admin add-scene entry not found in admin dashboard"
  );
}

async function main() {
  process.env.FIREBASE_AUTH_EMULATOR_HOST = authHost;
  process.env.FIRESTORE_EMULATOR_HOST = firestoreHost;

  admin.initializeApp({ projectId });

  console.log(`Using emulators auth=${authHost} firestore=${firestoreHost}`);

  const signIn = await signInWithPassword(ADMIN_EMAIL, ADMIN_PASSWORD);
  assert(signIn.localId === ADMIN_UID, `Unexpected uid after login: ${signIn.localId}`);
  console.log("OK auth login with admin credentials");

  const userRecord = await admin.auth().getUser(ADMIN_UID);
  assert(userRecord.email === ADMIN_EMAIL, "Admin auth user email mismatch");
  assert(userRecord.customClaims?.admin === true, "Admin custom claim is missing");
  console.log("OK auth user and custom claims");

  const userDoc = await admin.firestore().doc(`users/${ADMIN_UID}`).get();
  assert(userDoc.exists, "Admin profile missing in Firestore");
  const userData = userDoc.data() || {};
  assert(userData.isAdmin === true, "Admin profile isAdmin is not true");
  console.log("OK firestore admin profile and isAdmin flag");

  await verifyCodeAccessGuards();
  console.log("OK admin route guard + add-scene dashboard entry");

  console.log("SUCCESS admin login/profile/access verification passed");
}

main().catch((error) => {
  console.error(`FAILED ${error.message}`);
  process.exit(1);
});
