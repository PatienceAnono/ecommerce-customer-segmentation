# Methodology (v2)

> Synthetic data. All numbers below come from `notebooks/customer_segmentation.ipynb`.
> Detailed tables are in `reports/tables/`, and headline values are in `reports/metrics.json`.

## 1. Data and cleaning

Source: `data/raw/customer_segmentation_dataset.csv` (1,010 rows, 13 columns). Recency in this file is measured against
2025-05-01 for every row (`last_purchase_date + recency_days`), so that is the analysis date.

| Step | Rows | Decision |
|---|---|---|
| Exact duplicate rows | 10 | Dropped. Every duplicated `customer_id` was an exact copy. |
| Gender | 180 missing | M/F mapped to Male/Female; missing kept as "Unknown", not imputed |
| Category case | n/a | Title case |
| Tenure | n/a | `tenure_days` = 2025-05-01 - `signup_date` |
| Zero orders with spend | 17 | Impossible, so set to 1 order (minimum consistent value) and flagged `zero_with_spend_set_to_1` |
| Missing order count | 26 | Median of observed values (4) and flagged `imputed_median` |
| Missing age | 48 | Median and flagged. Age is not a segmentation input. |
| Under 18 | 75 | Kept and flagged `age_under_18` for consent review |
| Spend | 0 changed | **No cap.** Revenue uses uncapped spend. Modelling uses `log1p(spend)` (raw skew 4.88). |
| AOV | 43 blank | spend / orders, only where the order count was observed |

**Why no cap?** v1 capped spend at the 99th percentile ($1,315.02) and then reported "revenue" on capped values, which understated it by $7,438.
The cap also changed the K-Means solution: the original k=2 result appears only with uncapped spend, and k=3 only with capped spend.
A log transform reduces skew without discarding information.

## 2. Churn score assessment

`churn_risk_score` has a rank correlation of 0.949 with recency (Pearson 0.849). A monotone (isotonic) fit from recency alone explains 92.8% of its
variance. All 248 customers with recency over 365 days have a score of exactly 1.00. The score is therefore treated as a recency
transformation:
- It is excluded from clustering.
- It is reported only descriptively (539 customers, 53.9%, at 0.70 or above).
- It is never used as evidence that a segment is "high churn risk".

## 3. RFM scores (reference only)

| Score | Method | Why |
|---|---|---|
| R | Quintiles of `recency_days` computed on the values (5 = most recent) | Equal values always share a score |
| F | Fixed bins: 1, 2, 3-4, 5-6, 7+ orders | Order count is a small integer with large ties; quantile scoring has to split identical customers |
| M | Quintiles of uncapped spend | Continuous, so ties are negligible |

**Instability root cause (v1).** v1 used `qcut(frequency.rank(method="first"))`, which breaks ties by row position.
Customers with identical order counts received different F scores. For example, of the 152 customers with 2 orders, 109 scored F=1 and 43 scored F=2.
Shuffling the row order 20 times moved **60 to 74 customers** (median 67) between v1 segments. The cause was the tie-break alone, not
K-Means, distance ties or preprocessing. With the revised scoring, 20 shuffles change **0** scores and **0** segments.

## 4. Primary segmentation

Recency band (Active 0-90, Cooling 91-180, Lapsing 181-365, Lapsed over 365 days) x value tier (High-Value = top 20% by total spend,
threshold $368.35; Standard otherwise), giving 8 segments. Customers with tenure of 180 days or less are flagged `newer_customer` (87); this is not a segment.

Why these axes:
- Recency and spend are the two variables that matter most for CRM decisions (contact timing and investment level).
- They are nearly independent of each other.
- No other variable showed any relationship with them (section 6).

Order count is shown in the profiles but not used as an axis. It is almost uncorrelated with spend (Spearman -0.02), and the High-Value
tier differs from Standard in basket size (median AOV $111-$205 vs $40-$43), not in order count.

The thresholds are conventional and readable rather than optimised. Moving them changes segment sizes. It does not change the conclusion
that recency and spend are the only informative dimensions.

