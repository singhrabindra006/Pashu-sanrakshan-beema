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
exports.adminClaimRouter = exports.claimRouter = void 0;
const express_1 = require("express");
const multer_1 = require("../../config/multer");
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const role_middleware_1 = require("../../core/middleware/role.middleware");
const upload_middleware_1 = require("../../core/middleware/upload.middleware");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
const controller = __importStar(require("./claims.controller"));
const claims_validation_1 = require("./claims.validation");
/** Mounted at /claims */
exports.claimRouter = (0, express_1.Router)();
exports.claimRouter.use(auth_middleware_1.authenticate, role_middleware_1.farmerOnly);
// 21. Submit claim (multipart).
exports.claimRouter.post('/', (0, upload_middleware_1.handleUpload)(multer_1.uploadClaimEvidence), (0, validation_middleware_1.validate)(claims_validation_1.submitClaimValidation), controller.submit);
// 22. My claims.
exports.claimRouter.get('/', (0, validation_middleware_1.validate)(claims_validation_1.listClaimsValidation), controller.listMine);
// Detail view for ClaimDetailPage.
exports.claimRouter.get('/:id', (0, validation_middleware_1.validate)(claims_validation_1.claimIdValidation), controller.detail);
/** Mounted at /admin/claims */
exports.adminClaimRouter = (0, express_1.Router)();
exports.adminClaimRouter.use(auth_middleware_1.authenticate, role_middleware_1.adminOnly);
// 23. All claims.
exports.adminClaimRouter.get('/', (0, validation_middleware_1.validate)(claims_validation_1.listClaimsValidation), controller.listAll);
// Detail view for AdminClaimDetailPage.
exports.adminClaimRouter.get('/:id', (0, validation_middleware_1.validate)(claims_validation_1.claimIdValidation), controller.detail);
// 24. Approve / reject.
exports.adminClaimRouter.patch('/:id/decide', (0, validation_middleware_1.validate)(claims_validation_1.decideClaimValidation), controller.decide);
exports.default = exports.claimRouter;
