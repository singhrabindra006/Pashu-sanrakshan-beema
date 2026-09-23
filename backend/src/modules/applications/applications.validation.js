"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.decideApplicationValidation = exports.applicationIdValidation = exports.listApplicationsValidation = exports.submitApplicationValidation = void 0;
const express_validator_1 = require("express-validator");
const status_1 = require("../../core/constants/status");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
exports.submitApplicationValidation = [
    (0, express_validator_1.body)('animal_id').isInt({ min: 1 }).withMessage('Select an animal').toInt(),
    (0, express_validator_1.body)('scheme_id').isInt({ min: 1 }).withMessage('Select a scheme').toInt(),
    (0, express_validator_1.body)('coverage_amount')
        .isFloat({ gt: 0, max: 9999999999 })
        .withMessage('Coverage amount must be greater than 0')
        .toFloat(),
];
exports.listApplicationsValidation = [
    (0, express_validator_1.query)('status').optional().isIn(status_1.APPLICATION_STATUSES).withMessage(`status must be one of: ${status_1.APPLICATION_STATUSES.join(', ')}`),
    (0, express_validator_1.query)('search').optional().isString().trim().isLength({ max: 100 }),
];
exports.applicationIdValidation = [(0, validation_middleware_1.idParam)()];
exports.decideApplicationValidation = [
    (0, validation_middleware_1.idParam)(),
    (0, express_validator_1.body)('action')
        .exists({ checkFalsy: true })
        .withMessage('action is required')
        .bail()
        .customSanitizer((value) => String(value).toUpperCase())
        .isIn(status_1.DECISION_ACTIONS)
        .withMessage('action must be APPROVE or REJECT'),
    (0, express_validator_1.body)('policy_number').optional({ nullable: true, checkFalsy: true }).isString().trim().isLength({ max: 50 }),
    (0, express_validator_1.body)('start_date').optional({ nullable: true, checkFalsy: true }).isISO8601().withMessage('start_date must be YYYY-MM-DD'),
    (0, express_validator_1.body)('end_date').optional({ nullable: true, checkFalsy: true }).isISO8601().withMessage('end_date must be YYYY-MM-DD'),
    (0, express_validator_1.body)('reason')
        .if((0, express_validator_1.body)('action').custom((value) => String(value).toUpperCase() === 'REJECT'))
        .exists({ checkFalsy: true })
        .withMessage('A rejection reason is required')
        .bail()
        .isString()
        .trim()
        .isLength({ min: 5, max: 2000 })
        .withMessage('Rejection reason must be between 5 and 2000 characters'),
];
