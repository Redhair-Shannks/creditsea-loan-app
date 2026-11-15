import { env } from '../config/env.js';

const write = (level, args) => {
  if (env.isTest) return;
  const stamp = new Date().toISOString();
  const out = level === 'error' ? console.error : console.log;
  out(`[${stamp}] ${level.toUpperCase()}`, ...args);
};

/** Minimal logger: timestamps in dev/prod, silent during tests. */
export const logger = {
  info: (...args) => write('info', args),
  warn: (...args) => write('warn', args),
  error: (...args) => write('error', args),
};
