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
exports.deactivate = exports.update = exports.detail = exports.listMine = exports.create = void 0;
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const apiResponse_1 = require("../../core/utils/apiResponse");
const asyncHandler_1 = require("../../core/utils/asyncHandler");
const service = __importStar(require("./animals.service"));
function readBooleanQuery(value) {
    if (value === undefined || value === '')
        return undefined;
    return value === 'true' || value === '1';
}
/** POST /animals - multipart, optional "photo" field. */
exports.create = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const animal = await service.createAnimal((0, auth_middleware_1.currentFarmerProfileId)(req), req.body, req.file);
    res.success(animal, 'Animal registered', 201);
});
/** GET /animals - my animals, paginated. */
exports.listMine = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { page, limit, offset } = (0, apiResponse_1.readPagination)(req);
    const result = await service.listMyAnimals((0, auth_middleware_1.currentFarmerProfileId)(req), {
        isActive: readBooleanQuery(req.query.is_active),
        search: req.query.search ? String(req.query.search) : undefined,
    }, page, limit, offset);
    res.success(result, 'Animals loaded');
});
/** GET /animals/:id - owner or any admin. */
exports.detail = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const user = (0, auth_middleware_1.currentUser)(req);
    const animal = await service.getAnimal(Number(req.params.id), {
        role: user.role,
        farmerProfileId: user.farmerProfileId,
    });
    res.success(animal, 'Animal loaded');
});
/** PUT /animals/:id - multipart; a new "photo" replaces the old file. */
exports.update = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const animal = await service.updateAnimal(Number(req.params.id), (0, auth_middleware_1.currentFarmerProfileId)(req), req.body, req.file);
    res.success(animal, 'Animal updated');
});
/** DELETE /animals/:id - soft delete. */
exports.deactivate = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const animal = await service.deactivateAnimal(Number(req.params.id), (0, auth_middleware_1.currentFarmerProfileId)(req));
    res.success(animal, 'Animal deactivated');
});
