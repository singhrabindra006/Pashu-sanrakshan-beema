"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPool = getPool;
exports.assertDatabaseConnection = assertDatabaseConnection;
exports.closePool = closePool;
exports.query = query;
exports.queryOne = queryOne;
exports.execute = execute;
exports.withTransaction = withTransaction;
const promise_1 = __importDefault(require("mysql2/promise"));
const index_1 = require("./index");
let pool = null;
function getPool() {
    if (!pool) {
        pool = promise_1.default.createPool({
            host: index_1.config.db.host,
            port: index_1.config.db.port,
            user: index_1.config.db.user,
            password: index_1.config.db.password,
            database: index_1.config.db.database,
            waitForConnections: true,
            connectionLimit: index_1.config.db.connectionLimit,
            queueLimit: 0,
            dateStrings: ['DATE'],
            timezone: 'Z',
            charset: 'utf8mb4_unicode_ci',
            supportBigNumbers: true,
            decimalNumbers: true,
            multipleStatements: false,
        });
    }
    return pool;
}
/** Fails fast on boot so a bad DB config never reaches a request handler. */
async function assertDatabaseConnection() {
    const connection = await getPool().getConnection();
    try {
        await connection.ping();
    }
    finally {
        connection.release();
    }
}
async function closePool() {
    if (pool) {
        await pool.end();
        pool = null;
    }
}
async function query(sql, params = []) {
    const [rows] = await getPool().query(sql, params);
    return rows;
}
async function queryOne(sql, params = []) {
    const rows = await query(sql, params);
    return rows.length > 0 ? rows[0] : null;
}
async function execute(sql, params = []) {
    const [result] = await getPool().query(sql, params);
    return result;
}
/** Runs `work` inside a transaction, rolling back on any thrown error. */
async function withTransaction(work) {
    const connection = await getPool().getConnection();
    try {
        await connection.beginTransaction();
        const result = await work(connection);
        await connection.commit();
        return result;
    }
    catch (error) {
        await connection.rollback();
        throw error;
    }
    finally {
        connection.release();
    }
}
