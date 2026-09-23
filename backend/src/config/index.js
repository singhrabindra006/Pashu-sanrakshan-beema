"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.config = void 0;
exports.requiredEnv = required;
const path_1 = __importDefault(require("path"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
function required(key) {
    const value = process.env[key];
    if (value === undefined || value.trim() === '') {
        throw new Error(`Missing required environment variable: ${key}`);
    }
    return value.trim();
}
function optional(key, fallback) {
    const value = process.env[key];
    return value === undefined || value.trim() === '' ? fallback : value.trim();
}
function number(key, fallback) {
    const raw = process.env[key];
    if (raw === undefined || raw.trim() === '')
        return fallback;
    const parsed = Number(raw);
    if (Number.isNaN(parsed)) {
        throw new Error(`Environment variable ${key} must be a number, received "${raw}"`);
    }
    return parsed;
}
const nodeEnv = optional('NODE_ENV', 'development');
const uploadRoot = path_1.default.resolve(process.cwd(), optional('UPLOAD_DIR', 'uploads'));
exports.config = {
    nodeEnv,
    isProduction: nodeEnv === 'production',
    port: number('PORT', 4000),
    /** Absolute URL clients use to reach this API. Used to build file URLs. */
    publicBaseUrl: optional('PUBLIC_BASE_URL', `http://localhost:${number('PORT', 4000)}`).replace(/\/$/, ''),
    apiPrefix: '/api/v1',
    cors: {
        /** Comma separated list, or "*" to allow everything (default for dev). */
        origins: optional('CORS_ORIGIN', '*')
            .split(',')
            .map((origin) => origin.trim())
            .filter(Boolean),
    },
    db: {
        host: optional('DB_HOST', '127.0.0.1'),
        port: number('DB_PORT', 3306),
        user: optional('DB_USER', 'root'),
        password: optional('DB_PASSWORD', ''),
        database: optional('DB_NAME', 'livestock_insurance'),
        connectionLimit: number('DB_CONNECTION_LIMIT', 10),
    },
    firebase: {
        /**
         * Either point FIREBASE_SERVICE_ACCOUNT_PATH at a downloaded service
         * account JSON file, or supply the three inline values.
         */
        serviceAccountPath: optional('FIREBASE_SERVICE_ACCOUNT_PATH', ''),
        projectId: optional('FIREBASE_PROJECT_ID', ''),
        clientEmail: optional('FIREBASE_CLIENT_EMAIL', ''),
        privateKey: optional('FIREBASE_PRIVATE_KEY', '').replace(/\\n/g, '\n'),
    },
    uploads: {
        root: uploadRoot,
        profiles: path_1.default.join(uploadRoot, 'profiles'),
        animals: path_1.default.join(uploadRoot, 'animals'),
        claims: path_1.default.join(uploadRoot, 'claims'),
        maxImageBytes: number('MAX_IMAGE_MB', 5) * 1024 * 1024,
        maxEvidenceBytes: number('MAX_EVIDENCE_MB', 10) * 1024 * 1024,
    },
    policy: {
        /** Default policy term applied when an admin approves without explicit dates. */
        defaultTermMonths: number('POLICY_TERM_MONTHS', 12),
    },
};
