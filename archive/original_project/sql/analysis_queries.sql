-- ============================================================
-- FILE: analysis_queries.sql
-- PROJECT: Customer Segmentation & Behavioral Clustering
-- AUTHOR: Patience Anono — PA Data Analytics
-- DESCRIPTION: Business intelligence queries mirroring the
--              Python analysis — demonstrating SQL proficiency
--              alongside the Python notebook
-- ============================================================

-- ═══════════════════════════════════════════════════════════
-- SECTION 1: CUSTOMER OVERVIEW
-- ═══════════════════════════════════════════════════════════

-- Query 1.1: Total customers and key aggregate metrics
SELECT
    COUNT(DISTINCT c.customer_id)                        AS total_customers,
    ROUND(AVG(t.monetary_value), 2)                      AS avg_order_value,
    ROUND(AVG(t.frequency), 2)                           AS avg_purchase_frequency,
    ROUND(AVG(t.recency_days), 0)                        AS avg_recency_days,
    ROUND(SUM(t.monetary_value), 2)                      AS total_revenue,
    COUNT(CASE WHEN s.churn_risk_score >= 0.7 THEN 1 END) AS high_risk_customers
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id;

-- Query 1.2: Top 10 highest-spending customers
SELECT
    c.customer_id,
    c.country,
    c.acquisition_channel,
    c.preferred_category,
    t.monetary_value                AS total_spend,
    t.frequency                     AS purchase_count,
    t.recency_days,
    s.rfm_segment,
    s.churn_risk_score
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id
ORDER BY t.monetary_value DESC
LIMIT 10;

-- Query 1.3: Customer distribution by country
SELECT
    country,
    COUNT(customer_id)                                    AS customers,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER(), 1) AS pct_share
FROM customers
GROUP BY country
ORDER BY customers DESC;


-- ═══════════════════════════════════════════════════════════
-- SECTION 2: RFM SEGMENT ANALYSIS
-- ═══════════════════════════════════════════════════════════

-- Query 2.1: Segment size, revenue share and key metrics
SELECT
    s.rfm_segment,
    COUNT(s.customer_id)                     AS customers,
    ROUND(SUM(t.monetary_value), 2)          AS total_revenue,
    ROUND(AVG(t.monetary_value), 2)          AS avg_spend,
    ROUND(AVG(t.frequency), 2)               AS avg_frequency,
    ROUND(AVG(t.recency_days), 0)            AS avg_recency_days,
    ROUND(AVG(s.churn_risk_score), 3)        AS avg_churn_risk,
    ROUND(
        SUM(t.monetary_value) * 100.0 /
        SUM(SUM(t.monetary_value)) OVER(), 1
    )                                         AS revenue_share_pct
FROM customer_segments s
JOIN customer_transactions t ON s.customer_id = t.customer_id
GROUP BY s.rfm_segment
ORDER BY total_revenue DESC;

-- Query 2.2: Champions — full profile for VIP list
SELECT
    c.customer_id,
    c.gender,
    c.age,
    c.country,
    c.preferred_category,
    c.acquisition_channel,
    t.monetary_value,
    t.frequency,
    t.recency_days,
    s.rfm_score,
    s.rfm_code
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id
WHERE s.rfm_segment = 'Champions'
ORDER BY t.monetary_value DESC;

-- Query 2.3: At Risk customers — for reactivation campaign
SELECT
    c.customer_id,
    c.country,
    c.preferred_category,
    c.acquisition_channel,
    c.email_open_rate,
    t.monetary_value,
    t.frequency,
    t.recency_days,
    s.churn_risk_score,
    c.last_purchase_date
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id
WHERE s.rfm_segment = 'At Risk'
ORDER BY t.monetary_value DESC, s.churn_risk_score DESC;

-- Query 2.4: High-value customers at churn risk — URGENT list
-- Champions or Loyal Customers with churn_risk_score >= 0.7
SELECT
    c.customer_id,
    c.country,
    t.monetary_value,
    t.recency_days,
    s.rfm_segment,
    s.churn_risk_score,
    c.email_open_rate,
    c.last_purchase_date
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id
WHERE s.rfm_segment IN ('Champions', 'Loyal Customers')
  AND s.churn_risk_score >= 0.7
ORDER BY t.monetary_value DESC;


