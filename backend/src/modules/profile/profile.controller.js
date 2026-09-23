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
exports.uploadPhoto = exports.updateMine = exports.getMine = void 0;
const auth_middleware_1 = require("../../core/middleware/auth.middleware");
const apiError_1 = require("../../core/utils/apiError");
const asyncHandler_1 = require("../../core/utils/asyncHandler");
const service = __importStar(require("./profile.service"));
/** GET /profile/me */
exports.getMine = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const profile = await service.getMyProfile((0, auth_middleware_1.currentFarmerProfileId)(req));
    res.success(profile, 'Profile loaded');
});
/** PATCH /profile/me - phone only. */
exports.updateMine = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const profile = await service.updateMyPhone((0, auth_middleware_1.currentFarmerProfileId)(req), String(req.body.phone).trim());
    res.success(profile, 'Phone number updated');
});
/** POST /profile/me/photo - multipart field "photo". */
exports.uploadPhoto = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.file)
        throw new apiError_1.BadRequestError('"photo" file is required');
    const profile = await service.replaceMyPhoto((0, auth_middleware_1.currentFarmerProfileId)(req), req.file);
    res.success(profile, 'Profile photo updated');
});
