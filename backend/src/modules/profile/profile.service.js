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
exports.getMyProfile = getMyProfile;
exports.updateMyPhone = updateMyPhone;
exports.replaceMyPhoto = replaceMyPhoto;
const apiError_1 = require("../../core/utils/apiError");
const fileHelper_1 = require("../../core/utils/fileHelper");
const repository = __importStar(require("./profile.repository"));
function map(row) {
    return {
        id: row.id,
        user_id: row.user_id,
        full_name: row.full_name,
        email: row.email,
        phone: row.phone,
        profile_image_path: row.profile_image_path,
        image_url: (0, fileHelper_1.toPublicUrl)(row.profile_image_path),
        created_at: row.created_at,
    };
}
async function load(profileId) {
    const row = await repository.findByProfileId(profileId);
    if (!row)
        throw new apiError_1.NotFoundError('Farmer profile not found');
    return row;
}
async function getMyProfile(profileId) {
    return map(await load(profileId));
}
/** Phone is the only field a farmer may edit; name and email are owned by Firebase. */
async function updateMyPhone(profileId, phone) {
    await load(profileId);
    await repository.updatePhone(profileId, phone);
    return map(await load(profileId));
}
/** Replaces the avatar and removes the previous file from disk. */
async function replaceMyPhoto(profileId, file) {
    const existing = await load(profileId);
    const storedPath = (0, fileHelper_1.storedPathFromUpload)('profiles', file);
    await repository.updateImagePath(profileId, storedPath);
    if (existing.profile_image_path && existing.profile_image_path !== storedPath) {
        await (0, fileHelper_1.deleteFile)(existing.profile_image_path);
    }
    return map(await load(profileId));
}
