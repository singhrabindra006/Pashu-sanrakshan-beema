"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.initialiseFirebase = initialiseFirebase;
exports.firebaseAuth = firebaseAuth;
const fs_1 = __importDefault(require("fs"));
const firebase_admin_1 = __importDefault(require("firebase-admin"));
const index_1 = require("./index");
let initialised = false;
function buildCredential() {
    if (index_1.config.firebase.serviceAccountPath) {
        if (!fs_1.default.existsSync(index_1.config.firebase.serviceAccountPath)) {
            throw new Error(`Firebase service account file not found: ${index_1.config.firebase.serviceAccountPath}`);
        }
        const raw = fs_1.default.readFileSync(index_1.config.firebase.serviceAccountPath, 'utf-8');
        return firebase_admin_1.default.credential.cert(JSON.parse(raw));
    }
    const { projectId, clientEmail, privateKey } = index_1.config.firebase;
    if (projectId && clientEmail && privateKey) {
        return firebase_admin_1.default.credential.cert({ projectId, clientEmail, privateKey });
    }
    // Falls back to GOOGLE_APPLICATION_CREDENTIALS / workload identity.
    return firebase_admin_1.default.credential.applicationDefault();
}
function initialiseFirebase() {
    if (!initialised) {
        firebase_admin_1.default.initializeApp({ credential: buildCredential() });
        initialised = true;
    }
    return firebase_admin_1.default.app();
}
function firebaseAuth() {
    initialiseFirebase();
    return firebase_admin_1.default.auth();
}
