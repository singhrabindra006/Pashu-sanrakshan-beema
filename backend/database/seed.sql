-- =============================================================================
-- LIMS demo data.
-- Run AFTER schema.sql. Replace the firebase_uid values with the real UIDs from
-- your Firebase project (Authentication -> Users), otherwise these rows cannot
-- be used to log in.
-- =============================================================================

USE `livestock_insurance`;

-- Admin accounts are never created by the app; they are inserted here.
INSERT INTO `users` (`firebase_uid`, `email`, `full_name`, `role`)
VALUES ('REPLACE_WITH_ADMIN_FIREBASE_UID', 'admin@lims.local', 'System Administrator', 'ADMIN')
ON DUPLICATE KEY UPDATE `full_name` = VALUES(`full_name`), `role` = 'ADMIN';

INSERT INTO `schemes` (`name`, `description`, `max_coverage`, `start_date`, `end_date`, `is_active`)
VALUES
  ('Cattle Suraksha 2025',
   'Comprehensive cover for cows and buffaloes against death, disease, accident and theft. Requires a valid ear tag and a clear identification photo.',
   80000.00, '2025-01-01', '2026-12-31', TRUE),
  ('Small Ruminant Shield 2025',
   'Cover tailored to goats and sheep. Includes natural disaster protection for flock owners.',
   25000.00, '2025-01-01', '2026-12-31', TRUE),
  ('Dairy Plus Premium',
   'High value cover for high yielding milch animals. Veterinary certificate recommended at claim time.',
   150000.00, '2025-04-01', '2026-03-31', TRUE),
  ('Legacy Pilot Scheme 2023',
   'Closed pilot programme retained for historical records only.',
   40000.00, '2023-01-01', '2023-12-31', FALSE);
