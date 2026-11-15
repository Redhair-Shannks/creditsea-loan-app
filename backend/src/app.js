import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import apiRoutes from './routes/index.js';

/** Builds the Express app (no network or DB side effects, so tests can use it directly). */
export function createApp() {
  const app = express();

  app.set('trust proxy', 1); // Render/Heroku/Vercel sit behind one proxy
  app.disable('x-powered-by');
  app.set('etag', false); // personal/financial data: never answer from a cache
  app.use(helmet());
  app.use(cors({ origin: env.corsOrigins ?? true }));
  app.use(express.json({ limit: '100kb' }));
  if (!env.isTest) app.use(morgan(env.isProduction ? 'combined' : 'dev'));

  app.get('/', (_req, res) => res.json({ name: 'CreditSea Loan API', version: 'v1', health: '/api/v1/health' }));
  app.use('/api/v1', (_req, res, next) => {
    res.set('Cache-Control', 'no-store');
    next();
  });
  app.use('/api/v1', apiRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
