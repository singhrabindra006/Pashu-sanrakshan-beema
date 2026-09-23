-- =============================================================================
-- Livestock Insurance Management System (LIMS)
-- MySQL 8.0 schema - 6 tables
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `livestock_insurance`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `livestock_insurance`;

-- -----------------------------------------------------------------------------
-- Table 1: users (core identity & Firebase auth sync)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `firebase_uid` VARCHAR(128) NOT NULL,
  `email`        VARCHAR(255) NOT NULL,
  `full_name`    VARCHAR(150) NOT NULL,
  `role`         ENUM('FARMER','ADMIN') NOT NULL DEFAULT 'FARMER',
  `is_active`    BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_firebase_uid` (`firebase_uid`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_role` (`role`)
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Table 2: farmer_profiles (farmer-only data - phone + photo)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `farmer_profiles` (
  `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`            INT UNSIGNED NOT NULL,
  `phone`              VARCHAR(20) NULL,
  `profile_image_path` VARCHAR(500) NULL,
  `created_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_farmer_profiles_user_id` (`user_id`),
  CONSTRAINT `fk_farmer_profiles_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Table 3: schemes (admin managed)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `schemes` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(150) NOT NULL,
  `description`  TEXT NULL,
  `max_coverage` DECIMAL(12,2) NOT NULL,
  `start_date`   DATE NOT NULL,
  `end_date`     DATE NOT NULL,
  `is_active`    BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_schemes_active_window` (`is_active`, `start_date`, `end_date`)
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Table 4: animals (farmer owned)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `animals` (
  `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `farmer_profile_id` INT UNSIGNED NOT NULL,
  `ear_tag`           VARCHAR(50) NOT NULL,
  `animal_type`       ENUM('COW','BUFFALO','GOAT','SHEEP') NOT NULL,
  `breed`             VARCHAR(100) NULL,
  `age_months`        INT UNSIGNED NOT NULL DEFAULT 0,
  `photo_path`        VARCHAR(500) NULL,
  `is_active`         BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_animals_ear_tag` (`ear_tag`),
  KEY `idx_animals_owner` (`farmer_profile_id`, `is_active`),
  CONSTRAINT `fk_animals_farmer_profile`
    FOREIGN KEY (`farmer_profile_id`) REFERENCES `farmer_profiles` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Table 5: applications (core workflow)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `applications` (
  `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_number` VARCHAR(50) NOT NULL,
  `farmer_profile_id`  INT UNSIGNED NOT NULL,
  `animal_id`          INT UNSIGNED NOT NULL,
  `scheme_id`          INT UNSIGNED NOT NULL,
  `coverage_amount`    DECIMAL(12,2) NOT NULL,
  `status`             ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  `policy_number`      VARCHAR(50) NULL,
  `policy_start_date`  DATE NULL,
  `policy_end_date`    DATE NULL,
  `rejection_reason`   TEXT NULL,
  `decided_by`         INT UNSIGNED NULL,
  `decided_at`         TIMESTAMP NULL DEFAULT NULL,
  `created_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_applications_number` (`application_number`),
  UNIQUE KEY `uq_applications_policy_number` (`policy_number`),
  KEY `idx_applications_owner_status` (`farmer_profile_id`, `status`),
  KEY `idx_applications_status` (`status`),
  CONSTRAINT `fk_applications_farmer_profile`
    FOREIGN KEY (`farmer_profile_id`) REFERENCES `farmer_profiles` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_applications_animal`
    FOREIGN KEY (`animal_id`) REFERENCES `animals` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_applications_scheme`
    FOREIGN KEY (`scheme_id`) REFERENCES `schemes` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_applications_decided_by`
    FOREIGN KEY (`decided_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Table 6: claims 
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `claims` (
  `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `claim_number`     VARCHAR(50) NOT NULL,
  `application_id`   INT UNSIGNED NOT NULL,
  `incident_type`    ENUM('DEATH','DISEASE','ACCIDENT','THEFT','NATURAL_DISASTER','OTHER') NOT NULL,
  `incident_date`    DATE NOT NULL,
  `description`      TEXT NOT NULL,
  `claimed_amount`   DECIMAL(12,2) NOT NULL,
  `approved_amount`  DECIMAL(12,2) NULL,
  `evidence_path`    VARCHAR(500) NULL,
  `status`           ENUM('SUBMITTED','APPROVED','REJECTED') NOT NULL DEFAULT 'SUBMITTED',
  `rejection_reason` TEXT NULL,
  `decided_by`       INT UNSIGNED NULL,
  `decided_at`       TIMESTAMP NULL DEFAULT NULL,
  `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_claims_number` (`claim_number`),
  KEY `idx_claims_application` (`application_id`),
  KEY `idx_claims_status` (`status`),
  CONSTRAINT `fk_claims_application`
    FOREIGN KEY (`application_id`) REFERENCES `applications` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_claims_decided_by`
    FOREIGN KEY (`decided_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;
