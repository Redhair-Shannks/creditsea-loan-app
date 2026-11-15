import { ApiError } from '../utils/ApiError.js';

/**
 * Validates `req[source]` against a zod schema. The parsed (trimmed, coerced) value
 * is stored on `req.valid[source]`; the first problem becomes the user-facing message.
 */
export const validate = (schema, source = 'body') => (req, _res, next) => {
  const result = schema.safeParse(req[source] ?? {});
  if (!result.success) {
    const details = result.error.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message }));
    throw ApiError.badRequest(details[0]?.message ?? 'Invalid request.', 'VALIDATION_ERROR', details);
  }
  req.valid = { ...req.valid, [source]: result.data };
  next();
};
