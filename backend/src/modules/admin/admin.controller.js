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
exports.farmerDashboard = exports.toggleFarmer = exports.farmerDetail = exports.listFarmers = exports.dashboard = void 0;
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const apiResponse_1 = require("../../core/utils/apiResponse");
const asyncHandler_1 = require("../../core/utils/asyncHandler");
const service = __importStar(require("./admin.service"));
function readBooleanQuery(value) {
    if (value === undefined || value === '')
        return undefined;
    return value === 'true' || value === '1';
}
/** GET /admin/dashboard - stat cards + recent activity. */
exports.dashboard = (0, asyncHandler_1.asyncHandler)(async (_req, res) => {
    const data = await service.getAdminDashboard();
    res.success(data, 'Dashboard loaded');
});
/** GET /admin/farmers?search=&is_active= */
exports.listFarmers = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { page, limit, offset } = (0, apiResponse_1.readPagination)(req);
    const result = await service.listFarmers({
        search: req.query.search ? String(req.query.search) : undefined,
        isActive: readBooleanQuery(req.query.is_active),
    }, page, limit, offset);
    res.success(result, 'Farmers loaded');
});
/** GET /admin/farmers/:id - farmer + animals + applications + claims. */
exports.farmerDetail = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const data = await service.getFarmerDetail(Number(req.params.id));
    res.success(data, 'Farmer loaded');
});
/** PATCH /admin/farmers/:id/toggle - block / unblock access. */
exports.toggleFarmer = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const farmer = await service.toggleFarmerActive(Number(req.params.id));
    res.success(farmer, farmer.is_active ? 'Farmer activated' : 'Farmer deactivated');
});
/** GET /profile/me/dashboard - farmer home stats. */
exports.farmerDashboard = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const data = await service.getFarmerDashboard((0, auth_middleware_1.currentFarmerProfileId)(req));
    res.success(data, 'Dashboard loaded');
});
