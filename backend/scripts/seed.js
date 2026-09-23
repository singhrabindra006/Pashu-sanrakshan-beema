"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Loads demo schemes and (optionally) provisions the ADMIN account.
 *
 *   npm run db:seed
 *
 * Admins are never created through the API. Create the user in Firebase
 * Authentication first, then run:
 *
 *   ADMIN_FIREBASE_UID=<uid> ADMIN_EMAIL=<email> ADMIN_NAME="Full Name" npm run db:seed
 */
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const promise_1 = __importDefault(require("mysql2/promise"));
const config_1 = require("../src/config");
async function main() {
    const sqlPath = path_1.default.resolve(__dirname, '..', 'database', 'seed.sql');
    const connection = await promise_1.default.createConnection({
        host: config_1.config.db.host,
        port: config_1.config.db.port,
        user: config_1.config.db.user,
        password: config_1.config.db.password,
        database: config_1.config.db.database,
        multipleStatements: true,
    });
    try {
        const adminUid = process.env.ADMIN_FIREBASE_UID?.trim();
        if (adminUid) {
            const email = process.env.ADMIN_EMAIL?.trim() ?? 'admin@lims.local';
            const name = process.env.ADMIN_NAME?.trim() ?? 'System Administrator';
            await connection.query(`INSERT INTO users (firebase_uid, email, full_name, role)
         VALUES (?, ?, ?, 'ADMIN')
         ON DUPLICATE KEY UPDATE email = VALUES(email), full_name = VALUES(full_name), role = 'ADMIN', is_active = 1`, [adminUid, email, name]);
            console.info(`[seed] admin ready: ${email}`);
        }
        else {
            console.warn('[seed] ADMIN_FIREBASE_UID not set - skipping admin account');
        }
        // Only load demo schemes into an empty catalogue.
        const [rows] = await connection.query('SELECT COUNT(*) AS total FROM schemes');
        if (Number(rows[0]?.total ?? 0) > 0) {
            console.info('[seed] schemes already present - skipping demo data');
            return;
        }
        const sql = fs_1.default
            .readFileSync(sqlPath, 'utf-8')
            // The admin INSERT in seed.sql is handled above with real values.
            .replace(/INSERT INTO `users`[\s\S]*?;\n/, '');
        await connection.query(sql);
        console.info('[seed] demo schemes inserted');
    }
    finally {
        await connection.end();
    }
}
main().catch((error) => {
    console.error('[seed] failed', error);
    process.exit(1);
});
