"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.EVIDENCE_MIME_TYPES = exports.IMAGE_MIME_TYPES = exports.uploadClaimEvidence = exports.uploadAnimalPhoto = exports.uploadProfilePhoto = void 0;
exports.ensureUploadDirectories = ensureUploadDirectories;
const crypto_1 = __importDefault(require("crypto"));
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const multer_1 = __importDefault(require("multer"));
const index_1 = require("./index");
const apiError_1 = require("../core/utils/apiError");
const IMAGE_MIME_TYPES = ['image/jpeg', 'image/jpg', 'image/pjpeg', 'image/png', 'image/x-png'];
exports.IMAGE_MIME_TYPES = IMAGE_MIME_TYPES;
const EVIDENCE_MIME_TYPES = [...IMAGE_MIME_TYPES, 'application/pdf'];
exports.EVIDENCE_MIME_TYPES = EVIDENCE_MIME_TYPES;
function ensureUploadDirectories() {
    for (const dir of [index_1.config.uploads.profiles, index_1.config.uploads.animals, index_1.config.uploads.claims]) {
        fs_1.default.mkdirSync(dir, { recursive: true });
    }
}
function randomFileName(originalName) {
    const extension = path_1.default.extname(originalName).toLowerCase() || '.bin';
    return `${Date.now()}-${crypto_1.default.randomBytes(8).toString('hex')}${extension}`;
}
function diskStorage(destination) {
    return multer_1.default.diskStorage({
        destination: (_req, _file, cb) => {
            fs_1.default.mkdirSync(destination, { recursive: true });
            cb(null, destination);
        },
        filename: (_req, file, cb) => cb(null, randomFileName(file.originalname)),
    });
}
function mimeFilter(allowed) {
    return (_req, file, cb) => {
        if (allowed.includes(file.mimetype)) {
            cb(null, true);
            return;
        }
        cb(new apiError_1.BadRequestError(`Unsupported file type "${file.mimetype}". Allowed: ${allowed.join(', ')}`));
    };
}
/** Profile avatar: single JPG/PNG up to MAX_IMAGE_MB. */
exports.uploadProfilePhoto = (0, multer_1.default)({
    storage: diskStorage(index_1.config.uploads.profiles),
    limits: { fileSize: index_1.config.uploads.maxImageBytes, files: 1 },
    fileFilter: mimeFilter(IMAGE_MIME_TYPES),
}).single('photo');
/** Animal identification photo: single JPG/PNG up to MAX_IMAGE_MB. */
exports.uploadAnimalPhoto = (0, multer_1.default)({
    storage: diskStorage(index_1.config.uploads.animals),
    limits: { fileSize: index_1.config.uploads.maxImageBytes, files: 1 },
    fileFilter: mimeFilter(IMAGE_MIME_TYPES),
}).single('photo');
/** Claim evidence: single JPG/PNG/PDF up to MAX_EVIDENCE_MB. */
exports.uploadClaimEvidence = (0, multer_1.default)({
    storage: diskStorage(index_1.config.uploads.claims),
    limits: { fileSize: index_1.config.uploads.maxEvidenceBytes, files: 1 },
    fileFilter: mimeFilter(EVIDENCE_MIME_TYPES),
}).single('evidence');
