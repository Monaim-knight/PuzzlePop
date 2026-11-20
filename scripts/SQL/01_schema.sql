-- =========================================================
-- PuzzlePop Marketing Analytics
-- 01 - Analytical Database Schema
-- =========================================================
--
-- Purpose:
-- Create the four analysis-ready MySQL tables used by the
-- PuzzlePop Marketing Analytics project.
--
-- Source:
-- Processed synthetic datasets produced by the R pipeline.
--
-- Important:
-- All project data is synthetic and created solely for
-- portfolio and educational purposes.
--
-- Grain:
-- analytics_ad_delivery      = one ad-delivery observation
-- analytics_installs         = one attributed install/user
-- analytics_user_performance = one user
-- analytics_experiment       = one user per experiment
--
-- =========================================================


CREATE DATABASE IF NOT EXISTS puzzlepop_marketing;

USE puzzlepop_marketing;


-- =========================================================
-- 1. AD DELIVERY
-- =========================================================

CREATE TABLE IF NOT EXISTS analytics_ad_delivery (
    raw_row_id VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    channel_code VARCHAR(20) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    campaign_id VARCHAR(30) NOT NULL,
    campaign_name VARCHAR(100) NOT NULL,
    strategy_code VARCHAR(30) NOT NULL,
    strategy_name VARCHAR(100) NOT NULL,
    creative_id VARCHAR(30) NOT NULL,
    creative_name VARCHAR(100) NOT NULL,
    creative_type VARCHAR(50) NOT NULL,
    creative_concept VARCHAR(100) NOT NULL,
    country_code VARCHAR(10) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    spend DECIMAL(12,2) NOT NULL,
    impressions BIGINT UNSIGNED NOT NULL,
    clicks BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (raw_row_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;


-- =========================================================
-- 2. INSTALL / ATTRIBUTION
-- =========================================================

CREATE TABLE IF NOT EXISTS analytics_installs (
    appsflyer_id VARCHAR(30) NOT NULL,
    customer_user_id VARCHAR(30) NOT NULL,
    install_time DATETIME NOT NULL,
    attributed_touch_time DATETIME DEFAULT NULL,
    attributed_touch_type VARCHAR(30) DEFAULT NULL,
    acquisition_type VARCHAR(20) NOT NULL,
    is_organic TINYINT(1) NOT NULL,
    is_retargeting TINYINT(1) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    campaign_id VARCHAR(30) DEFAULT NULL,
    campaign_name VARCHAR(100) DEFAULT NULL,
    creative_id VARCHAR(30) DEFAULT NULL,
    creative_name VARCHAR(100) DEFAULT NULL,
    creative_type VARCHAR(50) DEFAULT NULL,
    creative_concept VARCHAR(100) DEFAULT NULL,
    country_code VARCHAR(10) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    platform VARCHAR(20) NOT NULL,

    PRIMARY KEY (appsflyer_id),

    UNIQUE KEY uq_installs_customer_user_id
        (customer_user_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;


-- =========================================================
-- 3. USER PERFORMANCE & MONETIZATION
-- =========================================================

CREATE TABLE IF NOT EXISTS analytics_user_performance (
    appsflyer_id VARCHAR(30) NOT NULL,
    customer_user_id VARCHAR(30) NOT NULL,
    sessions_first_7d INT UNSIGNED NOT NULL,
    retained_d1 TINYINT(1) NOT NULL,
    retained_d7 TINYINT(1) NOT NULL,
    retained_d30 TINYINT(1) NOT NULL,
    is_payer TINYINT(1) NOT NULL,
    purchase_count INT UNSIGNED NOT NULL,
    iap_revenue DECIMAL(12,2) NOT NULL,
    ad_impressions BIGINT UNSIGNED NOT NULL,
    ad_revenue DECIMAL(16,6) NOT NULL,
    total_revenue DECIMAL(16,6) NOT NULL,

    PRIMARY KEY (appsflyer_id),

       UNIQUE KEY uq_performance_customer_user_id
        (customer_user_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;


-- =========================================================
-- 4. ONBOARDING EXPERIMENT
-- =========================================================

CREATE TABLE IF NOT EXISTS analytics_experiment (
    customer_user_id VARCHAR(30) NOT NULL,
    experiment_id VARCHAR(30) NOT NULL,
    experiment_variant VARCHAR(20) NOT NULL,
    tutorial_completed TINYINT(1) NOT NULL,
    retained_d1 TINYINT(1) NOT NULL,
    retained_d7 TINYINT(1) NOT NULL,
    retained_d30 TINYINT(1) NOT NULL,
    is_payer TINYINT(1) NOT NULL,
    total_revenue DECIMAL(16,6) NOT NULL,

        PRIMARY KEY (
        customer_user_id,
        experiment_id
    )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;