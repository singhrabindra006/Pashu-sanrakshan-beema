"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FILE_CATEGORIES = exports.DECISION_ACTIONS = exports.INCIDENT_TYPES = exports.ANIMAL_TYPES = exports.CLAIM_STATUSES = exports.CLAIM_STATUS = exports.APPLICATION_STATUSES = exports.APPLICATION_STATUS = void 0;
exports.APPLICATION_STATUS = {
    PENDING: 'PENDING',
    APPROVED: 'APPROVED',
    REJECTED: 'REJECTED',
};
exports.APPLICATION_STATUSES = Object.values(exports.APPLICATION_STATUS);
exports.CLAIM_STATUS = {
    SUBMITTED: 'SUBMITTED',
    APPROVED: 'APPROVED',
    REJECTED: 'REJECTED',
};
exports.CLAIM_STATUSES = Object.values(exports.CLAIM_STATUS);
exports.ANIMAL_TYPES = ['COW', 'BUFFALO', 'GOAT', 'SHEEP'];
exports.INCIDENT_TYPES = ['DEATH', 'DISEASE', 'ACCIDENT', 'THEFT', 'NATURAL_DISASTER', 'OTHER'];
exports.DECISION_ACTIONS = ['APPROVE', 'REJECT'];
/** Sub-directories under `uploads/`; doubles as the file route path segment. */
exports.FILE_CATEGORIES = ['profiles', 'animals', 'claims'];
