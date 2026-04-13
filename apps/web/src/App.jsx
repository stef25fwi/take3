import { useEffect, useState } from 'react';
import { fetchJson } from './lib/api';

export default function App() {
  const [status, setStatus] = useState('Chargement...');
  const [features, setFeatures] = useState([]);

  useEffect(() => {
    async function loadData() {
      try {
        const [health, featuresData] = await Promise.all([
          fetchJson('/health'),
          fetchJson('/api/features')
        ]);

        setStatus(health.message);
        setFeatures(featuresData.features);
      } catch {
        setStatus('API indisponible pour le moment.');
      }
    }

    loadData();
  }, []);

  return (
    <main className="page">
      <section className="hero">
        <span className="badge">MVP prêt à développer</span>
        <h1>Take30</h1>
        <p>
          Une base complète avec un frontend React et une API Express pour lancer
          rapidement l’application.
        </p>
      </section>

      <section className="grid">
        <article className="card">
          <h2>État du serveur</h2>
          <p>{status}</p>
        </article>

        <article className="card">
          <h2>Fonctionnalités prévues</h2>
          <ul>
            {features.map((feature) => (
              <li key={feature}>{feature}</li>
            ))}
          </ul>
        </article>
      </section>
    </main>
  );
}
