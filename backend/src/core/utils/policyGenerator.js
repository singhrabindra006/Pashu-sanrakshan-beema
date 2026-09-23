"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.todayCompact = todayCompact;
exports.toDateOnly = toDateOnly;
exports.generateApplicationNumber = generateApplicationNumber;
exports.generateClaimNumber = generateClaimNumber;
exports.generatePolicyNumber = generatePolicyNumber;
exports.defaultPolicyWindow = defaultPolicyWindow;
exports.withUniqueNumberRetry = withUniqueNumberRetry;
const config_1 = require("../../config");
function pad(value, width) {
    return String(value).padStart(width, '0');
}
function todayCompact(date = new Date()) {
    return `${date.getFullYear()}${pad(date.getMonth() + 1, 2)}${pad(date.getDate(), 2)}`;
}
function toDateOnly(date) {
    return `${date.getFullYear()}-${pad(date.getMonth() + 1, 2)}-${pad(date.getDate(), 2)}`;
}
/** APP-20250115-001 */
function generateApplicationNumber(sequence, date = new Date()) {
    return `APP-${todayCompact(date)}-${pad(sequence, 3)}`;
}
/** CLM-20250115-001 */
function generateClaimNumber(sequence, date = new Date()) {
    return `CLM-${todayCompact(date)}-${pad(sequence, 3)}`;
}
/** POL-2025-00001 */
function generatePolicyNumber(sequence, date = new Date()) {
    return `POL-${date.getFullYear()}-${pad(sequence, 5)}`;
}
/** Fallback policy window used when the admin approves without supplying dates. */
function defaultPolicyWindow(from = new Date()) {
    const start = new Date(from.getFullYear(), from.getMonth(), from.getDate());
    const end = new Date(start);
    end.setMonth(end.getMonth() + config_1.config.policy.defaultTermMonths);
    end.setDate(end.getDate() - 1);
    return { start: toDateOnly(start), end: toDateOnly(end) };
}
const DUPLICATE_ENTRY = 'ER_DUP_ENTRY';
/**
 * Human readable identifiers are derived from a COUNT(*), so two concurrent
 * submissions can collide on the UNIQUE index. Retry with the next sequence
 * instead of failing the request.
 */
async function withUniqueNumberRetry(work, maxAttempts = 5) {
    let lastError;
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
        try {
            return await work(attempt);
        }
        catch (error) {
            const code = error.code;
            if (code !== DUPLICATE_ENTRY)
                throw error;
            lastError = error;
        }
    }
    throw lastError;
}
