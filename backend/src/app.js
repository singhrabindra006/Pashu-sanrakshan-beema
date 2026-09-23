const compression = require('compression');
const cors = require('cors');
const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');

const { config } = require('./config');
const { globalErrorHandler, notFoundHandler } = require('./core/middleware/error.middleware');
const { responseEnhancer } = require('./core/utils/apiResponse');
const adminRoutes = require('./modules/admin/admin.routes').default;
const animalRoutes = require('./modules/animals/animals.routes').default;
const { adminApplicationRouter, applicationRouter } = require('./modules/applications/applications.routes');
const authRoutes = require('./modules/auth/auth.routes').default;
const { adminClaimRouter, claimRouter } = require('./modules/claims/claims.routes');
const fileRoutes = require('./modules/files/files.routes').default;
const profileRoutes = require('./modules/profile/profile.routes').default;
const { adminSchemeRouter, schemeRouter } = require('./modules/schemes/schemes.routes');

function createApp() {
  const app = express();

  app.set('trust proxy', 1);
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(
    cors({
      origin: config.cors.origins.includes('*') ? true : config.cors.origins,
      credentials: true,
    }),
  );
  app.use(compression());
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true, limit: '1mb' }));
  app.use(morgan(config.isProduction ? 'combined' : 'dev'));
  app.use(responseEnhancer);

  app.get('/health', (_req, res) => {
    res.success({ status: 'ok', env: config.nodeEnv, time: new Date().toISOString() }, 'Service healthy');
  });

  const api = express.Router();
  api.use('/auth', authRoutes);
  api.use('/profile', profileRoutes);
  api.use('/schemes', schemeRouter);
  api.use('/admin/schemes', adminSchemeRouter);
  api.use('/animals', animalRoutes);
  api.use('/applications', applicationRouter);
  api.use('/admin/applications', adminApplicationRouter);
  api.use('/claims', claimRouter);
  api.use('/admin/claims', adminClaimRouter);
  api.use('/admin', adminRoutes);
  api.use('/files', fileRoutes);

  app.use(config.apiPrefix, api);
  app.use(notFoundHandler);
  app.use(globalErrorHandler);

  return app;
}

module.exports = { createApp };
module.exports.default = createApp;
