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
exports.listMyAnimals = listMyAnimals;
exports.getAnimal = getAnimal;
exports.createAnimal = createAnimal;
exports.updateAnimal = updateAnimal;
exports.deactivateAnimal = deactivateAnimal;
exports.mapAnimal = map;
const roles_1 = require("../../core/constants/roles");
const apiError_1 = require("../../core/utils/apiError");
const apiResponse_1 = require("../../core/utils/apiResponse");
const fileHelper_1 = require("../../core/utils/fileHelper");
const repository = __importStar(require("./animals.repository"));
function map(row) {
    return {
        id: row.id,
        farmer_profile_id: row.farmer_profile_id,
        ear_tag: row.ear_tag,
        animal_type: row.animal_type,
        breed: row.breed,
        age_months: Number(row.age_months),
        photo_path: row.photo_path,
        photo_url: (0, fileHelper_1.toPublicUrl)(row.photo_path),
        is_active: Boolean(row.is_active),
        created_at: row.created_at,
        owner_name: row.owner_name,
        owner_phone: row.owner_phone,
        has_active_application: Number(row.active_application_count) > 0,
    };
}
function normalise(body) {
    return {
        ear_tag: String(body.ear_tag).trim().toUpperCase(),
        animal_type: String(body.animal_type).trim().toUpperCase(),
        breed: body.breed === undefined || body.breed === null || String(body.breed).trim() === '' ? null : String(body.breed).trim(),
        age_months: Number(body.age_months ?? 0),
    };
}
async function loadOwned(id, farmerProfileId) {
    const row = await repository.findById(id);
    if (!row)
        throw new apiError_1.NotFoundError('Animal not found');
    if (row.farmer_profile_id !== farmerProfileId) {
        throw new apiError_1.ForbiddenError('This animal belongs to another farmer');
    }
    return row;
}
async function assertEarTagFree(earTag, exceptId) {
    const existing = await repository.findByEarTag(earTag);
    if (existing && existing.id !== exceptId) {
        throw new apiError_1.ConflictError(`Ear tag "${earTag}" is already registered`);
    }
}
async function listMyAnimals(farmerProfileId, filters, page, limit, offset) {
    const filter = { farmerProfileId, ...filters };
    const [rows, total] = await Promise.all([repository.list(filter, limit, offset), repository.count(filter)]);
    return (0, apiResponse_1.paginate)(rows.map(map), total, page, limit);
}
/** Admins may inspect any animal; farmers only their own. */
async function getAnimal(id, viewer) {
    const row = await repository.findById(id);
    if (!row)
        throw new apiError_1.NotFoundError('Animal not found');
    if (viewer.role !== roles_1.ROLES.ADMIN && row.farmer_profile_id !== viewer.farmerProfileId) {
        throw new apiError_1.ForbiddenError('This animal belongs to another farmer');
    }
    return map(row);
}
async function createAnimal(farmerProfileId, body, photo) {
    const input = normalise(body);
    await assertEarTagFree(input.ear_tag);
    const photoPath = photo ? (0, fileHelper_1.storedPathFromUpload)('animals', photo) : null;
    const id = await repository.insert(farmerProfileId, input, photoPath);
    return getAnimal(id, { role: roles_1.ROLES.FARMER, farmerProfileId });
}
async function updateAnimal(id, farmerProfileId, body, photo) {
    const existing = await loadOwned(id, farmerProfileId);
    const input = normalise(body);
    await assertEarTagFree(input.ear_tag, id);
    const photoPath = photo ? (0, fileHelper_1.storedPathFromUpload)('animals', photo) : undefined;
    await repository.update(id, input, photoPath);
    if (photoPath && existing.photo_path) {
        await (0, fileHelper_1.deleteFile)(existing.photo_path);
    }
    return getAnimal(id, { role: roles_1.ROLES.FARMER, farmerProfileId });
}
/** Soft delete - the animal stays referenced by historical applications. */
async function deactivateAnimal(id, farmerProfileId) {
    const existing = await loadOwned(id, farmerProfileId);
    if (!existing.is_active) {
        throw new apiError_1.BadRequestError('Animal is already inactive');
    }
    if (Number(existing.active_application_count) > 0) {
        throw new apiError_1.BadRequestError('Cannot deactivate an animal with a pending application or an active policy');
    }
    await repository.setActive(id, false);
    return getAnimal(id, { role: roles_1.ROLES.FARMER, farmerProfileId });
}
