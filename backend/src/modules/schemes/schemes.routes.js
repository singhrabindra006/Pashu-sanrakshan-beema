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
exports.adminSchemeRouter = exports.schemeRouter = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const role_middleware_1 = require("../../core/middleware/role.middleware");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
const controller = __importStar(require("./schemes.controller"));
const schemes_validation_1 = require("./schemes.validation");
/** Mounted at /schemes */
exports.schemeRouter = (0, express_1.Router)();
exports.schemeRouter.use(auth_middleware_1.authenticate);
// 7. Active schemes (farmer catalogue).
exports.schemeRouter.get('/', role_middleware_1.farmerOnly, controller.listAvailable);
// 8. Scheme detail.
exports.schemeRouter.get('/:id', role_middleware_1.anyRole, (0, validation_middleware_1.validate)(schemes_validation_1.schemeIdValidation), controller.detail);
/** Mounted at /admin/schemes */
exports.adminSchemeRouter = (0, express_1.Router)();
exports.adminSchemeRouter.use(auth_middleware_1.authenticate, role_middleware_1.adminOnly);
// Admin catalogue including inactive/expired schemes (Active | Inactive tabs).
exports.adminSchemeRouter.get('/', (0, validation_middleware_1.validate)(schemes_validation_1.adminListSchemesValidation), controller.listAll);
// 9. Create scheme.
exports.adminSchemeRouter.post('/', (0, validation_middleware_1.validate)(schemes_validation_1.createSchemeValidation), controller.create);
// 10. Update scheme.
exports.adminSchemeRouter.put('/:id', (0, validation_middleware_1.validate)(schemes_validation_1.updateSchemeValidation), controller.update);
// 11. Toggle is_active.
exports.adminSchemeRouter.patch('/:id/toggle', (0, validation_middleware_1.validate)(schemes_validation_1.schemeIdValidation), controller.toggle);
exports.default = exports.schemeRouter;
