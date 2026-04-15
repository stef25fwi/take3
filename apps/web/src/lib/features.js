import { collection, getDocs } from 'firebase/firestore';
import { firestoreDb } from './firebase';
import { fetchJson } from './api';

function normalizeFeature(doc) {
  const data = doc.data();
  const label = data.label ?? data.name ?? data.title ?? doc.id;

  if (typeof label !== 'string' || data.enabled === false) {
    return null;
  }

  return {
    id: doc.id,
    label,
    order: typeof data.order === 'number' ? data.order : Number.MAX_SAFE_INTEGER,
    source: data.source ?? 'firestore'
  };
}

async function fetchFeaturesFromFirestore() {
  const snapshot = await getDocs(collection(firestoreDb, 'features'));

  return snapshot.docs
    .map(normalizeFeature)
    .filter(Boolean)
    .sort((left, right) => left.order - right.order)
    .map((feature) => feature.label);
}

async function fetchFeaturesFromApi() {
  const response = await fetchJson('/api/features');
  return response.features ?? [];
}

export async function loadFeatures() {
  try {
    const firestoreFeatures = await fetchFeaturesFromFirestore();

    if (firestoreFeatures.length > 0) {
      return {
        features: firestoreFeatures,
        source: 'Synchronise depuis Firestore'
      };
    }
  } catch {
  }

  try {
    const apiFeatures = await fetchFeaturesFromApi();

    if (apiFeatures.length > 0) {
      return {
        features: apiFeatures,
        source: 'Repli API locale'
      };
    }
  } catch {
  }

  return {
    features: [],
    source: 'Aucune donnee disponible'
  };
}