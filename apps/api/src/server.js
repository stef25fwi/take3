import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { env } from './config/env.js';
import healthRouter from './routes/health.js';
import featuresRouter from './routes/features.js';
import take60VideosRouter from './routes/take60Videos.js';

const app = express();
const { port, clientUrl } = env;

app.use(cors({ origin: clientUrl }));
app.use(express.json());

app.use('/health', healthRouter);
app.use('/api/features', featuresRouter);
app.use('/api/take60/videos', take60VideosRouter);

app.listen(port, () => {
  console.log(`Take30 API running on http://localhost:${port}`);
});
