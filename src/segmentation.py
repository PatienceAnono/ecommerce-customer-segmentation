"""Deterministic RFM scoring and the rule-based segmentation used as the primary deliverable.

Also contains a faithful copy of the ORIGINAL segment rules (legacy_rfm_segments) so the
old results can be reproduced and compared. Do not use the legacy function for decisions.
"""
import numpy as np
import pandas as pd

from .config import (FREQUENCY_BINS, HIGH_VALUE_QUANTILE, NEWER_CUSTOMER_MAX_TENURE,
                     RECENCY_BANDS, RECENCY_LABELS)

SEGMENT_ORDER = [
    "Active High-Value", "Active Standard",
    "Cooling High-Value", "Cooling Standard",
    "Lapsing High-Value", "Lapsing Standard",
    "Lapsed High-Value", "Lapsed Standard",
]


def rfm_scores(df):
    """R, F, M scores (1-5) that depend only on each customer's values, never on row order.

    R: recency quintiles computed on the values (equal values always share a score).
    F: fixed order-count bins 1 | 2 | 3-4 | 5-6 | 7+ (frequency is discrete, so quantiles tie).
    M: quintiles of uncapped spend.
    """
    out = pd.DataFrame(index=df.index)
    out["R_score"] = pd.qcut(df["recency_days"], 5, labels=[5, 4, 3, 2, 1]).astype(int)
    out["F_score"] = pd.cut(df["frequency"], FREQUENCY_BINS, labels=[1, 2, 3, 4, 5]).astype(int)
    out["M_score"] = pd.qcut(df["monetary_value"], 5, labels=[1, 2, 3, 4, 5]).astype(int)
    out["RFM_code"] = out["R_score"].astype(str) + out["F_score"].astype(str) + out["M_score"].astype(str)
    return out


def assign_segments(df):
    """Rule-based segments = recency band x value tier, plus a newer-customer flag.

    Recency band: Active 0-90 days, Cooling 91-180, Lapsing 181-365, Lapsed >365.
    Value tier: High-Value = top 20% by total uncapped spend, otherwise Standard.
    """
    threshold = df["monetary_value"].quantile(HIGH_VALUE_QUANTILE)
    out = pd.DataFrame(index=df.index)
    out["recency_band"] = pd.cut(df["recency_days"], RECENCY_BANDS, labels=RECENCY_LABELS).astype(str)
    out["value_tier"] = np.where(df["monetary_value"] >= threshold, "High-Value", "Standard")
    out["segment"] = out["recency_band"] + " " + out["value_tier"]
    out["newer_customer"] = df["tenure_days"] <= NEWER_CUSTOMER_MAX_TENURE
    return out, float(threshold)


def legacy_rfm_segments(df, monetary_col="monetary_value"):
    """The original notebook's rules, reproduced exactly (including the row-order tie-break)."""
    r = pd.qcut(df["recency_days"], 5, labels=[5, 4, 3, 2, 1]).astype(int)
    f = pd.qcut(df["frequency"].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]).astype(int)
    m = pd.qcut(df[monetary_col].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]).astype(int)
    score = r + f + m

    def rule(rv, fv, mv, s):
        if rv >= 4 and fv >= 4 and mv >= 4:
            return "Champions"
        if fv >= 4 and mv >= 4:
            return "Loyal Customers"
        if rv <= 2 and fv >= 3:
            return "At Risk"
        if rv >= 4 and fv <= 2:
            return "New Customers"
        if s <= 6:
            return "Hibernating"
        return "Potential Loyalists"

    return pd.Series([rule(*v) for v in zip(r, f, m, score)], index=df.index, name="legacy_segment")


def order_sensitivity(df, assign_fn, n_shuffles=20, seed=0):
    """How many customers change label when ONLY the row order changes."""
    base = assign_fn(df)
    changes = []
    rng = np.random.default_rng(seed)
    for _ in range(n_shuffles):
        perm = rng.permutation(len(df))
        shuffled = df.iloc[perm].reset_index(drop=True)
        labels = pd.Series(assign_fn(shuffled).values, index=df.index[perm])
        changes.append(int((labels.reindex(df.index) != base).sum()))
    return changes


def profile(df, by="segment"):
    """Segment profile with medians (skewed variables) and revenue on uncapped spend."""
    total = df["monetary_value"].sum()
    g = df.groupby(by)
    prof = pd.DataFrame({
        "customers": g.size(),
        "share_of_customers_pct": g.size() / len(df) * 100,
        "revenue": g["monetary_value"].sum(),
        "revenue_share_pct": g["monetary_value"].sum() / total * 100,
        "median_recency_days": g["recency_days"].median(),
        "median_orders": g["frequency"].median(),
        "mean_orders": g["frequency"].mean(),
        "median_spend": g["monetary_value"].median(),
        "mean_spend": g["monetary_value"].mean(),
        "median_aov": g["aov"].median(),
        "median_tenure_days": g["tenure_days"].median(),
        "pct_newer_customers": g["tenure_days"].apply(lambda s: (s <= NEWER_CUSTOMER_MAX_TENURE).mean() * 100),
        "median_email_open_rate": g["email_open_rate"].median(),
        "median_churn_score": g["churn_risk_score"].median(),
    })
    return prof.round(2)
