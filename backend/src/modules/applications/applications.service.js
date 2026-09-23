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
exports.submitApplication = submitApplication;
exports.listMyApplications = listMyApplications;
exports.listAllApplications = listAllApplications;
exports.getApplication = getApplication;
exports.listClaimableApplications = listClaimableApplications;
exports.decideApplication = decideApplication;
exports.mapApplication = map;
const roles_1 = require("../../core/constants/roles");
const status_1 = require("../../core/constants/status");
const apiError_1 = require("../../core/utils/apiError");
const apiResponse_1 = require("../../core/utils/apiResponse");
const fileHelper_1 = require("../../core/utils/fileHelper");
const policyGenerator_1 = require("../../core/utils/policyGenerator");
const animalRepository = __importStar(require("../animals/animals.repository"));
const schemeRepository = __importStar(require("../schemes/schemes.repository"));
const repository = __importStar(require("./applications.repository"));
function map(row) {
    return {
        id: row.id,
        application_number: row.application_number,
        farmer_profile_id: row.farmer_profile_id,
        animal_id: row.animal_id,
        scheme_id: row.scheme_id,
        coverage_amount: Number(row.coverage_amount),
        status: row.status,
        policy_number: row.policy_number,
        policy_start_date: row.policy_start_date,
        policy_end_date: row.policy_end_date,
        rejection_reason: row.rejection_reason,
        decided_by: row.decided_by,
        decided_by_name: row.decided_by_name,
        decided_at: row.decided_at,
        created_at: row.created_at,
        animal_ear_tag: row.animal_ear_tag,
        animal_type: row.animal_type,
        animal_breed: row.animal_breed,
        animal_age_months: Number(row.animal_age_months),
        animal_photo_url: (0, fileHelper_1.toPublicUrl)(row.animal_photo_path),
        scheme_name: row.scheme_name,
        scheme_max_coverage: Number(row.scheme_max_coverage),
        scheme_start_date: row.scheme_start_date,
        scheme_end_date: row.scheme_end_date,
        farmer_name: row.farmer_name,
        farmer_email: row.farmer_email,
        farmer_phone: row.farmer_phone,
        claim_count: Number(row.claim_count),
    };
}
async function load(id) {
    const row = await repository.findById(id);
    if (!row)
        throw new apiError_1.NotFoundError('Application not found');
    return row;
}
/**
 * POST /applications
 * Validates ownership, that the animal is still active, that the scheme is
 * available today, and that the requested coverage fits the scheme ceiling.
 */
async function submitApplication(farmerProfileId, body) {
    const animalId = Number(body.animal_id);
    const schemeId = Number(body.scheme_id);
    const coverageAmount = Number(body.coverage_amount);
    const animal = await animalRepository.findById(animalId);
    if (!animal)
        throw new apiError_1.NotFoundError('Animal not found');
    if (animal.farmer_profile_id !== farmerProfileId) {
        throw new apiError_1.ForbiddenError('This animal belongs to another farmer');
    }
    if (!animal.is_active) {
        throw new apiError_1.BadRequestError('This animal is inactive and cannot be insured');
    }
    const scheme = await schemeRepository.findById(schemeId);
    if (!scheme)
        throw new apiError_1.NotFoundError('Scheme not found');
    if (!scheme.is_available) {
        throw new apiError_1.BadRequestError('This scheme is not open for applications');
    }
    if (coverageAmount > Number(scheme.max_coverage)) {
        throw new apiError_1.BadRequestError(`Coverage cannot exceed the scheme maximum of ${Number(scheme.max_coverage)}`);
    }
    if (await repository.hasOpenApplicationForAnimal(animalId)) {
        throw new apiError_1.ConflictError('This animal already has a pending application or an active policy');
    }
    const id = await repository.insert({ farmerProfileId, animalId, schemeId, coverageAmount });
    return map(await load(id));
}
async function listMyApplications(farmerProfileId, status, page, limit, offset) {
    const filter = { farmerProfileId, status };
    const [rows, total] = await Promise.all([repository.list(filter, limit, offset), repository.count(filter)]);
    return (0, apiResponse_1.paginate)(rows.map(map), total, page, limit);
}
async function listAllApplications(filters, page, limit, offset) {
    const [rows, total] = await Promise.all([repository.list(filters, limit, offset), repository.count(filters)]);
    return (0, apiResponse_1.paginate)(rows.map(map), total, page, limit);
}
async function getApplication(id, viewer) {
    const row = await load(id);
    if (viewer.role !== roles_1.ROLES.ADMIN && row.farmer_profile_id !== viewer.farmerProfileId) {
        throw new apiError_1.ForbiddenError('This application belongs to another farmer');
    }
    return map(row);
}
async function listClaimableApplications(farmerProfileId) {
    const rows = await repository.listClaimable(farmerProfileId);
    return rows.map(map);
}
/**
 * PATCH /admin/applications/:id/decide
 * APPROVE issues the policy (number + window, generated when omitted);
 * REJECT records a mandatory reason. Only PENDING applications can be decided.
 */
async function decideApplication(id, adminUserId, input) {
    const application = await load(id);
    if (application.status !== status_1.APPLICATION_STATUS.PENDING) {
        throw new apiError_1.ConflictError(`Application has already been ${application.status.toLowerCase()}`);
    }
    if (input.action === 'REJECT') {
        const reason = (input.reason ?? '').trim();
        if (!reason)
            throw new apiError_1.BadRequestError('A rejection reason is required');
        await repository.reject(id, adminUserId, reason);
        return map(await load(id));
    }
    const fallback = (0, policyGenerator_1.defaultPolicyWindow)();
    const startDate = (input.start_date ?? fallback.start).slice(0, 10);
    const endDate = (input.end_date ?? fallback.end).slice(0, 10);
    if (endDate <= startDate) {
        throw new apiError_1.BadRequestError('Policy end date must be after the start date');
    }
    const policyNumber = (input.policy_number ?? '').trim() || (await repository.nextPolicyNumber());
    if (await repository.isPolicyNumberTaken(policyNumber, id)) {
        throw new apiError_1.ConflictError(`Policy number "${policyNumber}" is already in use`);
    }
    await repository.approve(id, adminUserId, policyNumber, startDate, endDate);
    return map(await load(id));
}
