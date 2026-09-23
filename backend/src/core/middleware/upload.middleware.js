"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleUpload = handleUpload;
exports.requireFile = requireFile;
const multer_1 = require("multer");
const apiError_1 = require("../utils/apiError");
/**
 * Multer reports failures through its own error class. Wrapping the upload
 * handler keeps those out of the generic 500 branch.
 */
function handleUpload(uploader) {
    return (req, res, next) => {
        uploader(req, res, (error) => {
            if (!error) {
                next();
                return;
            }
            if (error instanceof multer_1.MulterError) {
                switch (error.code) {
                    case 'LIMIT_FILE_SIZE':
                        next(new apiError_1.PayloadTooLargeError('File is larger than the allowed limit'));
                        return;
                    case 'LIMIT_FILE_COUNT':
                    case 'LIMIT_UNEXPECTED_FILE':
                        next(new apiError_1.BadRequestError(`Unexpected upload field "${error.field}"`));
                        return;
                    default:
                        next(new apiError_1.BadRequestError(error.message));
                        return;
                }
            }
            next(error);
        });
    };
}
/** For endpoints where the file is mandatory. */
function requireFile(field) {
    return (req, _res, next) => {
        if (!req.file) {
            next(new apiError_1.BadRequestError(`"${field}" file is required`));
            return;
        }
        next();
    };
}
