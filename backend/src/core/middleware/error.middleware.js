"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.globalErrorHandler = exports.notFoundHandler = void 0;
const config_1 = require("../../config");
const apiError_1 = require("../utils/apiError");
const fileHelper_1 = require("../utils/fileHelper");
const notFoundHandler = (req, _res, next) => {
    next(new apiError_1.NotFoundError(`Route ${req.method} ${req.originalUrl} does not exist`));
};
exports.notFoundHandler = notFoundHandler;
function translate(error) {
    if (error instanceof apiError_1.ApiError)
        return error;
    const code = error.code;
    if (code === 'ER_DUP_ENTRY') {
        return new apiError_1.ConflictError('A record with the same unique value already exists');
    }
    if (code === 'ER_NO_REFERENCED_ROW_2' || code === 'ER_ROW_IS_REFERENCED_2') {
        return new apiError_1.ConflictError('Related record is missing or still in use');
    }
    if (code === 'ECONNREFUSED' || code === 'PROTOCOL_CONNECTION_LOST') {
        return new apiError_1.InternalServerError('Database is unavailable, please try again shortly');
    }
    return new apiError_1.InternalServerError(error instanceof Error ? error.message : 'Unexpected error');
}
const globalErrorHandler = (error, req, res, _next) => {
    const apiError = translate(error);
    // A failed request must not leave an orphaned upload on disk.
    void (0, fileHelper_1.deleteUploadedFile)(req.file);
    if (!apiError.statusCode || apiError.statusCode >= 500) {
        console.error(`[error] ${req.method} ${req.originalUrl}`, error);
    }
    res.status(apiError.statusCode).json({
        success: false,
        message: apiError.message,
        code: apiError.code,
        errors: apiError.details ?? null,
        ...(config_1.config.isProduction ? {} : { stack: apiError.stack?.split('\n').slice(0, 5) }),
    });
};
exports.globalErrorHandler = globalErrorHandler;
