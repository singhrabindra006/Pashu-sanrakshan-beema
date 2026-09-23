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
exports.listAvailableSchemes = listAvailableSchemes;
exports.listAllSchemes = listAllSchemes;
exports.getScheme = getScheme;
exports.createScheme = createScheme;
exports.updateScheme = updateScheme;
exports.toggleScheme = toggleScheme;
exports.mapScheme = map;
const apiResponse_1 = require("../../core/utils/apiResponse");
const apiError_1 = require("../../core/utils/apiError");
const repository = __importStar(require("./schemes.repository"));
function map(row) {
    return {
        id: row.id,
        name: row.name,
        description: row.description,
        max_coverage: Number(row.max_coverage),
        start_date: row.start_date,
        end_date: row.end_date,
        is_active: Boolean(row.is_active),
        is_available: Boolean(row.is_available),
        created_at: row.created_at,
    };
}
async function listAvailableSchemes(page, limit, offset) {
    const [rows, total] = await Promise.all([repository.listAvailable(limit, offset), repository.countAvailable()]);
    return (0, apiResponse_1.paginate)(rows.map(map), total, page, limit);
}
async function listAllSchemes(isActive, page, limit, offset) {
    const [rows, total] = await Promise.all([repository.listAll(isActive, limit, offset), repository.countAll(isActive)]);
    return (0, apiResponse_1.paginate)(rows.map(map), total, page, limit);
}
async function getScheme(id) {
    const row = await repository.findById(id);
    if (!row)
        throw new apiError_1.NotFoundError('Scheme not found');
    return map(row);
}
function normalise(body) {
    const input = {
        name: String(body.name).trim(),
        description: body.description === undefined || body.description === null ? null : String(body.description).trim(),
        max_coverage: Number(body.max_coverage),
        start_date: String(body.start_date).slice(0, 10),
        end_date: String(body.end_date).slice(0, 10),
    };
    if (input.end_date < input.start_date) {
        throw new apiError_1.BadRequestError('End date must be on or after the start date');
    }
    return input;
}
async function createScheme(body) {
    const id = await repository.insert(normalise(body));
    return getScheme(id);
}
async function updateScheme(id, body) {
    await getScheme(id);
    await repository.update(id, normalise(body));
    return getScheme(id);
}
async function toggleScheme(id) {
    const scheme = await getScheme(id);
    await repository.setActive(id, !scheme.is_active);
    return getScheme(id);
}
