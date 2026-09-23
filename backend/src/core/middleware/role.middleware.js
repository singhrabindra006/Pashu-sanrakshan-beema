"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.anyRole = exports.farmerOnly = exports.adminOnly = void 0;
exports.authorize = authorize;
const roles_1 = require("../constants/roles");
const apiError_1 = require("../utils/apiError");
/** authorize('ADMIN') / authorize('FARMER', 'ADMIN') */
function authorize(...allowed) {
    return (req, _res, next) => {
        const role = req.user?.role;
        if (!role) {
            next(new apiError_1.UnauthorizedError());
            return;
        }
        if (!allowed.includes(role)) {
            next(new apiError_1.ForbiddenError(`This endpoint is restricted to: ${allowed.join(', ')}`));
            return;
        }
        next();
    };
}
exports.adminOnly = authorize(roles_1.ROLES.ADMIN);
exports.farmerOnly = authorize(roles_1.ROLES.FARMER);
exports.anyRole = authorize(roles_1.ROLES.FARMER, roles_1.ROLES.ADMIN);
