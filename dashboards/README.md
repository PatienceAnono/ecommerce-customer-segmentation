# Dashboard

No dashboard file is included yet. The notebook writes dashboard-ready exports to `data/processed/`:

| File | Grain | Use |
|---|---|---|
| `customer_segments.csv` | one row per customer (1,000) | Main table: `segment`, `recency_band`, `value_tier`, R/F/M scores, data-quality flags |
| `segment_profiles.csv` | one row per segment (8) | Pre-aggregated profile, revenue on uncapped spend |
| `exploratory_cluster_profiles.csv` | one row per K-Means cluster (3) | Reference only; not for decisions |

Suggested pages for Power BI or Looker Studio:
1. **Overview:** customers, revenue, AOV and the recency x value grid. Use `recency_band` on columns and `value_tier` on rows.
2. **Win-back list:** filter `value_tier = High-Value` and `recency_band` in (Lapsing, Lapsed), sorted by `monetary_value`. Exclude or flag `age_under_18`.
3. **Data quality:** counts by `frequency_flag`, `age_imputed` and `age_under_18`.

Measure definitions that match the notebook:
- Revenue = SUM(`monetary_value`), uncapped.
- AOV (order-weighted) = SUM(`monetary_value`) / SUM(`frequency`), only where `frequency_flag = "observed"`.

Avoid ranking acquisition channels or categories. The notebook finds no detectable differences between them.
