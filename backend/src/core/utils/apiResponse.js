"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.responseEnhancer = responseEnhancer;
exports.paginate = paginate;
exports.readPagination = readPagination;
/**
 * Attaches `res.success` / `res.error` so every module emits the same envelope:
 *   { success, message, data }        on 2xx
 *   { success, message, code, errors} on 4xx/5xx
 */
function responseEnhancer(_req, res, next) {
    res.success = (data = null, message = 'OK', statusCode = 200) => res.status(statusCode).json({ success: true, message, data });
    res.error = (message, statusCode = 400, code = 'BAD_REQUEST', errors = null) => res.status(statusCode).json({ success: false, message, code, errors });
    next();
}
function paginate(items, total, page, limit) {
    return {
        items,
        page,
        limit,
        total,
        total_pages: limit > 0 ? Math.ceil(total / limit) : 0,
    };
}
/** Normalises `?page=` / `?limit=` into safe bounds. */
function readPagination(req, defaultLimit = 20, maxLimit = 100) {
    const page = Math.max(1, Number.parseInt(String(req.query.page ?? '1'), 10) || 1);
    const rawLimit = Number.parseInt(String(req.query.limit ?? defaultLimit), 10) || defaultLimit;
    const limit = Math.min(maxLimit, Math.max(1, rawLimit));
    return { page, limit, offset: (page - 1) * limit };
}
