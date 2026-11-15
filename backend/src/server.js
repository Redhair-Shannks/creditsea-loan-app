import { createApp } from './app.js';
import { env } from './config/env.js';
import { connectDatabase, disconnectDatabase } from './db/connect.js';
import { startLifecycleScheduler } from './services/loanLifecycle.service.js';
import { logger } from './utils/logger.js';

async function main() {
  await connectDatabase();

  const server = createApp().listen(env.PORT, () => {
    logger.info(`CreditSea API listening on http://localhost:${env.PORT}/api/v1`);
    if (env.OTP_DEV_MODE) logger.warn('OTP_DEV_MODE is on: OTP codes are returned in API responses (demo only).');
  });
  const stopScheduler = startLifecycleScheduler();

  const shutdown = async (signal) => {
    logger.info(`${signal} received, shutting down...`);
    stopScheduler();
    server.close();
    await disconnectDatabase();
    process.exit(0);
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

main().catch((error) => {
  logger.error('Failed to start the server:', error);
  process.exit(1);
});
