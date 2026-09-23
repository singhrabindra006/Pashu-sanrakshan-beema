"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.decideClaimValidation = exports.claimIdValidation = exports.listClaimsValidation = exports.submitClaimValidation = void 0;
const express_validator_1 = require("express-validator");
const status_1 = require("../../core/constants/status");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
exports.submitClaimValidation = [
    (0, express_validator_1.body)('application_id').isInt({ min: 1 }).withMessage('Select an approved application').toInt(),
    (0, express_validator_1.body)('incident_type')
        .exists({ checkFalsy: true })
        .withMessage('Incident type is required')
        .bail()
        .customSanitizer((value) => String(value).toUpperCase())
        .isIn(status_1.INCIDENT_TYPES)
        .withMessage(`Incident type must be one of: ${status_1.INCIDENT_TYPES.join(', ')}`),
    (0, express_validator_1.body)('incident_date').isISO8601().withMessage('Incident date must be YYYY-MM-DD'),
    (0, express_validator_1.body)('description')
        .exists({ checkFalsy: true })
        .withMessage('Description is required')
        .bail()
        .isString()
        .trim()
        .isLength({ min: 10, max: 5000 })
        .withMessage('Description must be between 10 and 5000 characters'),
    (0, express_validator_1.body)('claimed_amount')
        .isFloat({ gt: 0, max: 9999999999 })
        .withMessage('Claimed amount must be greater than 0')
        .toFloat(),
];
exports.listClaimsValidation = [
    (0, express_validator_1.query)('status').optional().isIn(status_1.CLAIM_STATUSES).withMessage(`status must be one of: ${status_1.CLAIM_STATUSES.join(', ')}`),
    (0, express_validator_1.query)('search').optional().isString().trim().isLength({ max: 100 }),
];
exports.claimIdValidation = [(0, validation_middleware_1.idParam)()];
exports.decideClaimValidation = [
    (0, validation_middleware_1.idParam)(),
    (0, express_validator_1.body)('action')
        .exists({ checkFalsy: true })
        .withMessage('action is required')
        .bail()
        .customSanitizer((value) => String(value).toUpperCase())
        .isIn(status_1.DECISION_ACTIONS)
        .withMessage('action must be APPROVE or REJECT'),
    (0, express_validator_1.body)('approved_amount')
        .if((0, express_validator_1.body)('action').custom((value) => String(value).toUpperCase() === 'APPROVE'))
        .isFloat({ gt: 0, max: 9999999999 })
        .withMessage('Approved amount must be greater than 0')
        .toFloat(),
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
