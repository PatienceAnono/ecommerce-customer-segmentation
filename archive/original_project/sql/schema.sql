-- ============================================================
-- FILE: schema.sql
-- PROJECT: Customer Segmentation & Behavioral Clustering
-- AUTHOR: Patience Anono — PA Data Analytics
-- DESCRIPTION: Full database schema for the customer CRM system
-- ============================================================

-- ─── Drop tables if they exist (for clean re-runs) ──────────
DROP TABLE IF EXISTS customer_transactions;
DROP TABLE IF EXISTS customer_segments;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS acquisition_channels;
DROP TABLE IF EXISTS product_categories;

-- ─── Reference table: Acquisition Channels ──────────────────
CREATE TABLE acquisition_channels (
    channel_id   SERIAL PRIMARY KEY,
    channel_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO acquisition_channels (channel_name) VALUES
    ('Email'),
    ('Social Media'),
    ('Organic Search'),
    ('Paid Ads'),
    ('Referral');

-- ─── Reference table: Product Categories ────────────────────
CREATE TABLE product_categories (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO product_categories (category_name) VALUES
    ('Skincare'),
    ('Haircare'),
    ('Makeup'),
    ('Bodycare'),
    ('Wellness');

-- ─── Core table: Customers ───────────────────────────────────
CREATE TABLE customers (
    customer_id          VARCHAR(20)    PRIMARY KEY,
    gender               VARCHAR(10)    CHECK (gender IN ('Male', 'Female', 'Unknown')),
    age                  INT            CHECK (age BETWEEN 18 AND 100),
    country              VARCHAR(50)    NOT NULL,
    signup_date          DATE           NOT NULL,
    last_purchase_date   DATE,
    tenure_days          INT            GENERATED ALWAYS AS (
                             EXTRACT(DAY FROM (CURRENT_DATE - signup_date))::INT
                         ) STORED,
    preferred_category   VARCHAR(50)    REFERENCES product_categories(category_name),
    acquisition_channel  VARCHAR(50)    REFERENCES acquisition_channels(channel_name),
    email_open_rate      DECIMAL(4,3)   CHECK (email_open_rate BETWEEN 0 AND 1),
    created_at           TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

-- ─── Transactions table ──────────────────────────────────────
CREATE TABLE customer_transactions (
    transaction_id   SERIAL          PRIMARY KEY,
    customer_id      VARCHAR(20)     NOT NULL REFERENCES customers(customer_id),
    recency_days     INT             CHECK (recency_days >= 0),
    frequency        DECIMAL(5,1)    CHECK (frequency >= 0),
    monetary_value   DECIMAL(10,2)   CHECK (monetary_value >= 0),
    recorded_at      DATE            DEFAULT CURRENT_DATE
);

-- ─── Segmentation results table ─────────────────────────────
CREATE TABLE customer_segments (
    segment_id       SERIAL          PRIMARY KEY,
    customer_id      VARCHAR(20)     NOT NULL REFERENCES customers(customer_id),
    r_score          INT             CHECK (r_score BETWEEN 1 AND 5),
    f_score          INT             CHECK (f_score BETWEEN 1 AND 5),
    m_score          INT             CHECK (m_score BETWEEN 1 AND 5),
    rfm_score        INT             CHECK (rfm_score BETWEEN 3 AND 15),
    rfm_code         VARCHAR(5),
    rfm_segment      VARCHAR(30),
    kmeans_cluster   INT             CHECK (kmeans_cluster >= 0),
    churn_risk_score DECIMAL(4,3)    CHECK (churn_risk_score BETWEEN 0 AND 1),
    segment_date     DATE            DEFAULT CURRENT_DATE,
    UNIQUE (customer_id, segment_date)
);

-- ─── Indexes for performance ─────────────────────────────────
CREATE INDEX idx_customers_country         ON customers(country);
CREATE INDEX idx_customers_channel         ON customers(acquisition_channel);
CREATE INDEX idx_customers_category        ON customers(preferred_category);
CREATE INDEX idx_transactions_customer     ON customer_transactions(customer_id);
CREATE INDEX idx_segments_rfm_segment      ON customer_segments(rfm_segment);
CREATE INDEX idx_segments_cluster          ON customer_segments(kmeans_cluster);
CREATE INDEX idx_segments_churn            ON customer_segments(churn_risk_score);
