/**
 * An error that maps directly to an HTTP response:
 * `{ "error": { "code": "...", "message": "...", "details": ... } }`.
 * `message` is always safe to show to the end user.
 */
export class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }

  static badRequest(message, code = 'BAD_REQUEST', details) {
    return new ApiError(400, code, message, details);
  }

  static unauthorized(message = 'Please sign in to continue.', code = 'UNAUTHORIZED') {
    return new ApiError(401, code, message);
  }

  static forbidden(message = 'You are not allowed to do that.', code = 'FORBIDDEN') {
    return new ApiError(403, code, message);
  }

  static notFound(message = 'Not found.', code = 'NOT_FOUND') {
    return new ApiError(404, code, message);
  }

  static conflict(message, code = 'CONFLICT', details) {
    return new ApiError(409, code, message, details);
  }

  static unprocessable(message, code = 'UNPROCESSABLE', details) {
    return new ApiError(422, code, message, details);
  }

  static tooMany(message, code = 'TOO_MANY_REQUESTS', details) {
    return new ApiError(429, code, message, details);
  }
}
