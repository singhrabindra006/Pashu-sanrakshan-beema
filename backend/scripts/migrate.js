"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Applies database/schema.sql. Safe to re-run: every statement uses
 * CREATE ... IF NOT EXISTS.
 *
 *   npm run db:migrate
 */
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const promise_1 = __importDefault(require("mysql2/promise"));
const config_1 = require("../src/config");
async function main() {
    const sqlPath = path_1.default.resolve(__dirname, '..', 'database', 'schema.sql');
    const sql = fs_1.default.readFileSync(sqlPath, 'utf-8');
    // No database is selected: schema.sql creates it.
    const connection = await promise_1.default.createConnection({
        host: config_1.config.db.host,
        port: config_1.config.db.port,
        user: config_1.config.db.user,
        password: config_1.config.db.password,
        multipleStatements: true,
    });
    try {
        await connection.query(sql);
        console.info(`[migrate] applied ${path_1.default.basename(sqlPath)} to ${config_1.config.db.host}:${config_1.config.db.port}`);
    }
    finally {
        await connection.end();
    }
}
main().catch((error) => {
    console.error('[migrate] failed', error);
    process.exit(1);
});
