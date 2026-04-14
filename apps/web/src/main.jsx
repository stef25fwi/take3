import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { initializeFirebaseAnalytics } from './lib/firebase';
import './take30-theme.css';

void initializeFirebaseAnalytics();

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
