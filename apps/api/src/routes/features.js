import { Router } from 'express';

const router = Router();

router.get('/', (_req, res) => {
  res.json({
    features: [
      'Authentification',
      'Tableau de bord',
      'API REST',
      'Base pour déploiement'
    ]
  });
});

export default router;
