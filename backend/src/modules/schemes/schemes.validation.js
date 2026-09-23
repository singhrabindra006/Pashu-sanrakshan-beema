"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminListSchemesValidation = exports.schemeIdValidation = exports.updateSchemeValidation = exports.createSchemeValidation = void 0;
const express_validator_1 = require("express-validator");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
const schemeBody = [
    (0, express_validator_1.body)('name')
        .exists({ checkFalsy: true })
        .withMessage('Scheme name is required')
        .bail()
        .isString()
        .trim()
        .isLength({ min: 3, max: 150 })
        .withMessage('Scheme name must be between 3 and 150 characters'),
    (0, express_validator_1.body)('description').optional({ nullable: true }).isString().trim().isLength({ max: 5000 }),
    (0, express_validator_1.body)('max_coverage')
        .exists({ checkNull: true })
        .withMessage('Maximum coverage is required')
        .bail()
        .isFloat({ gt: 0, max: 9999999999 })
        .withMessage('Maximum coverage must be greater than 0')
        .toFloat(),
    (0, express_validator_1.body)('start_date').isISO8601().withMessage('Start date must be in YYYY-MM-DD format'),
    (0, express_validator_1.body)('end_date').isISO8601().withMessage('End date must be in YYYY-MM-DD format'),
];
exports.createSchemeValidation = schemeBody;
exports.updateSchemeValidation = [(0, validation_middleware_1.idParam)(), ...schemeBody];
exports.schemeIdValidation = [(0, validation_middleware_1.idParam)()];
exports.adminListSchemesValidation = [
    (0, express_validator_1.query)('is_active').optional().isIn(['true', 'false', '1', '0']).withMessage('is_active must be true or false'),
];
