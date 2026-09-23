"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAdminDashboard = getAdminDashboard;
exports.listFarmers = listFarmers;
exports.getFarmerDetail = getFarmerDetail;
exports.toggleFarmerActive = toggleFarmerActive;
exports.getFarmerDashboard = getFarmerDashboard;
const database_1 = require("../../config/database");
const apiError_1 = require("../../core/utils/apiError");
const apiResponse_1 = require("../../core/utils/apiResponse");
const fileHelper_1 = require("../../core/utils/fileHelper");
const animalRepository = __importStar(require("../animals/animals.repository"));
const applicationRepository = __importStar(require("../applications/applications.repository"));
const claimRepository = __importStar(require("../claims/claims.repository"));
const animals_service_1 = require("../animals/animals.service");
const applications_service_1 = require("../applications/applications.service");
const claims_service_1 = require("../claims/claims.service");
async function getAdminDashboard() {
    const counts = await (0, database_1.queryOne)(`
    SELECT
      (SELECT COUNT(*) FROM users WHERE role = 'FARMER')                                   AS total_farmers,
      (SELECT COUNT(*) FROM users WHERE role = 'FARMER' AND is_active = 1)                 AS active_farmers,
      (SELECT COUNT(*) FROM animals WHERE is_active = 1)                                   AS total_animals,
      (SELECT COUNT(*) FROM schemes)                                                       AS total_schemes,
      (SELECT COUNT(*) FROM schemes WHERE is_active = 1)                                   AS active_schemes,
      (SELECT COUNT(*) FROM applications WHERE status = 'PENDING')                         AS pending_applications,
      (SELECT COUNT(*) FROM applications WHERE status = 'APPROVED')                        AS approved_applications,
      (SELECT COUNT(*) FROM applications WHERE status = 'REJECTED')                        AS rejected_applications,
      (SELECT COUNT(*) FROM claims WHERE status = 'SUBMITTED')                             AS submitted_claims,
      (SELECT COUNT(*) FROM claims WHERE status = 'APPROVED')                              AS approved_claims,
      (SELECT COUNT(*) FROM claims WHERE status = 'REJECTED')                              AS rejected_claims,
      (SELECT COALESCE(SUM(coverage_amount), 0) FROM applications WHERE status='APPROVED') AS total_sum_insured,
      (SELECT COALESCE(SUM(approved_amount), 0) FROM claims WHERE status = 'APPROVED')     AS total_payout
  `);
    const recentApplications = await (0, database_1.query)(`
    SELECT ap.id, ap.application_number, ap.status, ap.created_at, u.full_name AS farmer_name, an.ear_tag
      FROM applications ap
      INNER JOIN farmer_profiles fp ON fp.id = ap.farmer_profile_id
      INNER JOIN users u ON u.id = fp.user_id
      INNER JOIN animals an ON an.id = ap.animal_id
     ORDER BY ap.created_at DESC
     LIMIT 10
  `);
    const recentClaims = await (0, database_1.query)(`
    SELECT c.id, c.claim_number, c.status, c.created_at, u.full_name AS farmer_name, c.incident_type
      FROM claims c
      INNER JOIN applications ap ON ap.id = c.application_id
      INNER JOIN farmer_profiles fp ON fp.id = ap.farmer_profile_id
      INNER JOIN users u ON u.id = fp.user_id
     ORDER BY c.created_at DESC
     LIMIT 10
  `);
    const activity = [
        ...recentApplications.map((row) => ({
            type: 'APPLICATION',
            id: row.id,
            reference: row.application_number,
            title: `Application ${row.application_number}`,
            subtitle: `${row.farmer_name} - ${row.ear_tag}`,
            status: row.status,
            created_at: row.created_at,
        })),
        ...recentClaims.map((row) => ({
            type: 'CLAIM',
            id: row.id,
            reference: row.claim_number,
            title: `Claim ${row.claim_number}`,
            subtitle: `${row.farmer_name} - ${row.incident_type}`,
            status: row.status,
            created_at: row.created_at,
        })),
    ]
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
        .slice(0, 10);
    return {
        total_farmers: Number(counts?.total_farmers ?? 0),
        active_farmers: Number(counts?.active_farmers ?? 0),
        total_animals: Number(counts?.total_animals ?? 0),
        total_schemes: Number(counts?.total_schemes ?? 0),
        active_schemes: Number(counts?.active_schemes ?? 0),
        pending_applications: Number(counts?.pending_applications ?? 0),
        approved_applications: Number(counts?.approved_applications ?? 0),
        rejected_applications: Number(counts?.rejected_applications ?? 0),
        submitted_claims: Number(counts?.submitted_claims ?? 0),
        approved_claims: Number(counts?.approved_claims ?? 0),
        rejected_claims: Number(counts?.rejected_claims ?? 0),
        total_sum_insured: Number(counts?.total_sum_insured ?? 0),
        total_payout: Number(counts?.total_payout ?? 0),
        recent_activity: activity,
    };
}
const SELECT_FARMER = `
  SELECT u.id AS user_id, fp.id AS farmer_profile_id, u.full_name, u.email, fp.phone,
         fp.profile_image_path, u.is_active, u.created_at,
         (SELECT COUNT(*) FROM animals a WHERE a.farmer_profile_id = fp.id) AS animal_count,
         (SELECT COUNT(*) FROM applications ap WHERE ap.farmer_profile_id = fp.id) AS application_count,
         (SELECT COUNT(*) FROM claims c
            INNER JOIN applications ap2 ON ap2.id = c.application_id
           WHERE ap2.farmer_profile_id = fp.id) AS claim_count
    FROM users u
    INNER JOIN farmer_profiles fp ON fp.user_id = u.id
   WHERE u.role = 'FARMER'
`;
function mapFarmer(row) {
    return {
        user_id: row.user_id,
        farmer_profile_id: row.farmer_profile_id,
        full_name: row.full_name,
        email: row.email,
        phone: row.phone,
        image_url: (0, fileHelper_1.toPublicUrl)(row.profile_image_path),
        is_active: Boolean(row.is_active),
        animal_count: Number(row.animal_count),
        application_count: Number(row.application_count),
        claim_count: Number(row.claim_count),
        created_at: row.created_at,
    };
}
async function listFarmers(filters, page, limit, offset) {
    const conditions = [];
    const params = [];
    if (filters.search) {
        conditions.push('(u.full_name LIKE ? OR u.email LIKE ? OR fp.phone LIKE ?)');
        const like = `%${filters.search}%`;
        params.push(like, like, like);
    }
    if (filters.isActive !== undefined) {
        conditions.push('u.is_active = ?');
        params.push(filters.isActive ? 1 : 0);
    }
    const extra = conditions.length ? ` AND ${conditions.join(' AND ')}` : '';
    const [rows, totalRow] = await Promise.all([
        (0, database_1.query)(`${SELECT_FARMER}${extra} ORDER BY u.id DESC LIMIT ? OFFSET ?`, [...params, limit, offset]),
        (0, database_1.queryOne)(`SELECT COUNT(*) AS total
         FROM users u
         INNER JOIN farmer_profiles fp ON fp.user_id = u.id
        WHERE u.role = 'FARMER'${extra}`, params),
    ]);
    return (0, apiResponse_1.paginate)(rows.map(mapFarmer), Number(totalRow?.total ?? 0), page, limit);
}
/** Master audit view behind AdminFarmerDetailPage (3 tabs). */
async function getFarmerDetail(userId) {
    const row = await (0, database_1.queryOne)(`${SELECT_FARMER} AND u.id = ? LIMIT 1`, [userId]);
    if (!row)
        throw new apiError_1.NotFoundError('Farmer not found');
    const farmer = mapFarmer(row);
    const [animals, applications, claims] = await Promise.all([
        animalRepository.list({ farmerProfileId: farmer.farmer_profile_id }, 200, 0),
        applicationRepository.list({ farmerProfileId: farmer.farmer_profile_id }, 200, 0),
        claimRepository.list({ farmerProfileId: farmer.farmer_profile_id }, 200, 0),
    ]);
    return {
        farmer,
        animals: animals.map(animals_service_1.mapAnimal),
        applications: applications.map(applications_service_1.mapApplication),
        claims: claims.map(claims_service_1.mapClaim),
    };
}
/** Soft block/unblock: flips users.is_active, which auth.middleware enforces. */
async function toggleFarmerActive(userId) {
    const row = await (0, database_1.queryOne)(`${SELECT_FARMER} AND u.id = ? LIMIT 1`, [userId]);
    if (!row)
        throw new apiError_1.NotFoundError('Farmer not found');
    await (0, database_1.execute)('UPDATE users SET is_active = ? WHERE id = ? AND role = ?', [row.is_active ? 0 : 1, userId, 'FARMER']);
    const updated = await (0, database_1.queryOne)(`${SELECT_FARMER} AND u.id = ? LIMIT 1`, [userId]);
    return mapFarmer(updated);
}
/** Stats block on FarmerHomePage. */
async function getFarmerDashboard(farmerProfileId) {
    const row = await (0, database_1.queryOne)(`SELECT
       (SELECT COUNT(*) FROM animals WHERE farmer_profile_id = ?)                                    AS total_animals,
       (SELECT COUNT(*) FROM animals WHERE farmer_profile_id = ? AND is_active = 1)                  AS active_animals,
       (SELECT COUNT(*) FROM applications WHERE farmer_profile_id = ? AND status = 'PENDING')        AS pending_applications,
       (SELECT COUNT(*) FROM applications WHERE farmer_profile_id = ? AND status = 'APPROVED')       AS approved_applications,
       (SELECT COUNT(*) FROM applications WHERE farmer_profile_id = ? AND status = 'REJECTED')       AS rejected_applications,
       (SELECT COUNT(*) FROM applications
          WHERE farmer_profile_id = ? AND status = 'APPROVED'
            AND (policy_end_date IS NULL OR policy_end_date >= CURDATE()))                          AS active_policies,
       (SELECT COUNT(*) FROM claims c INNER JOIN applications ap ON ap.id = c.application_id
          WHERE ap.farmer_profile_id = ? AND c.status = 'SUBMITTED')                                 AS submitted_claims,
       (SELECT COUNT(*) FROM claims c INNER JOIN applications ap ON ap.id = c.application_id
          WHERE ap.farmer_profile_id = ? AND c.status = 'APPROVED')                                  AS approved_claims,
       (SELECT COUNT(*) FROM claims c INNER JOIN applications ap ON ap.id = c.application_id
          WHERE ap.farmer_profile_id = ? AND c.status = 'REJECTED')                                  AS rejected_claims,
       (SELECT COALESCE(SUM(coverage_amount), 0) FROM applications
          WHERE farmer_profile_id = ? AND status = 'APPROVED')                                       AS total_sum_insured,
       (SELECT COALESCE(SUM(c.approved_amount), 0) FROM claims c
          INNER JOIN applications ap ON ap.id = c.application_id
          WHERE ap.farmer_profile_id = ? AND c.status = 'APPROVED')                                  AS total_payout`, Array.from({ length: 11 }, () => farmerProfileId));
    return {
        total_animals: Number(row?.total_animals ?? 0),
        active_animals: Number(row?.active_animals ?? 0),
        pending_applications: Number(row?.pending_applications ?? 0),
        approved_applications: Number(row?.approved_applications ?? 0),
        rejected_applications: Number(row?.rejected_applications ?? 0),
        active_policies: Number(row?.active_policies ?? 0),
        submitted_claims: Number(row?.submitted_claims ?? 0),
        approved_claims: Number(row?.approved_claims ?? 0),
        rejected_claims: Number(row?.rejected_claims ?? 0),
        total_sum_insured: Number(row?.total_sum_insured ?? 0),
        total_payout: Number(row?.total_payout ?? 0),
    };
}
