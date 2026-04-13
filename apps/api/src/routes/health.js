import { Router } from 'express';

const router = Router();

router.get('/', (_req, res) => {
  res.json({
    ok: true,
    message: 'API Take30 opérationnelle'
  });
});

export default router;
