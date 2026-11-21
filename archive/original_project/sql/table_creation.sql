-- ============================================================
-- FILE: table_creation.sql
-- PROJECT: Customer Segmentation & Behavioral Clustering
-- AUTHOR: Patience Anono — PA Data Analytics
-- DESCRIPTION: Table population with sample data representing
--              the segmentation output from the Python analysis
-- ============================================================

-- ─── Insert sample customers (representative rows) ──────────
INSERT INTO customers (
    customer_id, gender, age, country,
    signup_date, last_purchase_date,
    preferred_category, acquisition_channel, email_open_rate
) VALUES
-- Champions (high R, F, M scores)
('CUST_00001', 'Female', 28, 'Kenya',    '2023-01-15', '2025-04-20', 'Skincare',  'Organic Search', 0.45),
('CUST_00002', 'Male',   34, 'Nigeria',  '2022-11-03', '2025-04-18', 'Haircare',  'Referral',       0.52),
('CUST_00003', 'Female', 31, 'UK',       '2023-03-22', '2025-04-15', 'Makeup',    'Email',          0.38),

-- Loyal Customers
('CUST_00004', 'Female', 42, 'Canada',   '2022-06-10', '2024-10-12', 'Bodycare',  'Paid Ads',       0.31),
('CUST_00005', 'Male',   29, 'USA',      '2023-07-08', '2024-09-30', 'Wellness',  'Social Media',   0.28),

-- Potential Loyalists
('CUST_00006', 'Female', 26, 'Kenya',    '2023-09-14', '2025-02-20', 'Skincare',  'Email',          0.33),
('CUST_00007', 'Female', 38, 'UK',       '2023-04-01', '2024-12-15', 'Makeup',    'Organic Search', 0.25),

-- At Risk
('CUST_00008', 'Male',   45, 'Nigeria',  '2022-03-19', '2024-02-10', 'Haircare',  'Paid Ads',       0.18),
('CUST_00009', 'Female', 33, 'Canada',   '2022-07-25', '2024-01-05', 'Bodycare',  'Referral',       0.22),

-- New Customers
('CUST_00010', 'Female', 24, 'USA',      '2025-01-10', '2025-04-01', 'Skincare',  'Social Media',   0.41),
('CUST_00011', 'Male',   30, 'Kenya',    '2025-02-14', '2025-04-10', 'Wellness',  'Organic Search', 0.35),

-- Hibernating
('CUST_00012', 'Female', 52, 'UK',       '2021-11-20', '2023-08-14', 'Makeup',    'Email',          0.12),
('CUST_00013', 'Male',   37, 'Nigeria',  '2022-01-05', '2023-07-20', 'Skincare',  'Social Media',   0.09);

-- ─── Insert transaction records ──────────────────────────────
INSERT INTO customer_transactions (customer_id, recency_days, frequency, monetary_value, recorded_at) VALUES
-- Champions
('CUST_00001', 11,  7, 512.40, '2025-05-01'),
('CUST_00002', 13,  6, 398.75, '2025-05-01'),
('CUST_00003', 16,  6, 317.20, '2025-05-01'),
-- Loyal Customers
('CUST_00004', 201, 6, 495.80, '2025-05-01'),
('CUST_00005', 213, 5, 469.10, '2025-05-01'),
-- Potential Loyalists
('CUST_00006', 70,  4, 278.30, '2025-05-01'),
('CUST_00007', 137, 4, 207.60, '2025-05-01'),
-- At Risk
('CUST_00008', 450, 5, 215.40, '2025-05-01'),
('CUST_00009', 481, 4, 182.90, '2025-05-01'),
-- New Customers
('CUST_00010', 30,  2, 243.20, '2025-05-01'),
('CUST_00011', 21,  2, 222.50, '2025-05-01'),
-- Hibernating
('CUST_00012', 626, 2, 155.70, '2025-05-01'),
('CUST_00013', 649, 1, 113.20, '2025-05-01');

-- ─── Insert segmentation results ────────────────────────────
INSERT INTO customer_segments (
    customer_id, r_score, f_score, m_score, rfm_score,
    rfm_code, rfm_segment, kmeans_cluster, churn_risk_score
) VALUES
('CUST_00001', 5, 5, 5, 15, '555', 'Champions',          2, 0.21),
('CUST_00002', 5, 5, 4, 14, '554', 'Champions',          2, 0.38),
('CUST_00003', 5, 4, 4, 13, '544', 'Champions',          2, 0.33),
('CUST_00004', 3, 5, 5, 13, '355', 'Loyal Customers',    0, 0.85),
('CUST_00005', 3, 4, 5, 12, '345', 'Loyal Customers',    0, 0.88),
('CUST_00006', 4, 3, 3,  10, '433', 'Potential Loyalists',2, 0.58),
('CUST_00007', 3, 3, 3,   9, '333', 'Potential Loyalists',2, 0.62),
('CUST_00008', 1, 4, 3,   8, '143', 'At Risk',           1, 0.97),
('CUST_00009', 1, 3, 2,   6, '132', 'At Risk',           1, 0.99),
('CUST_00010', 5, 2, 3,  10, '523', 'New Customers',     2, 0.35),
('CUST_00011', 5, 1, 3,   9, '513', 'New Customers',     2, 0.41),
('CUST_00012', 1, 2, 2,   5, '122', 'Hibernating',       1, 0.95),
('CUST_00013', 1, 1, 1,   3, '111', 'Hibernating',       1, 0.98);
