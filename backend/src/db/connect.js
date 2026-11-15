import mongoose from 'mongoose';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';

let memoryServer = null;

/**
 * Connects to MongoDB. Without MONGODB_URI (local development only) it starts a
 * throw-away in-memory MongoDB so the API runs with zero setup.
 */
export async function connectDatabase(uri = env.MONGODB_URI) {
  let mongoUri = uri;
  if (!mongoUri) {
    const { MongoMemoryServer } = await import('mongodb-memory-server');
    memoryServer = await MongoMemoryServer.create();
    mongoUri = memoryServer.getUri('creditsea');
    logger.warn('MONGODB_URI is not set: using a temporary in-memory MongoDB (data is lost on restart).');
  }

  mongoose.set('strictQuery', true);
  await mongoose.connect(mongoUri);
  await mongoose.connection.syncIndexes();
  logger.info(`MongoDB connected (database "${mongoose.connection.name}")`);
}

export async function disconnectDatabase() {
  await mongoose.disconnect();
  if (memoryServer) {
    await memoryServer.stop();
    memoryServer = null;
  }
}
