"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logout = exports.me = exports.sync = void 0;
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const apiError_1 = require("../../core/utils/apiError");
const asyncHandler_1 = require("../../core/utils/asyncHandler");
const auth_service_1 = require("./auth.service");
/**
 * POST /auth/sync
 * Requires a valid Firebase ID token but not an existing MySQL row - this is
 * what bootstraps the row. The uid and email come from the verified token, not
 * from the request body, so a client cannot impersonate someone else.
 */
exports.sync = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid)
        throw new apiError_1.BadRequestError('Firebase identity missing from token');
    const email = (req.user?.email ?? req.body.email ?? '').toString().trim().toLowerCase();
    if (!email)
        throw new apiError_1.BadRequestError('The Firebase account has no email address');
    const { user, created } = await (0, auth_service_1.syncUser)({
        firebaseUid,
        email,
        fullName: String(req.body.full_name).trim(),
    });
    res.success(user, created ? 'Account created' : 'Account already synced', created ? 201 : 200);
});
/** GET /auth/me - used by the splash screen for auto-login. */
exports.me = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { mysqlId } = (0, auth_middleware_1.currentUser)(req);
    const user = await (0, auth_service_1.getCurrentUser)(mysqlId);
    res.success(user, 'Profile loaded');
});
/**
 * POST /auth/logout
 * Firebase tokens are stateless, so the client clears them. This exists for the
 * audit trail and to give the app a single place to hook cleanup.
 */
exports.logout = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { uid, mysqlId } = (0, auth_middleware_1.currentUser)(req);
    console.info(`[auth] logout user_id=${mysqlId} uid=${uid}`);
    res.success(null, 'Logged out');
});
