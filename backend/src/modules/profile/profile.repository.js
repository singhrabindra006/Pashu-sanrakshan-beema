"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findByProfileId = findByProfileId;
exports.findByUserId = findByUserId;
exports.updatePhone = updatePhone;
exports.updateImagePath = updateImagePath;
const database_1 = require("../../config/database");
const SELECT_PROFILE = `
  SELECT fp.id, fp.user_id, fp.phone, fp.profile_image_path, fp.created_at,
         u.full_name, u.email, u.is_active
    FROM farmer_profiles fp
    INNER JOIN users u ON u.id = fp.user_id
`;
function findByProfileId(profileId) {
    return (0, database_1.queryOne)(`${SELECT_PROFILE} WHERE fp.id = ? LIMIT 1`, [profileId]);
}
function findByUserId(userId) {
    return (0, database_1.queryOne)(`${SELECT_PROFILE} WHERE fp.user_id = ? LIMIT 1`, [userId]);
}
async function updatePhone(profileId, phone) {
    await (0, database_1.execute)('UPDATE farmer_profiles SET phone = ? WHERE id = ?', [phone, profileId]);
}
async function updateImagePath(profileId, storedPath) {
    await (0, database_1.execute)('UPDATE farmer_profiles SET profile_image_path = ? WHERE id = ?', [storedPath, profileId]);
}
