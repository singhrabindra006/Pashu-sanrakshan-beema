const { createApp } = require('./app');
const { config } = require('./config');
const { assertDatabaseConnection, closePool } = require('./config/database');
const { initialiseFirebase } = require('./config/firebase');
const { ensureUploadDirectories } = require('./config/multer');
const { lanIPv4s } = require('./core/utils/lanAddresses');

async function bootstrap() {
  ensureUploadDirectories();

  await assertDatabaseConnection();
  console.info(`[db] connected to ${config.db.host}:${config.db.port}/${config.db.database}`);

  initialiseFirebase();
  console.info('[firebase] admin SDK initialised');

  const server = createApp().listen(config.port, '0.0.0.0');

  server.on('listening', () => {
    const wifi = lanIPv4s();
    console.info(`[http] LIMS API on port ${config.port} (${config.nodeEnv})`);
    console.info(`[http]   this PC / USB: http://127.0.0.1:${config.port}${config.apiPrefix}`);
    if (wifi.length === 0) {
      console.info('[http]   Wi-Fi: no LAN IPv4 found yet — reconnect Wi-Fi and restart');
    } else {
      for (const ip of wifi) {
        console.info(`[http]   phone on Wi-Fi: http://${ip}:${config.port}${config.apiPrefix}`);
      }
    }
  });

  server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      console.error(`[http] port ${config.port} is already in use.`);
      console.error('[http] run `npm start` (it frees the port) or stop the other Node process.');
      process.exit(1);
      return;
    }
    throw error;
  });

  const shutdown = (signal) => {
    console.info(`[http] ${signal} received, shutting down`);
    server.close(() => {
      void closePool().finally(() => process.exit(0));
    });
    setTimeout(() => process.exit(1), 10_000).unref();
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

bootstrap().catch((error) => {
  console.error('[boot] failed to start LIMS API', error);
  process.exit(1);
});
