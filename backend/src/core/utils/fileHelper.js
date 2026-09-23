"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.toStoredPath = toStoredPath;
exports.storedPathFromUpload = storedPathFromUpload;
exports.parseStoredPath = parseStoredPath;
exports.resolveAbsolutePath = resolveAbsolutePath;
exports.absolutePathFromStored = absolutePathFromStored;
exports.toPublicUrl = toPublicUrl;
exports.getMimeType = getMimeType;
exports.fileExists = fileExists;
exports.deleteFile = deleteFile;
exports.deleteUploadedFile = deleteUploadedFile;
const promises_1 = __importDefault(require("fs/promises"));
const path_1 = __importDefault(require("path"));
const config_1 = require("../../config");
const status_1 = require("../constants/status");
const apiError_1 = require("./apiError");
const MIME_BY_EXTENSION = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.pdf': 'application/pdf',
};
/** Relative, DB-storable path: `uploads/animals/xyz.jpg` (always forward slashes). */
function toStoredPath(category, fileName) {
    return `uploads/${category}/${path_1.default.basename(fileName)}`;
}
/** Turns an uploaded multer file into the path persisted in MySQL. */
function storedPathFromUpload(category, file) {
    return toStoredPath(category, file.filename);
}
function parseStoredPath(storedPath) {
    const segments = storedPath.replace(/\\/g, '/').split('/').filter(Boolean);
    const fileName = segments[segments.length - 1];
    const category = segments[segments.length - 2];
    if (!fileName || !status_1.FILE_CATEGORIES.includes(category)) {
        throw new apiError_1.BadRequestError(`Malformed file path: ${storedPath}`);
    }
    return { category, fileName };
}
/**
 * Resolves to an absolute path inside the upload root, rejecting any traversal
 * attempt (`../`, absolute paths, nested directories).
 */
function resolveAbsolutePath(category, fileName) {
    if (!status_1.FILE_CATEGORIES.includes(category)) {
        throw new apiError_1.BadRequestError(`Unknown file category: ${category}`);
    }
    const safeName = path_1.default.basename(fileName);
    if (safeName !== fileName || safeName.startsWith('.')) {
        throw new apiError_1.BadRequestError('Invalid file name');
    }
    const absolute = path_1.default.resolve(config_1.config.uploads.root, category, safeName);
    const categoryRoot = path_1.default.resolve(config_1.config.uploads.root, category);
    if (!absolute.startsWith(categoryRoot + path_1.default.sep)) {
        throw new apiError_1.BadRequestError('Invalid file path');
    }
    return absolute;
}
function absolutePathFromStored(storedPath) {
    const { category, fileName } = parseStoredPath(storedPath);
    return resolveAbsolutePath(category, fileName);
}
/** Authenticated download URL handed to the Flutter client.
 *  Relative so a phone on USB (`127.0.0.1`) and an emulator (`10.0.2.2`)
 *  can both prefix their own API origin. */
function toPublicUrl(storedPath) {
    if (!storedPath)
        return null;
    const { category, fileName } = parseStoredPath(storedPath);
    return `${config_1.config.apiPrefix}/files/${category}/${fileName}`;
}
function getMimeType(fileName) {
    return MIME_BY_EXTENSION[path_1.default.extname(fileName).toLowerCase()] ?? 'application/octet-stream';
}
async function fileExists(absolutePath) {
    try {
        await promises_1.default.access(absolutePath);
        return true;
    }
    catch {
        return false;
    }
}
/** Best-effort removal; a missing file is never an error (e.g. replaced photo). */
async function deleteFile(storedPath) {
    if (!storedPath)
        return;
    try {
        await promises_1.default.unlink(absolutePathFromStored(storedPath));
    }
    catch {
        // Nothing to clean up.
    }
}
async function deleteUploadedFile(file) {
    if (!file)
        return;
    try {
        await promises_1.default.unlink(file.path);
    }
    catch {
        // Nothing to clean up.
    }
}
