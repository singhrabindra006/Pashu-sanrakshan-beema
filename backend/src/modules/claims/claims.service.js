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
exports.submitClaim = submitClaim;
exports.listMyClaims = listMyClaims;
exports.listAllClaims = listAllClaims;
exports.getClaim = getClaim;
exports.decideClaim = decideClaim;
exports.discardEvidence = discardEvidence;
exports.mapClaim = map;
const roles_1 = require("../../core/constants/roles");
const status_1 = require("../../core/constants/status");
const apiError_1 = require("../../core/utils/apiError");
const apiResponse_1 = require("../../core/utils/apiResponse");
const fileHelper_1 = require("../../core/utils/fileHelper");
const policyGenerator_1 = require("../../core/utils/policyGenerator");
const applicationRepository = __importStar(require("../applications/applications.repository"));
const repository = __importStar(require("./claims.repository"));
function map(row) {
    return {
        id: row.id,
        claim_number: row.claim_number,
        application_id: row.application_id,
        incident_type: row.incident_type,
        incident_date: row.incident_date,
        description: row.description,
        claimed_amount: Number(row.claimed_amount),
        approved_amount: row.approved_amount === null ? null : Number(row.approved_amount),
        evidence_path: row.evidence_path,
        evidence_url: (0, fileHelper_1.toPublicUrl)(row.evidence_path),
        status: row.status,
        rejection_reason: row.rejection_reason,
        decided_by: row.decided_by,
        decided_by_name: row.decided_by_name,
        decided_at: row.decided_at,
        created_at: row.created_at,
        application_number: row.application_number,
        policy_number: row.policy_number,
        policy_start_date: row.policy_start_date,
        policy_end_date: row.policy_end_date,
        coverage_amount: Number(row.coverage_amount),
        farmer_profile_id: row.farmer_profile_id,
        farmer_name: row.farmer_name,
        farmer_email: row.farmer_email,
        farmer_phone: row.farmer_phone,
        animal_id: row.animal_id,
        animal_ear_tag: row.animal_ear_tag,
        animal_type: row.animal_type,
        animal_breed: row.animal_breed,
        animal_photo_url: (0, fileHelper_1.toPublicUrl)(row.animal_photo_path),
        scheme_name: row.scheme_name,
    };
}
async function load(id) {
    const row = await repository.findById(id);
    if (!row)
        throw new apiError_1.NotFoundError('Claim not found');
    return row;
}
/**
 * POST /claims
 * The parent application must be APPROVED and owned by the caller. The incident
 * has to sit inside the policy window and the request cannot exceed the
 * remaining sum insured.
 */
async function submitClaim(farmerProfileId, body, evidence) {
    const applicationId = Number(body.application_id);
    const application = await applicationRepository.findById(applicationId);
    if (!application)
        throw new apiError_1.NotFoundError('Application not found');
    if (application.farmer_profile_id !== farmerProfileId) {
        throw new apiError_1.ForbiddenError('This application belongs to another farmer');
    }
    if (application.status !== status_1.APPLICATION_STATUS.APPROVED) {
        throw new apiError_1.BadRequestError('Claims can only be raised against an approved application');
    }
    const incidentDate = String(body.incident_date).slice(0, 10);
    const today = (0, policyGenerator_1.toDateOnly)(new Date());
    if (incidentDate > today) {
        throw new apiError_1.BadRequestError('Incident date cannot be in the future');
    }
    if (application.policy_start_date && incidentDate < application.policy_start_date) {
        throw new apiError_1.BadRequestError('Incident date is before the policy start date');
    }
    if (application.policy_end_date && incidentDate > application.policy_end_date) {
        throw new apiError_1.BadRequestError('Incident date is after the policy end date');
    }
    const claimedAmount = Number(body.claimed_amount);
    const alreadyApproved = await repository.approvedTotal(applicationId);
    const remaining = Number(application.coverage_amount) - alreadyApproved;
    if (claimedAmount > remaining) {
        throw new apiError_1.BadRequestError(`Claimed amount exceeds the remaining sum insured of ${remaining}`);
    }
    if (await repository.hasOpenClaim(applicationId)) {
        throw new apiError_1.ConflictError('A claim on this policy is already awaiting a decision');
    }
    const id = await repository.insert({
        applicationId,
        incidentType: String(body.incident_type).toUpperCase(),
        incidentDate,
        description: String(body.description).trim(),
        claimedAmount,
        evidencePath: evidence ? (0, fileHelper_1.storedPathFromUpload)('claims', evidence) : null,
    });
    return map(await load(id));
}
async function listMyClaims(farmerProfileId, status, page, limit, offset) {
    const filter = { farmerProfileId, status };
    const [rows, total] = await Promise.all([repository.list(filter, limit, offset), repository.count(filter)]);
    return (0, apiResponse_1.paginate)(rows.map(map), total, page, limit);
}
async function listAllClaims(filters, page, limit, offset) {
    const [rows, total] = await Promise.all([repository.list(filters, limit, offset), repository.count(filters)]);
    return (0, apiResponse_1.paginate)(rows.map(map), total, page, limit);
}
async function getClaim(id, viewer) {
    const row = await load(id);
    if (viewer.role !== roles_1.ROLES.ADMIN && row.farmer_profile_id !== viewer.farmerProfileId) {
        throw new apiError_1.ForbiddenError('This claim belongs to another farmer');
    }
    return map(row);
}
/** PATCH /admin/claims/:id/decide */
async function decideClaim(id, adminUserId, input) {
    const claim = await load(id);
    if (claim.status !== status_1.CLAIM_STATUS.SUBMITTED) {
        throw new apiError_1.ConflictError(`Claim has already been ${claim.status.toLowerCase()}`);
    }
    if (input.action === 'REJECT') {
        const reason = (input.reason ?? '').trim();
        if (!reason)
            throw new apiError_1.BadRequestError('A rejection reason is required');
        await repository.reject(id, adminUserId, reason);
        return map(await load(id));
    }
    const approvedAmount = Number(input.approved_amount);
    if (!Number.isFinite(approvedAmount) || approvedAmount <= 0) {
        throw new apiError_1.BadRequestError('An approved amount greater than 0 is required');
    }
    if (approvedAmount > Number(claim.claimed_amount)) {
        throw new apiError_1.BadRequestError('Approved amount cannot exceed the claimed amount');
    }
    const alreadyApproved = await repository.approvedTotal(claim.application_id, id);
    const remaining = Number(claim.coverage_amount) - alreadyApproved;
    if (approvedAmount > remaining) {
        throw new apiError_1.BadRequestError(`Approved amount exceeds the remaining sum insured of ${remaining}`);
    }
    await repository.approve(id, adminUserId, approvedAmount);
    return map(await load(id));
}
/** Used when an upload succeeded but the surrounding request later failed. */
async function discardEvidence(storedPath) {
    await (0, fileHelper_1.deleteFile)(storedPath);
}
