-- ============================================================
-- analysis_queries.sql: reproduces the headline figures from the notebook.
-- Runs on SQLite (tested by sql/test_queries.py) and PostgreSQL.
-- Synthetic data: no real customers.
-- ============================================================

-- Q1. Overview. AOV is order-weighted and uses only customers whose order count was observed.
SELECT
    COUNT(*)                                                    AS customers,
    ROUND(SUM(monetary_value), 2)                               AS total_revenue_uncapped,
    ROUND(AVG(monetary_value), 2)                               AS mean_spend_per_customer,
    ROUND(SUM(CASE WHEN frequency_flag = 'observed' THEN monetary_value END)
        / SUM(CASE WHEN frequency_flag = 'observed' THEN frequency END), 2) AS aov_order_weighted,
    ROUND(AVG(aov), 2)                                          AS aov_mean_of_customer_aov,
    SUM(CASE WHEN churn_risk_score >= 0.70 THEN 1 ELSE 0 END)   AS churn_score_ge_070,
    ROUND(100.0 * AVG(CASE WHEN churn_risk_score >= 0.70 THEN 1.0 ELSE 0 END), 1) AS churn_score_ge_070_pct
FROM customer_segments;

-- Q2. Segment profile (sizes and revenue on uncapped spend).
SELECT
    segment,
    COUNT(*)                                                            AS customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_segments), 1) AS pct_customers,
    ROUND(SUM(monetary_value), 2)                                       AS revenue,
    ROUND(100.0 * SUM(monetary_value) / (SELECT SUM(monetary_value) FROM customer_segments), 2) AS pct_revenue,
    ROUND(AVG(recency_days), 1)                                         AS mean_recency_days,
    ROUND(AVG(frequency), 2)                                            AS mean_orders,
    ROUND(AVG(monetary_value), 2)                                       AS mean_spend
FROM customer_segments
GROUP BY segment
ORDER BY CASE recency_band WHEN 'Active' THEN 1 WHEN 'Cooling' THEN 2 WHEN 'Lapsing' THEN 3 ELSE 4 END, value_tier;

-- Q3. Recency band x value tier grid.
SELECT
    recency_band,
    SUM(CASE WHEN value_tier = 'High-Value' THEN 1 ELSE 0 END) AS high_value_customers,
    SUM(CASE WHEN value_tier = 'Standard'   THEN 1 ELSE 0 END) AS standard_customers
FROM customer_segments
GROUP BY recency_band
ORDER BY CASE recency_band WHEN 'Active' THEN 1 WHEN 'Cooling' THEN 2 WHEN 'Lapsing' THEN 3 ELSE 4 END;

-- Q4. Revenue concentration: share of revenue from the top 20% of customers by spend.
WITH ranked AS (
    SELECT monetary_value, ROW_NUMBER() OVER (ORDER BY monetary_value DESC) AS rn
    FROM customer_segments
)
SELECT ROUND(100.0 * SUM(CASE WHEN rn <= (SELECT COUNT(*) FROM customer_segments) * 0.2 THEN monetary_value ELSE 0 END)
       / SUM(monetary_value), 1) AS top_20pct_revenue_share
FROM ranked;

-- Q5. Win-back priority list: high-value customers who have not bought for 181+ days.
SELECT customer_id, segment, recency_days, frequency, monetary_value, preferred_category, age_under_18
FROM customer_segments
WHERE value_tier = 'High-Value' AND recency_band IN ('Lapsing', 'Lapsed')
ORDER BY monetary_value DESC
LIMIT 20;

-- Q6. Channel summary, DESCRIPTIVE ONLY. The notebook finds no detectable differences between channels
-- (Kruskal-Wallis, Holm-corrected). Do not rank or reallocate budget from this table.
SELECT acquisition_channel, COUNT(*) AS customers, ROUND(AVG(monetary_value), 2) AS mean_spend,
       ROUND(AVG(frequency), 2) AS mean_orders
FROM customer_segments
GROUP BY acquisition_channel
ORDER BY acquisition_channel;

-- Q7. Data-quality flags carried through from cleaning.
SELECT frequency_flag, COUNT(*) AS customers FROM customer_segments GROUP BY frequency_flag;
SELECT SUM(CASE WHEN age_under_18 THEN 1 ELSE 0 END) AS under_18, SUM(CASE WHEN age_imputed THEN 1 ELSE 0 END) AS age_imputed
FROM customer_segments;
