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
const express_1 = require("express");
const multer_1 = require("../../config/multer");
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const role_middleware_1 = require("../../core/middleware/role.middleware");
const upload_middleware_1 = require("../../core/middleware/upload.middleware");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
const adminController = __importStar(require("../admin/admin.controller"));
const controller = __importStar(require("./profile.controller"));
const profile_validation_1 = require("./profile.validation");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authenticate, role_middleware_1.farmerOnly);
// 4. My profile.
router.get('/me', controller.getMine);
// Stat cards on FarmerHomePage.
router.get('/me/dashboard', adminController.farmerDashboard);
// 5. Update phone only.
router.patch('/me', (0, validation_middleware_1.validate)(profile_validation_1.updatePhoneValidation), controller.updateMine);
// 6. Avatar upload (JPG/PNG, max 5 MB).
router.post('/me/photo', (0, upload_middleware_1.handleUpload)(multer_1.uploadProfilePhoto), controller.uploadPhoto);
exports.default = router;