-- ═══════════════════════════════════════════════════════════
-- SECTION 3: ACQUISITION CHANNEL ANALYSIS
-- ═══════════════════════════════════════════════════════════

-- Query 3.1: Average customer value by acquisition channel
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id)             AS customers,
    ROUND(AVG(t.monetary_value), 2)           AS avg_ltv,
    ROUND(AVG(t.frequency), 2)                AS avg_frequency,
    ROUND(AVG(s.churn_risk_score), 3)         AS avg_churn_risk,
    COUNT(CASE WHEN s.rfm_segment = 'Champions' THEN 1 END) AS champions_count,
    ROUND(
        COUNT(CASE WHEN s.rfm_segment = 'Champions' THEN 1 END) * 100.0
        / COUNT(DISTINCT c.customer_id), 1
    )                                          AS champion_conversion_pct
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id
GROUP BY c.acquisition_channel
ORDER BY avg_ltv DESC;

-- Query 3.2: Revenue by acquisition channel and segment
SELECT
    c.acquisition_channel,
    s.rfm_segment,
    COUNT(c.customer_id)             AS customers,
    ROUND(SUM(t.monetary_value), 2)  AS total_revenue,
    ROUND(AVG(t.monetary_value), 2)  AS avg_spend
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id
GROUP BY c.acquisition_channel, s.rfm_segment
ORDER BY c.acquisition_channel, total_revenue DESC;


-- ═══════════════════════════════════════════════════════════
-- SECTION 4: PRODUCT CATEGORY ANALYSIS
-- ═══════════════════════════════════════════════════════════

-- Query 4.1: Revenue and customer count by category
SELECT
    c.preferred_category,
    COUNT(DISTINCT c.customer_id)       AS customers,
    ROUND(SUM(t.monetary_value), 2)     AS total_revenue,
    ROUND(AVG(t.monetary_value), 2)     AS avg_spend,
    ROUND(AVG(t.frequency), 2)          AS avg_frequency
FROM customers c
JOIN customer_transactions t ON c.customer_id = t.customer_id
GROUP BY c.preferred_category
ORDER BY total_revenue DESC;

-- Query 4.2: Category preference by RFM segment
-- Useful for personalised campaign design
SELECT
    s.rfm_segment,
    c.preferred_category,
    COUNT(c.customer_id)                  AS customers,
    ROUND(
        COUNT(c.customer_id) * 100.0 /
        SUM(COUNT(c.customer_id)) OVER (PARTITION BY s.rfm_segment), 1
    )                                      AS pct_of_segment
FROM customers c
JOIN customer_segments s ON c.customer_id = s.customer_id
GROUP BY s.rfm_segment, c.preferred_category
ORDER BY s.rfm_segment, pct_of_segment DESC;


-- ═══════════════════════════════════════════════════════════
-- SECTION 5: CHURN RISK ANALYSIS
-- ═══════════════════════════════════════════════════════════

-- Query 5.1: Churn risk distribution
SELECT
    CASE
        WHEN churn_risk_score < 0.3  THEN 'Low (< 0.3)'
        WHEN churn_risk_score < 0.6  THEN 'Medium (0.3–0.6)'
        WHEN churn_risk_score < 0.8  THEN 'High (0.6–0.8)'
        ELSE                              'Critical (≥ 0.8)'
    END                                    AS churn_risk_band,
    COUNT(customer_id)                     AS customers,
    ROUND(AVG(churn_risk_score), 3)        AS avg_score
FROM customer_segments
GROUP BY churn_risk_band
ORDER BY avg_score;

-- Query 5.2: High-risk customers by country (for geo-targeted campaigns)
SELECT
    c.country,
    COUNT(CASE WHEN s.churn_risk_score >= 0.8 THEN 1 END)  AS critical_risk,
    COUNT(CASE WHEN s.churn_risk_score >= 0.7
               AND s.churn_risk_score < 0.8 THEN 1 END)    AS high_risk,
    ROUND(AVG(t.monetary_value), 2)                         AS avg_spend
FROM customers c
JOIN customer_segments s      ON c.customer_id = s.customer_id
JOIN customer_transactions t  ON c.customer_id = t.customer_id
GROUP BY c.country
ORDER BY critical_risk DESC;


-- ═══════════════════════════════════════════════════════════
-- SECTION 6: K-MEANS CLUSTER ANALYSIS
-- ═══════════════════════════════════════════════════════════

