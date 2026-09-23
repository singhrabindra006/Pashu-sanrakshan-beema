"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findById = findById;
exports.list = list;
exports.count = count;
exports.hasOpenApplicationForAnimal = hasOpenApplicationForAnimal;
exports.insert = insert;
exports.nextPolicyNumber = nextPolicyNumber;
exports.approve = approve;
exports.reject = reject;
exports.isPolicyNumberTaken = isPolicyNumberTaken;
exports.listClaimable = listClaimable;
const database_1 = require("../../config/database");
const policyGenerator_1 = require("../../core/utils/policyGenerator");
const SELECT_APPLICATION = `
  SELECT ap.id, ap.application_number, ap.farmer_profile_id, ap.animal_id, ap.scheme_id,
         ap.coverage_amount, ap.status, ap.policy_number, ap.policy_start_date, ap.policy_end_date,
         ap.rejection_reason, ap.decided_by, ap.decided_at, ap.created_at,
         an.ear_tag AS animal_ear_tag, an.animal_type, an.breed AS animal_breed,
         an.age_months AS animal_age_months, an.photo_path AS animal_photo_path,
         s.name AS scheme_name, s.max_coverage AS scheme_max_coverage,
         s.start_date AS scheme_start_date, s.end_date AS scheme_end_date,
         fp.user_id AS farmer_user_id, fp.phone AS farmer_phone,
         u.full_name AS farmer_name, u.email AS farmer_email,
         du.full_name AS decided_by_name,
         (SELECT COUNT(*) FROM claims c WHERE c.application_id = ap.id) AS claim_count
    FROM applications ap
    INNER JOIN animals an ON an.id = ap.animal_id
    INNER JOIN schemes s ON s.id = ap.scheme_id
    INNER JOIN farmer_profiles fp ON fp.id = ap.farmer_profile_id
    INNER JOIN users u ON u.id = fp.user_id
    LEFT JOIN users du ON du.id = ap.decided_by
`;
function findById(id) {
    return (0, database_1.queryOne)(`${SELECT_APPLICATION} WHERE ap.id = ? LIMIT 1`, [id]);
}
function buildWhere(filter) {
    const conditions = [];
    const params = [];
    if (filter.farmerProfileId !== undefined) {
        conditions.push('ap.farmer_profile_id = ?');
        params.push(filter.farmerProfileId);
    }
    if (filter.status) {
        conditions.push('ap.status = ?');
        params.push(filter.status);
    }
    if (filter.search) {
        conditions.push('(ap.application_number LIKE ? OR ap.policy_number LIKE ? OR u.full_name LIKE ? OR an.ear_tag LIKE ?)');
        const like = `%${filter.search}%`;
        params.push(like, like, like, like);
    }
    return { clause: conditions.length ? `WHERE ${conditions.join(' AND ')}` : '', params };
}
function list(filter, limit, offset) {
    const { clause, params } = buildWhere(filter);
    return (0, database_1.query)(`${SELECT_APPLICATION} ${clause} ORDER BY ap.id DESC LIMIT ? OFFSET ?`, [
        ...params,
        limit,
        offset,
    ]);
}
async function count(filter) {
    const { clause, params } = buildWhere(filter);
    const row = await (0, database_1.queryOne)(`SELECT COUNT(*) AS total
       FROM applications ap
       INNER JOIN animals an ON an.id = ap.animal_id
       INNER JOIN farmer_profiles fp ON fp.id = ap.farmer_profile_id
       INNER JOIN users u ON u.id = fp.user_id
       ${clause}`, params);
    return row?.total ?? 0;
}
/** An animal may only have one live application (PENDING or APPROVED) at a time. */
async function hasOpenApplicationForAnimal(animalId) {
    const row = await (0, database_1.queryOne)(`SELECT COUNT(*) AS total FROM applications WHERE animal_id = ? AND status IN ('PENDING','APPROVED')`, [animalId]);
    return (row?.total ?? 0) > 0;
}
async function insert(input) {
    return (0, policyGenerator_1.withUniqueNumberRetry)(async (attempt) => (0, database_1.withTransaction)(async (connection) => {
        const [countRows] = await connection.query('SELECT COUNT(*) AS total FROM applications WHERE DATE(created_at) = CURDATE()');
        const sequence = Number(countRows[0]?.total ?? 0) + 1 + attempt;
        const applicationNumber = (0, policyGenerator_1.generateApplicationNumber)(sequence);
        const [result] = await connection.query(`INSERT INTO applications (application_number, farmer_profile_id, animal_id, scheme_id, coverage_amount)
         VALUES (?, ?, ?, ?, ?)`, [applicationNumber, input.farmerProfileId, input.animalId, input.schemeId, input.coverageAmount]);
        return result.insertId;
    }));
}
/** Next POL-YYYY-NNNNN for the current year. */
async function nextPolicyNumber() {
    const year = new Date().getFullYear();
    const row = await (0, database_1.queryOne)('SELECT COUNT(*) AS total FROM applications WHERE policy_number LIKE ?', [`POL-${year}-%`]);
    return (0, policyGenerator_1.generatePolicyNumber)(Number(row?.total ?? 0) + 1);
}
async function approve(id, adminUserId, policyNumber, startDate, endDate) {
    await (0, database_1.execute)(`UPDATE applications
        SET status = 'APPROVED', policy_number = ?, policy_start_date = ?, policy_end_date = ?,
            rejection_reason = NULL, decided_by = ?, decided_at = CURRENT_TIMESTAMP
      WHERE id = ? AND status = 'PENDING'`, [policyNumber, startDate, endDate, adminUserId, id]);
}
async function reject(id, adminUserId, reason) {
    await (0, database_1.execute)(`UPDATE applications
        SET status = 'REJECTED', rejection_reason = ?, policy_number = NULL,
            policy_start_date = NULL, policy_end_date = NULL,
            decided_by = ?, decided_at = CURRENT_TIMESTAMP
      WHERE id = ? AND status = 'PENDING'`, [reason, adminUserId, id]);
}
function isPolicyNumberTaken(policyNumber, exceptId) {
    return (0, database_1.queryOne)('SELECT id FROM applications WHERE policy_number = ? AND id <> ? LIMIT 1', [policyNumber, exceptId]).then((row) => row !== null);
}
/** Approved applications the farmer can raise a claim against. */
function listClaimable(farmerProfileId) {
    return (0, database_1.query)(`${SELECT_APPLICATION} WHERE ap.farmer_profile_id = ? AND ap.status = 'APPROVED' ORDER BY ap.id DESC`, [farmerProfileId]);
}
