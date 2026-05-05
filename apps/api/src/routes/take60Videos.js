import { Router } from 'express';

import { env } from '../config/env.js';
import { transcodeTake60Video } from '../services/take60Transcoder.js';

const router = Router();

function isAuthorized(req) {
  const expected = env.take60TranscoderToken;
  if (!expected) {
    return true;
  }

  const authorization = req.headers.authorization || '';
  return authorization === `Bearer ${expected}`;
}

router.post('/transcode', async (req, res) => {
  if (!isAuthorized(req)) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const videoId = String(req.body?.videoId || '').trim();
  if (!videoId) {
    res.status(400).json({ error: 'videoId is required' });
    return;
  }

  try {
    const result = await transcodeTake60Video(videoId);
    res.json({ ok: true, ...result });
  } catch (error) {
    console.error('[take60/transcode]', error);
    res.status(500).json({
      ok: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

export default router;