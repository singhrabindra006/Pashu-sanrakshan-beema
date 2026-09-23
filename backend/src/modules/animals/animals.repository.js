"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findById = findById;
exports.findByEarTag = findByEarTag;
exports.list = list;
exports.count = count;
exports.insert = insert;
exports.update = update;
exports.setActive = setActive;
const database_1 = require("../../config/database");
const SELECT_ANIMAL = `
  SELECT a.id, a.farmer_profile_id, a.ear_tag, a.animal_type, a.breed, a.age_months,
         a.photo_path, a.is_active, a.created_at,
         u.full_name AS owner_name, fp.phone AS owner_phone,
         (SELECT COUNT(*) FROM applications ap
           WHERE ap.animal_id = a.id AND ap.status IN ('PENDING','APPROVED')) AS active_application_count
    FROM animals a
    INNER JOIN farmer_profiles fp ON fp.id = a.farmer_profile_id
    INNER JOIN users u ON u.id = fp.user_id
`;
function findById(id) {
    return (0, database_1.queryOne)(`${SELECT_ANIMAL} WHERE a.id = ? LIMIT 1`, [id]);
}
function findByEarTag(earTag) {
    return (0, database_1.queryOne)(`${SELECT_ANIMAL} WHERE a.ear_tag = ? LIMIT 1`, [earTag]);
}
function buildWhere(filter) {
    const conditions = ['a.farmer_profile_id = ?'];
    const params = [filter.farmerProfileId];
    if (filter.isActive !== undefined) {
        conditions.push('a.is_active = ?');
        params.push(filter.isActive ? 1 : 0);
    }
    if (filter.search) {
        conditions.push('(a.ear_tag LIKE ? OR a.breed LIKE ?)');
        params.push(`%${filter.search}%`, `%${filter.search}%`);
    }
    return { clause: `WHERE ${conditions.join(' AND ')}`, params };
}
function list(filter, limit, offset) {
    const { clause, params } = buildWhere(filter);
    return (0, database_1.query)(`${SELECT_ANIMAL} ${clause} ORDER BY a.id DESC LIMIT ? OFFSET ?`, [...params, limit, offset]);
}
async function count(filter) {
    const { clause, params } = buildWhere(filter);
    const row = await (0, database_1.queryOne)(`SELECT COUNT(*) AS total FROM animals a ${clause}`, params);
    return row?.total ?? 0;
}
async function insert(farmerProfileId, input, photoPath) {
    const result = await (0, database_1.execute)(`INSERT INTO animals (farmer_profile_id, ear_tag, animal_type, breed, age_months, photo_path)
     VALUES (?, ?, ?, ?, ?, ?)`, [farmerProfileId, input.ear_tag, input.animal_type, input.breed, input.age_months, photoPath]);
    return result.insertId;
}
async function update(id, input, photoPath) {
    // `undefined` means "keep the existing photo"; `null` would clear it.
    const setPhoto = photoPath === undefined ? '' : ', photo_path = ?';
    const params = [input.ear_tag, input.animal_type, input.breed, input.age_months];
    if (photoPath !== undefined)
        params.push(photoPath);
    params.push(id);
    await (0, database_1.execute)(`UPDATE animals SET ear_tag = ?, animal_type = ?, breed = ?, age_months = ?${setPhoto} WHERE id = ?`, params);
}
async function setActive(id, isActive) {
    await (0, database_1.execute)('UPDATE animals SET is_active = ? WHERE id = ?', [isActive ? 1 : 0, id]);
}
