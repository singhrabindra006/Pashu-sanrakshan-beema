"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findById = findById;
exports.listAvailable = listAvailable;
exports.countAvailable = countAvailable;
exports.listAll = listAll;
exports.countAll = countAll;
exports.insert = insert;
exports.update = update;
exports.setActive = setActive;
const database_1 = require("../../config/database");
const AVAILABLE_EXPR = '(s.is_active = 1 AND CURDATE() BETWEEN s.start_date AND s.end_date)';
const SELECT_SCHEME = `
  SELECT s.id, s.name, s.description, s.max_coverage, s.start_date, s.end_date,
         s.is_active, s.created_at, ${AVAILABLE_EXPR} AS is_available
    FROM schemes s
`;
function findById(id) {
    return (0, database_1.queryOne)(`${SELECT_SCHEME} WHERE s.id = ? LIMIT 1`, [id]);
}
/** Farmer-facing list: active and inside the validity window. */
function listAvailable(limit, offset) {
    return (0, database_1.query)(`${SELECT_SCHEME} WHERE ${AVAILABLE_EXPR} ORDER BY s.end_date ASC, s.id DESC LIMIT ? OFFSET ?`, [limit, offset]);
}
async function countAvailable() {
    const row = await (0, database_1.queryOne)(`SELECT COUNT(*) AS total FROM schemes s WHERE ${AVAILABLE_EXPR}`);
    return row?.total ?? 0;
}
/** Admin-facing list: everything, optionally narrowed by the Active/Inactive tab. */
function listAll(isActive, limit, offset) {
    const where = isActive === undefined ? '' : 'WHERE s.is_active = ?';
    const params = isActive === undefined ? [] : [isActive ? 1 : 0];
    return (0, database_1.query)(`${SELECT_SCHEME} ${where} ORDER BY s.id DESC LIMIT ? OFFSET ?`, [...params, limit, offset]);
}
async function countAll(isActive) {
    const where = isActive === undefined ? '' : 'WHERE is_active = ?';
    const params = isActive === undefined ? [] : [isActive ? 1 : 0];
    const row = await (0, database_1.queryOne)(`SELECT COUNT(*) AS total FROM schemes ${where}`, params);
    return row?.total ?? 0;
}
async function insert(input) {
    const result = await (0, database_1.execute)('INSERT INTO schemes (name, description, max_coverage, start_date, end_date) VALUES (?, ?, ?, ?, ?)', [input.name, input.description, input.max_coverage, input.start_date, input.end_date]);
    return result.insertId;
}
async function update(id, input) {
    await (0, database_1.execute)('UPDATE schemes SET name = ?, description = ?, max_coverage = ?, start_date = ?, end_date = ? WHERE id = ?', [input.name, input.description, input.max_coverage, input.start_date, input.end_date, id]);
}
async function setActive(id, isActive) {
    await (0, database_1.execute)('UPDATE schemes SET is_active = ? WHERE id = ?', [isActive ? 1 : 0, id]);
}
