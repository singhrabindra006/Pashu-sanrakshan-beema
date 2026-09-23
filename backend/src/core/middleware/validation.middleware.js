"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validate = validate;
exports.idParam = idParam;
const express_validator_1 = require("express-validator");
const apiError_1 = require("../utils/apiError");
/**
 * Runs the supplied express-validator chains and converts the result into a
 * single 422 with a flat `{ field, message }[]` the Flutter forms can bind to.
 */
function validate(chains) {
    const runners = chains;
    return [
        ...runners,
        (req, _res, next) => {
            const result = (0, express_validator_1.validationResult)(req);
            if (result.isEmpty()) {
                next();
                return;
            }
            const errors = result.array({ onlyFirstError: true }).map((error) => ({
                field: 'path' in error && typeof error.path === 'string' ? error.path : 'body',
                message: error.msg,
            }));
            next(new apiError_1.ValidationError(errors, errors[0]?.message ?? 'Validation failed'));
        },
    ];
}
/** Every `:id` route segment is a positive integer primary key. */
function idParam(name = 'id') {
    return (0, express_validator_1.param)(name).isInt({ min: 1 }).withMessage(`${name} must be a positive integer`).toInt();
}
