import { ApiError } from '../utils/ApiError.js';
import { logger } from '../utils/logger.js';

const send = (res, status, code, message, details) =>
  res.status(status).json({ error: { code, message, ...(details ? { details } : {}) } });

export function notFoundHandler(req, _res, next) {
  next(ApiError.notFound(`Route ${req.method} ${req.originalUrl} does not exist.`, 'ROUTE_NOT_FOUND'));
}

/** Turns every error into the standard `{ error: { code, message } }` JSON shape. */
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, _next) {
  if (err instanceof ApiError) return send(res, err.status, err.code, err.message, err.details);
  if (err?.type === 'entity.parse.failed') return send(res, 400, 'INVALID_JSON', 'Request body must be valid JSON.');
  if (err?.type === 'entity.too.large') return send(res, 413, 'PAYLOAD_TOO_LARGE', 'Request body is too large.');
  if (err?.code === 11000) {
    const field = Object.keys(err.keyPattern ?? {})[0] ?? 'value';
    return send(res, 409, 'DUPLICATE', `This ${field} is already registered with another account.`);
  }
  if (err?.name === 'CastError') return send(res, 400, 'INVALID_ID', 'Invalid id.');
  if (err?.name === 'ValidationError') return send(res, 400, 'VALIDATION_ERROR', err.message);
  if (err?.name === 'VersionError') return send(res, 409, 'CONCURRENT_UPDATE', 'Please retry, the record just changed.');

  logger.error(`Unhandled error on ${req.method} ${req.originalUrl}:`, err);
  return send(res, 500, 'INTERNAL_ERROR', 'Something went wrong on our side. Please try again.');
}
