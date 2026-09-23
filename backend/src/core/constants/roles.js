"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ALL_ROLES = exports.ROLES = void 0;
exports.isRole = isRole;
exports.ROLES = {
    FARMER: 'FARMER',
    ADMIN: 'ADMIN',
};
exports.ALL_ROLES = [exports.ROLES.FARMER, exports.ROLES.ADMIN];
function isRole(value) {
    return typeof value === 'string' && exports.ALL_ROLES.includes(value);
}
