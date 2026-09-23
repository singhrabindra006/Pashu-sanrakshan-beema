"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updatePhoneValidation = void 0;
const express_validator_1 = require("express-validator");
exports.updatePhoneValidation = [
    (0, express_validator_1.body)('phone')
        .exists({ checkNull: true })
        .withMessage('Phone number is required')
        .bail()
        .isString()
        .trim()
        .matches(/^[0-9+\-\s()]{7,20}$/)
        .withMessage('Phone number must be 7-20 characters and contain digits only'),
];
