"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InternalServerError = exports.PayloadTooLargeError = exports.ConflictError = exports.NotFoundError = exports.ForbiddenError = exports.UnauthorizedError = exports.ValidationError = exports.BadRequestError = exports.ApiError = void 0;
class ApiError extends Error {
    constructor(statusCode, message, code, details) {
        super(message);
        this.name = new.target.name;
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
        Error.captureStackTrace(this, new.target);
    }
}
exports.ApiError = ApiError;
class BadRequestError extends ApiError {
    constructor(message = 'Invalid request', details) {
        super(400, message, 'BAD_REQUEST', details);
    }
}
exports.BadRequestError = BadRequestError;
class ValidationError extends ApiError {
    constructor(details, message = 'Validation failed') {
        super(422, message, 'VALIDATION_ERROR', details);
    }
}
exports.ValidationError = ValidationError;
class UnauthorizedError extends ApiError {
    constructor(message = 'Authentication required') {
        super(401, message, 'UNAUTHORIZED');
    }
}
exports.UnauthorizedError = UnauthorizedError;
class ForbiddenError extends ApiError {
    constructor(message = 'You do not have permission to perform this action') {
        super(403, message, 'FORBIDDEN');
    }
}
exports.ForbiddenError = ForbiddenError;
class NotFoundError extends ApiError {
    constructor(message = 'Resource not found') {
        super(404, message, 'NOT_FOUND');
    }
}
exports.NotFoundError = NotFoundError;
class ConflictError extends ApiError {
    constructor(message = 'Resource already exists') {
        super(409, message, 'CONFLICT');
    }
}
exports.ConflictError = ConflictError;
class PayloadTooLargeError extends ApiError {
    constructor(message = 'Uploaded file is too large') {
        super(413, message, 'PAYLOAD_TOO_LARGE');
    }
}
exports.PayloadTooLargeError = PayloadTooLargeError;
class InternalServerError extends ApiError {
    constructor(message = 'Something went wrong') {
        super(500, message, 'INTERNAL_ERROR');
    }
}
exports.InternalServerError = InternalServerError;
