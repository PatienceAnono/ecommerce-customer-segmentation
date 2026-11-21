# Customer Segmentation & Behavioral Clustering
## Executive Summary Report

**Author:** Patience Anono — Data Analyst | Marketing Analytics | Customer Intelligence
**Project:** Customer Segmentation Using RFM Analysis & K-Means Clustering
**Industry:** D2C E-commerce · Beauty & Wellness
**Date:** May 2026

---

## Objective

To design a reproducible customer intelligence system that moves the business beyond generic, one-size-fits-all marketing. Using RFM Analysis and K-Means Clustering, this project identifies distinct customer groups with measurable behavioral profiles — enabling targeted retention campaigns, personalized marketing, and smarter acquisition investment.

**Business questions answered:**
1. Who are the highest-value customers, and what keeps them engaged?
2. Which customers are drifting toward churn before it becomes permanent?
3. Which acquisition channels produce the most valuable customers?
4. How should marketing strategies differ by customer group?

---

## Dataset

| Property | Detail |
|---|---|
| Records | 1,000 customers (post-cleaning) |
| Variables | 13 behavioral and transactional features |
| Geography | Kenya, UK, USA, Nigeria, Canada |
| Industry | D2C Beauty & Wellness E-commerce |
| Categories | Skincare, Haircare, Makeup, Bodycare, Wellness |

**Data quality issues resolved:** 10 duplicate records removed; missing values in `age` (48), `frequency` (26) and `gender` (180) imputed; `monetary_value` outliers capped at 99th percentile ($799); categorical inconsistencies in `gender` and `preferred_category` standardised.

---

## Methodology

**Phase 1 — Data Cleaning & Preparation**
All data cleaning decisions were logged and documented. No records were silently dropped. Winsorisation was applied to outliers rather than removal to preserve real customer signals.

**Phase 2 — Exploratory Data Analysis**
Distribution analysis across all 13 variables; correlation matrix; acquisition channel quality profiling; churn risk and email engagement analysis.

**Phase 3 — RFM Analysis**
Quintile-based scoring (1–5) applied to Recency, Frequency and Monetary Value dimensions. Composite RFM Score calculated. Six named business segments assigned using behavioral logic.

**Phase 4 — K-Means Clustering**
Feature matrix scaled using StandardScaler. Optimal k determined using the Elbow Method and Silhouette Score across k=2 to k=10. Final model: k=3, Silhouette Score = 0.2804.

---

## Key Findings

### RFM Segmentation — 6 Segments Identified

| Segment | Customers | Revenue Share | Avg Spend | Avg Recency | Churn Risk |
|---|---|---|---|---|---|
| **Champions** | 61 (6.1%) | 9.9% | $409 | 88 days | 0.44 |
| **Loyal Customers** | 92 (9.2%) | 17.5% | $482 | 344 days | 0.91 |
| **Potential Loyalists** | 377 (37.7%) | 36.2% | $243 | 184 days | 0.64 |
| **New Customers** | 173 (17.3%) | 15.9% | $233 | 77 days | 0.40 |
| **At Risk** | 184 (18.4%) | 14.5% | $199 | 436 days | 0.98 |
| **Hibernating** | 113 (11.3%) | 6.0% | $134 | 392 days | 0.93 |

### K-Means Clustering — 3 Clusters Identified

| Cluster | Size | Avg Spend | Avg Recency | Churn Risk | Profile |
|---|---|---|---|---|---|
| **Cluster 0** | 67 (6.7%) | $799 | 336 days | 0.87 | High-value, at-risk — formerly strong spenders now disengaging |
| **Cluster 1** | 428 (42.8%) | $213 | 399 days | 0.97 | Low-value, dormant — high churn risk, low monetary return |
| **Cluster 2** | 505 (50.5%) | $215 | 101 days | 0.46 | Active base — recently engaged, moderate value, lowest churn risk |

### Critical Insight: Revenue Concentration Risk
The top two RFM tiers (Champions + Loyal Customers) account for only **15.3% of customers** but **27.4% of total revenue**. A churn event among Loyal Customers (avg churn risk: 0.91) would have disproportionate revenue impact. Protecting this cohort is the highest-priority action.

### Channel Quality
All five acquisition channels (Email, Social Media, Organic Search, Paid Ads, Referral) show broadly similar customer volumes (~200 each), suggesting acquisition is balanced — the opportunity lies in **activation and retention**, not acquisition volume.

---

## Business Recommendations

### 🏆 Champions (61 customers · 9.9% revenue)
**Action: Protect and reward.**
- Launch a VIP loyalty tier with exclusive early access to new products
- Personalised "thank you" campaigns with premium gift-with-purchase
- Referral incentive programme — Champions are the most credible advocates
- Do NOT over-email. High-frequency generic messages will degrade this relationship.

### 💙 Loyal Customers (92 customers · 17.5% revenue · ⚠️ churn risk 0.91)
**Action: Urgent re-engagement + upsell.**
- This segment has the highest revenue share AND the second-highest churn risk — a dangerous combination requiring immediate attention
- Cross-sell complementary categories (e.g., Skincare-loyal customers → introduce Wellness)
- Bundle offers and subscription tier upgrade incentives
- Triggered win-back sequence for those with recency > 180 days

### 🟡 Potential Loyalists (377 customers · 36.2% revenue)
**Action: The highest-ROI conversion opportunity.**
- The largest single segment. Moving even 20% into Loyal tier would significantly increase revenue concentration in high-value customers
- Personalised product recommendations based on preferred category
- Loyalty points programme to incentivise repeat purchase frequency
- Educational email series about product ranges they haven't explored

### 🔴 At Risk (184 customers · 14.5% revenue · churn risk 0.98)
**Action: Reactivation campaign — act now.**
- Average recency of 436 days. These customers were valuable and are now almost completely disengaged
- Last-chance win-back with a meaningful discount or exclusive offer (not generic spam)
- Survey email: "We miss you — what would bring you back?" — data collection + re-engagement
- Set a hard deadline: customers not reactivated within 60 days should be moved to sunset flow

### 🟢 New Customers (173 customers · 15.9% revenue)
**Action: Onboarding window is open — close the second purchase.**
- Average recency of 77 days — recently acquired, but frequency of 2.1 shows they haven't committed to repeat purchase
- Automated welcome series: Days 1, 7, 14, 30 with product education and category discovery
- Second-purchase incentive: time-limited offer triggered 14 days after first purchase
- Capture category preference early to personalise all future communications

### ⚪ Hibernating (113 customers · 6.0% revenue)
**Action: Minimal investment — evaluate carefully.**
- Low recency, low frequency, lowest average spend ($134)
- For top 20% by historical spend: one final win-back offer
- For remaining 80%: sunset flow — reduce to quarterly touch only
- Remove from regular campaign lists to protect email sender reputation

---

## Summary Metrics

| Metric | Value |
|---|---|
| Total Customers Analysed | 1,000 |
| Total Revenue in Dataset | ~$253,046 |
| Average Order Value | $253 |
| Customers at High Churn Risk (≥0.7) | ~640 (64%) |
| K-Means Optimal Clusters | 3 |
| Silhouette Score | 0.2804 |
| RFM Segments | 6 |

---

*Report produced by PA Data Analytics — padataanalytics.com · hello@padataanalytics.com*
