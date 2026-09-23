"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findById = findById;
exports.list = list;
exports.count = count;
exports.hasOpenClaim = hasOpenClaim;
exports.approvedTotal = approvedTotal;
exports.insert = insert;
exports.approve = approve;
exports.reject = reject;
const database_1 = require("../../config/database");
const policyGenerator_1 = require("../../core/utils/policyGenerator");
const SELECT_CLAIM = `
  SELECT c.id, c.claim_number, c.application_id, c.incident_type, c.incident_date, c.description,
         c.claimed_amount, c.approved_amount, c.evidence_path, c.status, c.rejection_reason,
         c.decided_by, c.decided_at, c.created_at,
         ap.application_number, ap.policy_number, ap.policy_start_date, ap.policy_end_date,
         ap.coverage_amount, ap.farmer_profile_id,
         u.full_name AS farmer_name, u.email AS farmer_email, fp.phone AS farmer_phone,
         an.id AS animal_id, an.ear_tag AS animal_ear_tag, an.animal_type,
         an.breed AS animal_breed, an.photo_path AS animal_photo_path,
         s.name AS scheme_name,
         du.full_name AS decided_by_name
    FROM claims c
    INNER JOIN applications ap ON ap.id = c.application_id
    INNER JOIN farmer_profiles fp ON fp.id = ap.farmer_profile_id
    INNER JOIN users u ON u.id = fp.user_id
    INNER JOIN animals an ON an.id = ap.animal_id
    INNER JOIN schemes s ON s.id = ap.scheme_id
    LEFT JOIN users du ON du.id = c.decided_by
`;
function findById(id) {
    return (0, database_1.queryOne)(`${SELECT_CLAIM} WHERE c.id = ? LIMIT 1`, [id]);
}
function buildWhere(filter) {
    const conditions = [];
    const params = [];
    if (filter.farmerProfileId !== undefined) {
        conditions.push('ap.farmer_profile_id = ?');
        params.push(filter.farmerProfileId);
    }
    if (filter.status) {
        conditions.push('c.status = ?');
        params.push(filter.status);
    }
    if (filter.search) {
        conditions.push('(c.claim_number LIKE ? OR ap.application_number LIKE ? OR ap.policy_number LIKE ? OR u.full_name LIKE ? OR an.ear_tag LIKE ?)');
        const like = `%${filter.search}%`;
        params.push(like, like, like, like, like);
    }
    return { clause: conditions.length ? `WHERE ${conditions.join(' AND ')}` : '', params };
}
function list(filter, limit, offset) {
    const { clause, params } = buildWhere(filter);
    return (0, database_1.query)(`${SELECT_CLAIM} ${clause} ORDER BY c.id DESC LIMIT ? OFFSET ?`, [...params, limit, offset]);
}
async function count(filter) {
    const { clause, params } = buildWhere(filter);
    const row = await (0, database_1.queryOne)(`SELECT COUNT(*) AS total
       FROM claims c
       INNER JOIN applications ap ON ap.id = c.application_id
       INNER JOIN farmer_profiles fp ON fp.id = ap.farmer_profile_id
       INNER JOIN users u ON u.id = fp.user_id
       INNER JOIN animals an ON an.id = ap.animal_id
       ${clause}`, params);
    return row?.total ?? 0;
}
async function hasOpenClaim(applicationId) {
    const row = await (0, database_1.queryOne)(`SELECT COUNT(*) AS total FROM claims WHERE application_id = ? AND status = 'SUBMITTED'`, [applicationId]);
    return (row?.total ?? 0) > 0;
}
/** Total already paid out on a policy; used to cap further approvals. */
async function approvedTotal(applicationId, exceptClaimId) {
    const row = await (0, database_1.queryOne)(`SELECT COALESCE(SUM(approved_amount), 0) AS total
       FROM claims
      WHERE application_id = ? AND status = 'APPROVED' AND id <> ?`, [applicationId, exceptClaimId ?? 0]);
    return Number(row?.total ?? 0);
}
async function insert(input) {
    return (0, policyGenerator_1.withUniqueNumberRetry)(async (attempt) => (0, database_1.withTransaction)(async (connection) => {
        const [countRows] = await connection.query('SELECT COUNT(*) AS total FROM claims WHERE DATE(created_at) = CURDATE()');
        const sequence = Number(countRows[0]?.total ?? 0) + 1 + attempt;
        const claimNumber = (0, policyGenerator_1.generateClaimNumber)(sequence);
        const [result] = await connection.query(`INSERT INTO claims (claim_number, application_id, incident_type, incident_date, description,
                             claimed_amount, evidence_path)
         VALUES (?, ?, ?, ?, ?, ?, ?)`, [
            claimNumber,
            input.applicationId,
            input.incidentType,
            input.incidentDate,
            input.description,
            input.claimedAmount,
            input.evidencePath,
        ]);
        return result.insertId;
    }));
}
async function approve(id, adminUserId, approvedAmount) {
    await (0, database_1.execute)(`UPDATE claims
        SET status = 'APPROVED', approved_amount = ?, rejection_reason = NULL,
            decided_by = ?, decided_at = CURRENT_TIMESTAMP
      WHERE id = ? AND status = 'SUBMITTED'`, [approvedAmount, adminUserId, id]);
}
async function reject(id, adminUserId, reason) {
    await (0, database_1.execute)(`UPDATE claims
        SET status = 'REJECTED', approved_amount = NULL, rejection_reason = ?,
            decided_by = ?, decided_at = CURRENT_TIMESTAMP
      WHERE id = ? AND status = 'SUBMITTED'`, [reason, adminUserId, id]);
}