## 5. Clustering assessment

Three feature sets, all standardised, with K-Means (`n_init=20`, `random_state=42`) for k = 2 to 8:

| Feature set | Features |
|---|---|
| Original | recency, orders, capped spend, email open rate, churn score |
| Original without churn | recency, orders, capped spend, email open rate |
| Revised | recency, orders, log1p(spend) |

Diagnostics for each k:
- inertia (elbow), silhouette and a **null silhouette** (columns shuffled independently: same marginals, no joint structure);
- Davies-Bouldin, Calinski-Harabasz and Gaussian-mixture BIC;
- bootstrap ARI (50 refits on 80% subsamples) and row-shuffle ARI (20 permutations);
- Ward agreement (ARI).

Full table: `reports/tables/kmeans_model_selection.csv`.

| | Silhouette | Null silhouette | Bootstrap ARI (mean) |
|---|---|---|---|
| Original, k=3 | 0.280 | 0.177 | 0.804 (min 0.50) |
| Original without churn, k=3 | 0.198 | 0.214 | 0.787 |
| Revised, k=3 | 0.269 | 0.263 | 0.981 |
| Revised, k=4 | 0.270 | 0.278 | 0.911 |

Findings:
- The original model's separation above its null came from recency entering twice (recency plus the churn score). Without the churn score it is no better than the null (above it for 3 of 7 k values, below for 4).
- With the revised features, the silhouette is indistinguishable from the null at every k. **There is no evidence of natural clusters.**
- The elbow has no clear bend. Davies-Bouldin and Calinski-Harabasz favour k=4, while bootstrap stability, row-shuffle stability and BIC
  favour k=3. Gaussian-mixture BIC prefers several components over one, which is expected from non-Gaussian marginals (flat recency,
  discrete orders, skewed spend) and is not by itself evidence of groups.
- A depth-2 decision tree reproduces 96.5% of the original clusters (from recency and capped spend) and 95.1% of the revised k=3 clusters
  (from recency at about 298 days and orders at about 4.5). Which thresholds K-Means "finds" depends on which features are supplied.
- The revised k=3 clusters agree only weakly with the rule-based segments (ARI 0.20) and with the original clusters (ARI 0.28).
- The original k=3 solution was also mildly sensitive to row order (minimum row-shuffle ARI 0.92). The revised k=3 solution is close to invariant (0.997).

**Decision.** K-Means provides limited additional value on this data. The rule-based grid is the primary segmentation.
A k=3 K-Means label (`exploratory_cluster`) is exported for reference only. k=3 was picked as the most stable candidate, not because the data shows three groups.

## 6. Insight testing

All 16 comparisons are tested as one family with a Holm correction (`reports/tables/insight_tests.csv`):
- Kruskal-Wallis with epsilon-squared for numeric outcomes.
- Chi-square with Cramér's V for categorical pairs. Every expected count is at least 6.4.

Segments are not tested on recency or spend because they are defined by them.

| Comparison family | Result |
|---|---|
| Spend, orders, AOV, recency and churn score by acquisition channel | No detectable difference (all Holm p = 1.0; epsilon² < 0.006) |
| Spend and orders by preferred category; spend by country | No detectable difference |
| Email open rate and age by segment | No detectable difference |
| Segment and value tier vs channel, category, country, gender | Independent (Cramér's V 0.03-0.08) |
| Email open rate vs spend, recency and orders (Spearman) | rho within ±0.03, not significant |

Non-significance here is not proof of no effect, but any effect is too small to be useful for targeting at this sample size.

## 7. Reproducibility

- The fixed analysis date and `random_state=42` are set in `src/config.py`.
- Segment rules are deterministic and invariant to row order.
- The notebook reproduces the v1 segments and clusters exactly (100% and ARI 1.0) from the archived export before comparing.
- `sql/test_queries.py` re-computes the headline figures in SQL and asserts that they match `metrics.json`.
- Library versions are pinned in `requirements.txt`.
