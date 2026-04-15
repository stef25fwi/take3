import { initializeApp } from 'firebase/app';
import { getAnalytics, isSupported } from 'firebase/analytics';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyBM6Wr064fmsyElN6cZEF5irLqlctcxHqc',
  authDomain: 'take30.firebaseapp.com',
  projectId: 'take30',
  storageBucket: 'take30.firebasestorage.app',
  messagingSenderId: '803573468710',
  appId: '1:803573468710:web:3aef887be4785feb39a0e7',
  measurementId: 'G-49LBD56KLW'
};

export const firebaseApp = initializeApp(firebaseConfig);
export const firestoreDb = getFirestore(firebaseApp);

let analyticsInstancePromise;

export function initializeFirebaseAnalytics() {
  if (!analyticsInstancePromise) {
    analyticsInstancePromise = isSupported()
      .then((supported) => (supported ? getAnalytics(firebaseApp) : null))
      .catch(() => null);
  }

  return analyticsInstancePromise;
}