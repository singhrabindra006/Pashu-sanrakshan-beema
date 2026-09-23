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
exports.toggle = exports.update = exports.create = exports.detail = exports.listAll = exports.listAvailable = void 0;
const apiResponse_1 = require("../../core/utils/apiResponse");
const asyncHandler_1 = require("../../core/utils/asyncHandler");
const service = __importStar(require("./schemes.service"));
function readBooleanQuery(value) {
    if (value === undefined || value === '')
        return undefined;
    return value === 'true' || value === '1';
}
/** GET /schemes - active schemes inside their validity window. */
exports.listAvailable = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { page, limit, offset } = (0, apiResponse_1.readPagination)(req);
    const result = await service.listAvailableSchemes(page, limit, offset);
    res.success(result, 'Schemes loaded');
});
/** GET /admin/schemes - all schemes, filterable by the Active/Inactive tab. */
exports.listAll = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { page, limit, offset } = (0, apiResponse_1.readPagination)(req);
    const result = await service.listAllSchemes(readBooleanQuery(req.query.is_active), page, limit, offset);
    res.success(result, 'Schemes loaded');
});
/** GET /schemes/:id */
exports.detail = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const scheme = await service.getScheme(Number(req.params.id));
    res.success(scheme, 'Scheme loaded');
});
/** POST /admin/schemes */
exports.create = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const scheme = await service.createScheme(req.body);
    res.success(scheme, 'Scheme created', 201);
});
/** PUT /admin/schemes/:id */
exports.update = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const scheme = await service.updateScheme(Number(req.params.id), req.body);
    res.success(scheme, 'Scheme updated');
});
/** PATCH /admin/schemes/:id/toggle */
exports.toggle = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const scheme = await service.toggleScheme(Number(req.params.id));
    res.success(scheme, scheme.is_active ? 'Scheme activated' : 'Scheme deactivated');
});
