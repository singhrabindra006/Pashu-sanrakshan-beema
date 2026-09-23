"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.stream = void 0;
const fs_1 = __importDefault(require("fs"));
const database_1 = require("../../config/database");
const roles_1 = require("../../core/constants/roles");
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const apiError_1 = require("../../core/utils/apiError");
const asyncHandler_1 = require("../../core/utils/asyncHandler");
const fileHelper_1 = require("../../core/utils/fileHelper");
/**
 * Farmers may only read files attached to their own profile, animals or claims.
 * Admins may read everything, since they review every application and claim.
 */
async function assertFarmerCanRead(category, storedPath, farmerProfileId) {
    if (!farmerProfileId)
        throw new apiError_1.ForbiddenError('No farmer profile is linked to this account');
    const sql = {
        profiles: 'SELECT id FROM farmer_profiles WHERE id = ? AND profile_image_path = ? LIMIT 1',
        animals: 'SELECT id FROM animals WHERE farmer_profile_id = ? AND photo_path = ? LIMIT 1',
        claims: `SELECT c.id
               FROM claims c
               INNER JOIN applications ap ON ap.id = c.application_id
              WHERE ap.farmer_profile_id = ? AND c.evidence_path = ?
              LIMIT 1`,
    };
    const row = await (0, database_1.queryOne)(sql[category], [farmerProfileId, storedPath]);
    if (!row)
        throw new apiError_1.ForbiddenError('You do not have access to this file');
}
/**
 * GET /files/:category/:filename
 * Streams an upload after an ownership check. Supports Range requests so the
 * Flutter PDF/image viewers can seek.
 */
exports.stream = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const user = (0, auth_middleware_1.currentUser)(req);
    const category = req.params.category;
    const fileName = req.params.filename;
    const absolutePath = (0, fileHelper_1.resolveAbsolutePath)(category, fileName);
    if (!(await (0, fileHelper_1.fileExists)(absolutePath))) {
        throw new apiError_1.NotFoundError('File not found');
    }
    if (user.role !== roles_1.ROLES.ADMIN) {
        await assertFarmerCanRead(category, (0, fileHelper_1.toStoredPath)(category, fileName), user.farmerProfileId);
    }
    const stat = await fs_1.default.promises.stat(absolutePath);
    const mimeType = (0, fileHelper_1.getMimeType)(fileName);
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Content-Disposition', `inline; filename="${fileName}"`);
    res.setHeader('Cache-Control', 'private, max-age=86400');
    res.setHeader('Accept-Ranges', 'bytes');
    const range = req.headers.range;
    if (range) {
        const match = /bytes=(\d*)-(\d*)/.exec(range);
        const start = match && match[1] ? Number(match[1]) : 0;
        const end = match && match[2] ? Number(match[2]) : stat.size - 1;
        if (start >= stat.size || end >= stat.size || start > end) {
            res.status(416).setHeader('Content-Range', `bytes */${stat.size}`);
            res.end();
            return;
        }
        res.status(206);
        res.setHeader('Content-Range', `bytes ${start}-${end}/${stat.size}`);
        res.setHeader('Content-Length', String(end - start + 1));
        fs_1.default.createReadStream(absolutePath, { start, end }).pipe(res);
        return;
    }
    res.setHeader('Content-Length', String(stat.size));
    fs_1.default.createReadStream(absolutePath).pipe(res);
});
