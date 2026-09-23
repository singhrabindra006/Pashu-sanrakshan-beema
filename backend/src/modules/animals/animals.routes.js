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
const controller = __importStar(require("./animals.controller"));
const animals_validation_1 = require("./animals.validation");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authenticate);
// 12. Add animal (multipart).
router.post('/', role_middleware_1.farmerOnly, (0, upload_middleware_1.handleUpload)(multer_1.uploadAnimalPhoto), (0, validation_middleware_1.validate)(animals_validation_1.createAnimalValidation), controller.create);
// 13. My animals.
router.get('/', role_middleware_1.farmerOnly, (0, validation_middleware_1.validate)(animals_validation_1.listAnimalsValidation), controller.listMine);
// 14. Animal detail (owner or admin).
router.get('/:id', role_middleware_1.anyRole, (0, validation_middleware_1.validate)(animals_validation_1.animalIdValidation), controller.detail);
// 15. Update animal (multipart, photo optional).
router.put('/:id', role_middleware_1.farmerOnly, (0, upload_middleware_1.handleUpload)(multer_1.uploadAnimalPhoto), (0, validation_middleware_1.validate)(animals_validation_1.updateAnimalValidation), controller.update);
// 16. Soft delete.
router.delete('/:id', role_middleware_1.farmerOnly, (0, validation_middleware_1.validate)(animals_validation_1.animalIdValidation), controller.deactivate);
exports.default = router;
