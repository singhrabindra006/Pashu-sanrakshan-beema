"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncUser = syncUser;
exports.getCurrentUser = getCurrentUser;
exports.mapUser = mapUser;
exports.findByFirebaseUid = findByFirebaseUid;
exports.findById = findById;
const database_1 = require("../../config/database");
const roles_1 = require("../../core/constants/roles");
const apiError_1 = require("../../core/utils/apiError");
const fileHelper_1 = require("../../core/utils/fileHelper");
const SELECT_USER = `
  SELECT u.id, u.firebase_uid, u.email, u.full_name, u.role, u.is_active, u.created_at,
         fp.id AS profile_id, fp.phone, fp.profile_image_path
    FROM users u
    LEFT JOIN farmer_profiles fp ON fp.user_id = u.id
`;
function mapUser(row) {
    return {
        id: row.id,
        firebase_uid: row.firebase_uid,
        email: row.email,
        full_name: row.full_name,
        role: row.role,
        is_active: Boolean(row.is_active),
        created_at: row.created_at,
        farmer_profile: row.profile_id === null
            ? null
            : {
                id: row.profile_id,
                phone: row.phone,
                profile_image_path: row.profile_image_path,
                image_url: (0, fileHelper_1.toPublicUrl)(row.profile_image_path),
            },
    };
}
async function findByFirebaseUid(uid) {
    const row = await (0, database_1.queryOne)(`${SELECT_USER} WHERE u.firebase_uid = ? LIMIT 1`, [uid]);
    return row ? mapUser(row) : null;
}
async function findById(id) {
    const row = await (0, database_1.queryOne)(`${SELECT_USER} WHERE u.id = ? LIMIT 1`, [id]);
    return row ? mapUser(row) : null;
}
/**
 * Called once right after a successful Firebase sign-up. Idempotent: calling it
 * again with the same UID simply returns the existing account, which makes the
 * client safe to retry after a dropped connection.
 *
 * The role is hard-coded to FARMER here - admins are provisioned directly in
 * MySQL, never through a public endpoint.
 */
async function syncUser(input) {
    const existing = await findByFirebaseUid(input.firebaseUid);
    if (existing) {
        if (!existing.is_active) {
            throw new apiError_1.ForbiddenError('Your account has been deactivated. Contact the administrator.');
        }
        return { user: existing, created: false };
    }
    const emailOwner = await (0, database_1.queryOne)('SELECT id, firebase_uid FROM users WHERE email = ? LIMIT 1', [input.email]);
    if (emailOwner) {
        // Same email, different Firebase account: re-point the row at the new UID so
        // a deleted-and-recreated Firebase user can still sign in.
        throw new apiError_1.ForbiddenError('This email is already registered to another account');
    }
    const userId = await (0, database_1.withTransaction)(async (connection) => {
        const [userResult] = await connection.query('INSERT INTO users (firebase_uid, email, full_name, role) VALUES (?, ?, ?, ?)', [input.firebaseUid, input.email, input.fullName, roles_1.ROLES.FARMER]);
        const insertedId = userResult.insertId;
        await connection.query('INSERT INTO farmer_profiles (user_id) VALUES (?)', [insertedId]);
        return insertedId;
    });
    const created = await findById(userId);
    if (!created)
        throw new apiError_1.UnauthorizedError('Account could not be created');
    return { user: created, created: true };
}
async function getCurrentUser(mysqlId) {
    const user = await findById(mysqlId);
    if (!user)
        throw new apiError_1.UnauthorizedError('Account no longer exists');
    return user;
}
