# Executive Summary: Customer Segmentation (v2)

> **Synthetic data.** This analysis uses a simulated CRM dataset. It describes no real company, customers or results.

**Scope:** 1,000 customers (after removing duplicates), analysis date 2025-05-01. All figures are produced by
`notebooks/customer_segmentation.ipynb` and stored in `reports/metrics.json`.

## Findings

1. **Recency and spend are what differentiate customers.** Nothing else measured (order count, email open rate, acquisition channel,
   preferred category, country, gender, age) shows a detectable relationship with spend or with segment membership.
   That's 16 tests, none significant after Holm correction, and all effect sizes negligible.
2. **Revenue is moderately concentrated, and much of the top tier is inactive.**
   - The top 20% of customers by spend (>= $368.35) generated 46.2% of revenue.
   - 121 of those 200 customers have not bought in more than 180 days.
   - Those 121 represent 29.9% of all historical revenue. This is the clearest priority in the data.
3. **Order value varies more than order count.**
   - The order-weighted AOV is $64.50; the mean of each customer's AOV is $85.22.
   - High-Value customers have a median AOV of $111 to $205, versus about $40 to $43 for Standard customers, while median order counts are similar (3 to 4).
   - High value comes from larger baskets, not more frequent purchases.
4. **The supplied churn score adds no information beyond recency.**
   - 53.9% of customers have a score of 0.70 or higher.
   - The score has a rank correlation of 0.95 with days since last purchase, and recency alone explains 93% of its variance.
   - It is treated as descriptive only and is not used for segmentation.
5. **Clustering does not find natural segments.** K-Means solutions are no better separated than shuffled data, and they reduce to simple
   threshold rules. The segmentation therefore uses transparent rules instead.

## Segments

| Segment | Customers | % revenue | Median days since purchase | Median spend |
|---|---|---|---|---|
| Active High-Value | 38 | 7.8% | 54 | $471.97 |
| Active Standard | 191 | 12.5% | 50 | $164.58 |
| Cooling High-Value | 41 | 8.6% | 139 | $480.89 |
| Cooling Standard | 199 | 13.3% | 128 | $160.04 |
| Lapsing High-Value | 66 | 14.3% | 255 | $466.96 |
| Lapsing Standard | 217 | 15.0% | 256 | $166.84 |
| Lapsed High-Value | 55 | 15.5% | 500 | $516.28 |
| Lapsed Standard | 193 | 13.0% | 478 | $162.88 |

Recency bands: Active 0-90 days · Cooling 91-180 · Lapsing 181-365 · Lapsed over 365.
High-Value: top 20% by total spend.

## Recommended next steps

These are tests to run, not forecasts. The data contains no costs or campaign results, so no revenue impact is claimed.

1. **Win-back test for the 121 Lapsing and Lapsed High-Value customers.** Use a randomised holdout and measure reactivation and spend.
2. **Retention for the 79 Active and Cooling High-Value customers.** Use service and recognition rather than discounts, and monitor whether they move into the Lapsing band.
3. **Timed reminders at 90-180 days** for Cooling Standard customers.
4. **Sunset rule for Lapsed Standard customers** after a single low-cost reactivation attempt.
5. **Consent review.** 75 customers are recorded as under 18, including 19 High-Value customers. Check them before any campaign.
6. **Data to collect next:** order-level transactions, margins, campaign costs and responses, and a churn definition based on observed outcomes.

## What changed from v1

v1 reported several figures and claims that did not hold up. These have been corrected or removed:
- AOV of $253 (that was average total spend per customer).
- 64% "high churn risk" (the correct figure is 53.9%).
- A $799 spend cap (the cap was actually $1,315; it has now been removed).
- "Loyal Customers" who mostly had not bought for over 180 days.
- "New Customers" with a median tenure of 334 days.
- Channel and category recommendations not supported by the data.

See `reports/audit_log.md`.
