# Audit Log: v1 to v2

v1 was audited on 2026-11-21 and rebuilt the same day. The v1 files are kept unchanged in `archive/original_project/`.

## Issues found in v1 and how they were resolved

| # | Severity | v1 issue | Evidence | v2 resolution |
|---|---|---|---|---|
| 1 | Critical | "Loyal Customers" had no recency condition | Median recency 304 days; 89% inactive for over 180 days; median churn score 1.0 | Labels replaced by recency band x value tier |
| 2 | Critical | "New Customers" had no tenure condition | Median tenure 334 days; no signups in the 4 months before the analysis date | Removed. `newer_customer` (tenure 180 days or less) is a flag |
| 3 | Critical | Churn score used as a clustering input and then as evidence of churn | Spearman 0.95 with recency; R² 0.93 from recency alone | Removed from clustering; descriptive only |
| 4 | Critical | Channel, category and "Loyal outspend Champions" claims | Non-significant (e.g. Loyal vs Champions spend p = 0.53) | Removed; all tests now reported with Holm correction |
| 5 | High | Segments depended on row order | `rank(method="first")` on tied order counts; 60-74 customers moved | Deterministic scores; 0 changes under shuffling |
| 6 | High | k=3 not justified | Silhouette gap of 0.003 over k=2; no better than null once the churn score is removed; result flips with the spend cap | Full model selection; clustering demoted to exploratory |
| 7 | High | Executive summary figures wrong | AOV $253 (really mean spend), 64% churn (really 53.9%), $799 cap (really $1,315) | All figures regenerated from the notebook (`metrics.json`) |
| 8 | High | Synthetic data presented as client work | Notebook said "the business I analysed" | Disclaimer at the top of every document |
| 9 | High | 17 customers with zero orders but positive spend; 75 under-18s | Raw data checks | Corrected or flagged |
| 10 | Medium | Revenue reported on capped spend | Understated by $7,438 | Uncapped spend everywhere; log transform for modelling |
| 11 | Medium | Charts overwritten or misnamed; misleading min-max radar | `spending_distribution.png` written 3 times | 9 charts, one file each; radar removed |
| 12 | Medium | SQL schema rejected the data; sample inserts were invented rows | `age CHECK >= 18`; `CURRENT_DATE` in a generated column; `CUST_00001`-style rows not in the data | New schema mirroring the export; tested on SQLite against `metrics.json` |
| 13 | Medium | `src/` stubs unused and contradicting the notebook | e.g. `build_rfm` summed per-customer rows | Rewritten; the notebook imports them |
| 14 | Medium | Stale duplicate notebook with different results (k=2) | Cells not executed in order | Archived |
| 15 | Low | Unpinned requirements, no `.gitignore`, empty dashboard folders, wrong clone URL and paths | n/a | Fixed |

## Claims removed from v1

- "Champions + Loyal = 27.4% of revenue: concentration risk." The labels were invalid. The concentration is now measured directly (top 20% = 46.2% of revenue).
- "Loyal Customers spend more than Champions: the most counterintuitive finding." Not significant.
- "Cluster 0: 67 high-value customers not captured by RFM." That cluster was the top spend tail produced by the capped-spend feature.
- "Email and Referral produce the highest-LTV customers; reallocate acquisition budget." No detectable channel differences, and there is no cost data.
- "Category preference varies meaningfully by segment." Chi-square p = 0.97 (v2 segments), Cramér's V 0.06.
- "Average Order Value $253." Corrected to $64.50 order-weighted ($85.22 mean of customer AOV).
- "~640 (64%) customers at high churn risk." Corrected to 539 (53.9%), and described as a recency transformation.
- "Median churn risk 0.71." Corrected to 0.745.
- "Moving 20% of Potential Loyalists would significantly increase revenue" and "reallocation improves ROI without increasing spend." No defensible calculation is possible.
- Welcome series for "New Customers." No recently acquired customers exist in the data.

## Note on the audit's AOV estimate

The audit estimated AOV at about $83. That figure used capped spend and included imputed order counts.
v2 excludes corrected and imputed counts and uses uncapped spend, giving $85.22 (mean of customer AOV) or $64.50 (order-weighted).
Both definitions are reported.
