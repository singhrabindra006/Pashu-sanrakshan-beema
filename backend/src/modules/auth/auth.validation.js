"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncValidation = void 0;
const express_validator_1 = require("express-validator");
exports.syncValidation = [
    (0, express_validator_1.body)('full_name')
        .exists({ checkFalsy: true })
        .withMessage('Full name is required')
        .bail()
        .isString()
        .trim()
        .isLength({ min: 3, max: 150 })
        .withMessage('Full name must be between 3 and 150 characters'),
    (0, express_validator_1.body)('email')
        .optional({ nullable: true })
        .isEmail()
        .withMessage('Email must be a valid address')
        .bail()
        .isLength({ max: 255 })
        .withMessage('Email must be at most 255 characters')
        .normalizeEmail({ gmail_remove_dots: false }),
];
