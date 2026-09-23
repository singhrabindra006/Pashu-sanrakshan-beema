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
exports.decide = exports.detail = exports.listAll = exports.listClaimable = exports.listMine = exports.submit = void 0;
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const apiResponse_1 = require("../../core/utils/apiResponse");
const asyncHandler_1 = require("../../core/utils/asyncHandler");
const service = __importStar(require("./applications.service"));
function readStatus(value) {
    return value ? String(value).toUpperCase() : undefined;
}
/** POST /applications */
exports.submit = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const application = await service.submitApplication((0, auth_middleware_1.currentFarmerProfileId)(req), req.body);
    res.success(application, 'Application submitted', 201);
});
/** GET /applications?status=PENDING */
exports.listMine = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { page, limit, offset } = (0, apiResponse_1.readPagination)(req);
    const result = await service.listMyApplications((0, auth_middleware_1.currentFarmerProfileId)(req), readStatus(req.query.status), page, limit, offset);
    res.success(result, 'Applications loaded');
});
/** GET /applications/claimable - approved policies for the claim form dropdown. */
exports.listClaimable = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const items = await service.listClaimableApplications((0, auth_middleware_1.currentFarmerProfileId)(req));
    res.success(items, 'Approved applications loaded');
});
/** GET /admin/applications?status=PENDING&page=1&search= */
exports.listAll = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { page, limit, offset } = (0, apiResponse_1.readPagination)(req);
    const result = await service.listAllApplications({
        status: readStatus(req.query.status),
        search: req.query.search ? String(req.query.search) : undefined,
    }, page, limit, offset);
    res.success(result, 'Applications loaded');
});
/** GET /applications/:id (farmer owner) and GET /admin/applications/:id (admin). */
exports.detail = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const user = (0, auth_middleware_1.currentUser)(req);
    const application = await service.getApplication(Number(req.params.id), {
        role: user.role,
        farmerProfileId: user.farmerProfileId,
    });
    res.success(application, 'Application loaded');
});
/** PATCH /admin/applications/:id/decide */
exports.decide = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { mysqlId } = (0, auth_middleware_1.currentUser)(req);
    const application = await service.decideApplication(Number(req.params.id), mysqlId, {
        action: String(req.body.action).toUpperCase(),
        policy_number: req.body.policy_number,
        start_date: req.body.start_date,
        end_date: req.body.end_date,
        reason: req.body.reason,
    });
    res.success(application, application.status === 'APPROVED' ? 'Application approved' : 'Application rejected');
});
