import { useEffect, useState } from 'react';
import { fetchJson } from './lib/api';
import { loadFeatures } from './lib/features';

export default function App() {
  const [status, setStatus] = useState('Chargement...');
  const [features, setFeatures] = useState([]);
  const [featureSource, setFeatureSource] = useState('Chargement Firestore...');

  useEffect(() => {
    async function loadData() {
      try {
        const [health, featureResult] = await Promise.all([
          fetchJson('/health').catch(() => null),
          loadFeatures()
        ]);

        setStatus(health?.message ?? 'API indisponible pour le moment.');
        setFeatures(featureResult.features);
        setFeatureSource(featureResult.source);
      } catch {
        setStatus('API indisponible pour le moment.');
        setFeatures([]);
        setFeatureSource('Aucune donnee disponible');
      }
    }

    loadData();
  }, []);

  return (
    <div className="take30-theme">
      <div className="take30-app">
        <div className="take30-screen">
          <header className="take30-header">
            <div className="take30-header-title">Take30</div>
            <button className="take30-icon-btn" aria-label="Ouvrir les notifications">
              ⚡
            </button>
          </header>

          <main className="take30-container take30-stack-20">
            <section className="take30-panel take30-stack-12">
              <span className="take30-chip take30-chip-active">Nouveau thème appliqué</span>
              <h1 className="take30-h1">Crée, tourne et publie en 30 minutes.</h1>
              <p className="take30-body">
                La version web utilise maintenant la direction Take30 sombre avec
                Navy, Yellow et Cyan.
              </p>
              <div className="take30-row" style={{ gap: '10px', flexWrap: 'wrap' }}>
                <span className="take30-chip">#081020</span>
                <span className="take30-chip take30-chip-cyan">#00D4FF</span>
                <span className="take30-chip take30-chip-active">#FFB800</span>
              </div>
            </section>

            <section className="take30-grid-2">
              <article className="take30-panel take30-stack-8">
                <div className="take30-caption">État du serveur</div>
                <h2 className="take30-h2">API</h2>
                <p className="take30-body">{status}</p>
              </article>

              <article className="take30-panel take30-stack-8">
                <div className="take30-caption">Navigation</div>
                <h2 className="take30-h2">Pages clés</h2>
                <p className="take30-body">
                  Accueil, Explorer, Battle, Profil et Prévisualisation.
                </p>
              </article>
            </section>

            <section className="take30-stack-12">
              <div className="take30-row-between">
                <h2 className="take30-h2">Fonctionnalités prévues</h2>
                <span className="take30-chip take30-chip-purple">{featureSource}</span>
              </div>
              <div className="take30-stack-12">
                {features.map((feature) => (
                  <div key={feature} className="take30-panel take30-stack-8">
                    <div className="take30-label">{feature}</div>
                    <div className="take30-caption">Module prêt pour l’intégration web</div>
                  </div>
                ))}
                {features.length === 0 ? (
                  <div className="take30-panel take30-stack-8">
                    <div className="take30-label">Aucune fonctionnalité synchronisée</div>
                    <div className="take30-caption">
                      Ajoute des documents dans la collection Firestore features pour alimenter cette zone.
                    </div>
                  </div>
                ) : null}
              </div>
            </section>

            <section className="take30-profile-actions">
              <button className="take30-btn take30-btn-primary">Ouvrir l’aperçu</button>
              <button className="take30-btn take30-btn-secondary">Voir le flow</button>
            </section>
          </main>
        </div>
      </div>
    </div>
  );
}
