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
exports.adminApplicationRouter = exports.applicationRouter = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const role_middleware_1 = require("../../core/middleware/role.middleware");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
const controller = __importStar(require("./applications.controller"));
const applications_validation_1 = require("./applications.validation");
/** Mounted at /applications */
exports.applicationRouter = (0, express_1.Router)();
exports.applicationRouter.use(auth_middleware_1.authenticate, role_middleware_1.farmerOnly);
// 17. Submit application.
exports.applicationRouter.post('/', (0, validation_middleware_1.validate)(applications_validation_1.submitApplicationValidation), controller.submit);
// 18. My applications.
exports.applicationRouter.get('/', (0, validation_middleware_1.validate)(applications_validation_1.listApplicationsValidation), controller.listMine);
// Approved policies used to populate the claim submission dropdown.
exports.applicationRouter.get('/claimable', controller.listClaimable);
// Detail view for ApplicationDetailPage.
exports.applicationRouter.get('/:id', (0, validation_middleware_1.validate)(applications_validation_1.applicationIdValidation), controller.detail);
/** Mounted at /admin/applications */
exports.adminApplicationRouter = (0, express_1.Router)();
exports.adminApplicationRouter.use(auth_middleware_1.authenticate, role_middleware_1.adminOnly);
// 19. All applications.
exports.adminApplicationRouter.get('/', (0, validation_middleware_1.validate)(applications_validation_1.listApplicationsValidation), controller.listAll);
// Detail view for AdminApplicationDetailPage.
exports.adminApplicationRouter.get('/:id', (0, validation_middleware_1.validate)(applications_validation_1.applicationIdValidation), controller.detail);
// 20. Approve / reject.
exports.adminApplicationRouter.patch('/:id/decide', (0, validation_middleware_1.validate)(applications_validation_1.decideApplicationValidation), controller.decide);
exports.default = exports.applicationRouter;