-- Query 6.1: Cluster profile summary
SELECT
    s.kmeans_cluster,
    COUNT(s.customer_id)                   AS customers,
    ROUND(AVG(t.recency_days), 0)          AS avg_recency_days,
    ROUND(AVG(t.frequency), 2)             AS avg_frequency,
    ROUND(AVG(t.monetary_value), 2)        AS avg_monetary,
    ROUND(AVG(s.churn_risk_score), 3)      AS avg_churn_risk,
    ROUND(
        SUM(t.monetary_value) * 100.0 /
        SUM(SUM(t.monetary_value)) OVER(), 1
    )                                       AS revenue_share_pct
FROM customer_segments s
JOIN customer_transactions t ON s.customer_id = t.customer_id
GROUP BY s.kmeans_cluster
ORDER BY s.kmeans_cluster;

-- Query 6.2: RFM segment breakdown within each K-Means cluster
-- Shows how ML clusters relate to rule-based segments
SELECT
    s.kmeans_cluster,
    s.rfm_segment,
    COUNT(s.customer_id)              AS customers,
    ROUND(AVG(t.monetary_value), 2)   AS avg_spend
FROM customer_segments s
JOIN customer_transactions t ON s.customer_id = t.customer_id
GROUP BY s.kmeans_cluster, s.rfm_segment
ORDER BY s.kmeans_cluster, customers DESC;


-- ═══════════════════════════════════════════════════════════
-- SECTION 7: POWER BI DASHBOARD QUERIES
-- ═══════════════════════════════════════════════════════════
-- These queries are optimised for direct use as Power BI
-- data sources. Each maps to a specific dashboard page.

-- Query 7.1: Page 1 — Executive Overview KPIs
SELECT
    COUNT(DISTINCT c.customer_id)                          AS kpi_total_customers,
    ROUND(SUM(t.monetary_value), 2)                        AS kpi_total_revenue,
    ROUND(AVG(t.monetary_value), 2)                        AS kpi_avg_order_value,
    ROUND(AVG(t.frequency), 2)                             AS kpi_avg_frequency,
    COUNT(CASE WHEN s.churn_risk_score >= 0.7 THEN 1 END)  AS kpi_high_risk_count,
    COUNT(CASE WHEN s.rfm_segment = 'Champions' THEN 1 END) AS kpi_champions_count
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id;

-- Query 7.2: Page 2 — Customer Segments (for segment charts)
SELECT
    s.rfm_segment                            AS segment,
    COUNT(s.customer_id)                     AS customer_count,
    ROUND(SUM(t.monetary_value), 2)          AS total_revenue,
    ROUND(AVG(t.monetary_value), 2)          AS avg_spend,
    ROUND(AVG(s.churn_risk_score), 3)        AS avg_churn_risk
FROM customer_segments s
JOIN customer_transactions t ON s.customer_id = t.customer_id
GROUP BY s.rfm_segment;

-- Query 7.3: Page 3 — Customer Behavior (flat table for scatter/distribution)
SELECT
    c.customer_id,
    c.country,
    c.gender,
    c.age,
    c.preferred_category,
    c.acquisition_channel,
    c.email_open_rate,
    t.recency_days,
    t.frequency,
    t.monetary_value,
    s.rfm_segment,
    s.rfm_score,
    s.kmeans_cluster,
    s.churn_risk_score
FROM customers c
JOIN customer_transactions t  ON c.customer_id = t.customer_id
JOIN customer_segments s      ON c.customer_id = s.customer_id;

-- Query 7.4: Page 4 — Cluster Analysis
SELECT
    s.kmeans_cluster,
    COUNT(s.customer_id)            AS customers,
    ROUND(AVG(t.recency_days), 1)   AS avg_recency,
    ROUND(AVG(t.frequency), 2)      AS avg_frequency,
    ROUND(AVG(t.monetary_value), 2) AS avg_monetary,
    ROUND(AVG(s.churn_risk_score), 3) AS avg_churn_risk,
    ROUND(AVG(c.email_open_rate), 3)  AS avg_email_open
FROM customer_segments s
JOIN customer_transactions t ON s.customer_id = t.customer_id
JOIN customers c              ON s.customer_id = c.customer_id
GROUP BY s.kmeans_cluster
ORDER BY s.kmeans_cluster;
