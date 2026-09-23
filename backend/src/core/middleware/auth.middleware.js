"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticate = exports.loadDatabaseUser = exports.verifyFirebaseToken = void 0;
exports.currentUser = currentUser;
exports.currentFarmerProfileId = currentFarmerProfileId;
exports.attachNoop = attachNoop;
const database_1 = require("../../config/database");
const firebase_1 = require("../../config/firebase");
const apiError_1 = require("../utils/apiError");
const asyncHandler_1 = require("../utils/asyncHandler");
function readBearerToken(req) {
    const header = req.headers.authorization ?? '';
    const [scheme, token] = header.split(' ');
    if (!token || scheme.toLowerCase() !== 'bearer') {
        throw new apiError_1.UnauthorizedError('Missing Authorization: Bearer <Firebase_ID_Token> header');
    }
    return token.trim();
}
/**
 * Stage 1 - proves the caller owns a Firebase account. Used on its own by
 * /auth/sync, which runs before the MySQL row exists.
 */
exports.verifyFirebaseToken = (0, asyncHandler_1.asyncHandler)(async (req, _res, next) => {
    const token = readBearerToken(req);
    try {
        const decoded = await (0, firebase_1.firebaseAuth)().verifyIdToken(token, true);
        req.user = { uid: decoded.uid, email: decoded.email ?? null };
    }
    catch (error) {
        const code = error.code ?? '';
        if (code.includes('id-token-expired')) {
            throw new apiError_1.UnauthorizedError('Firebase ID token has expired, please sign in again');
        }
        if (code.includes('id-token-revoked')) {
            throw new apiError_1.UnauthorizedError('Firebase session was revoked, please sign in again');
        }
        throw new apiError_1.UnauthorizedError('Invalid Firebase ID token');
    }
    next();
});
/**
 * Stage 2 - resolves the MySQL identity. The role always comes from MySQL, never
 * from the token or the client.
 */
exports.loadDatabaseUser = (0, asyncHandler_1.asyncHandler)(async (req, _res, next) => {
    if (!req.user?.uid)
        throw new apiError_1.UnauthorizedError();
    const row = await (0, database_1.queryOne)(`SELECT u.id, u.firebase_uid, u.email, u.full_name, u.role, u.is_active, fp.id AS farmer_profile_id
       FROM users u
       LEFT JOIN farmer_profiles fp ON fp.user_id = u.id
      WHERE u.firebase_uid = ?
      LIMIT 1`, [req.user.uid]);
    if (!row) {
        throw new apiError_1.UnauthorizedError('Account is not registered yet. Call POST /auth/sync first.');
    }
    if (!row.is_active) {
        throw new apiError_1.ForbiddenError('Your account has been deactivated. Contact the administrator.');
    }
    req.user = {
        uid: row.firebase_uid,
        email: row.email,
        mysqlId: row.id,
        role: row.role,
        fullName: row.full_name,
        isActive: true,
        farmerProfileId: row.farmer_profile_id ?? undefined,
    };
    next();
});
/** Standard guard for every endpoint except /auth/sync. */
exports.authenticate = [exports.verifyFirebaseToken, exports.loadDatabaseUser];
function currentUser(req) {
    const user = req.user;
    if (!user?.mysqlId || !user.role)
        throw new apiError_1.UnauthorizedError();
    return user;
}
/** Farmer-scoped endpoints need the profile row that owns animals/applications. */
function currentFarmerProfileId(req) {
    const profileId = req.user?.farmerProfileId;
    if (!profileId) {
        throw new apiError_1.ForbiddenError('No farmer profile is linked to this account');
    }
    return profileId;
}
function attachNoop(_req, _res, next) {
    next();
}
