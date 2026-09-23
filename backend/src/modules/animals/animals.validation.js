"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listAnimalsValidation = exports.animalIdValidation = exports.updateAnimalValidation = exports.createAnimalValidation = void 0;
const express_validator_1 = require("express-validator");
const status_1 = require("../../core/constants/status");
const validation_middleware_1 = require("../../core/middleware/validation.middleware");
const animalBody = [
    (0, express_validator_1.body)('ear_tag')
        .exists({ checkFalsy: true })
        .withMessage('Ear tag is required')
        .bail()
        .isString()
        .trim()
        .isLength({ min: 3, max: 50 })
        .withMessage('Ear tag must be between 3 and 50 characters')
        .matches(/^[A-Za-z0-9\-/]+$/)
        .withMessage('Ear tag may only contain letters, digits, - and /'),
    (0, express_validator_1.body)('animal_type')
        .exists({ checkFalsy: true })
        .withMessage('Animal type is required')
        .bail()
        .customSanitizer((value) => String(value).toUpperCase())
        .isIn(status_1.ANIMAL_TYPES)
        .withMessage(`Animal type must be one of: ${status_1.ANIMAL_TYPES.join(', ')}`),
    (0, express_validator_1.body)('breed').optional({ nullable: true, checkFalsy: true }).isString().trim().isLength({ max: 100 }),
    (0, express_validator_1.body)('age_months')
        .optional({ nullable: true, checkFalsy: true })
        .isInt({ min: 0, max: 600 })
        .withMessage('Age in months must be between 0 and 600')
        .toInt(),
];
exports.createAnimalValidation = animalBody;
exports.updateAnimalValidation = [(0, validation_middleware_1.idParam)(), ...animalBody];
exports.animalIdValidation = [(0, validation_middleware_1.idParam)()];
exports.listAnimalsValidation = [
    (0, express_validator_1.query)('is_active').optional().isIn(['true', 'false', '1', '0']).withMessage('is_active must be true or false'),
    (0, express_validator_1.query)('search').optional().isString().trim().isLength({ max: 100 }),
];
