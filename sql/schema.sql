-- ============================================================
-- schema.sql: one table that mirrors data/processed/customer_segments.csv
-- Written in portable SQL (tested on SQLite; standard PostgreSQL types).
-- Synthetic data: no real customers.
-- ============================================================

DROP TABLE IF EXISTS customer_segments;

CREATE TABLE customer_segments (
    customer_id          VARCHAR(20)   PRIMARY KEY,
    gender               VARCHAR(10)   CHECK (gender IN ('Female', 'Male', 'Unknown')),
    age                  INTEGER       CHECK (age BETWEEN 10 AND 100),   -- data contains 16-17 year olds (flagged)
    age_imputed          BOOLEAN,
    age_under_18         BOOLEAN,
    country              VARCHAR(50)   NOT NULL,
    signup_date          DATE          NOT NULL,
    last_purchase_date   DATE          NOT NULL,
    tenure_days          INTEGER       CHECK (tenure_days >= 0),          -- computed in Python at the fixed analysis date 2025-05-01
    recency_days         INTEGER       CHECK (recency_days >= 0),
    frequency            INTEGER       CHECK (frequency >= 1),
    frequency_flag       VARCHAR(30)   CHECK (frequency_flag IN ('observed', 'imputed_median', 'zero_with_spend_set_to_1')),
    monetary_value       NUMERIC(10,2) CHECK (monetary_value >= 0),       -- uncapped total spend
    aov                  NUMERIC(10,2),                                    -- NULL where frequency was not observed
    preferred_category   VARCHAR(50),
    acquisition_channel  VARCHAR(50),
    email_open_rate      NUMERIC(4,2)  CHECK (email_open_rate BETWEEN 0 AND 1),
    churn_risk_score     NUMERIC(4,2)  CHECK (churn_risk_score BETWEEN 0 AND 1), -- supplied field; near-function of recency
    r_score              INTEGER       CHECK (r_score BETWEEN 1 AND 5),
    f_score              INTEGER       CHECK (f_score BETWEEN 1 AND 5),
    m_score              INTEGER       CHECK (m_score BETWEEN 1 AND 5),
    rfm_code             VARCHAR(3),
    recency_band         VARCHAR(10)   CHECK (recency_band IN ('Active', 'Cooling', 'Lapsing', 'Lapsed')),
    value_tier           VARCHAR(12)   CHECK (value_tier IN ('High-Value', 'Standard')),
    segment              VARCHAR(30)   NOT NULL,
    newer_customer       BOOLEAN,
    exploratory_cluster  INTEGER                                          -- exploratory only; not used for decisions
);

CREATE INDEX idx_segments_segment ON customer_segments (segment);
CREATE INDEX idx_segments_channel ON customer_segments (acquisition_channel);

-- PostgreSQL load (run from the repository root in psql):
-- \copy customer_segments FROM 'data/processed/customer_segments.csv' WITH (FORMAT csv, HEADER true)
