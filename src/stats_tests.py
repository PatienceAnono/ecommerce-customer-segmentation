"""Hypothesis tests with effect sizes and Holm correction for multiple comparisons."""
import numpy as np
import pandas as pd
from scipy import stats


def kruskal_test(df, value, group):
    """Kruskal-Wallis (no normality assumption) with epsilon-squared effect size."""
    groups = [g[value].dropna().values for _, g in df.groupby(group)]
    h, p = stats.kruskal(*groups)
    n = sum(len(g) for g in groups)
    return {"test": "Kruskal-Wallis", "statistic": h, "p_value": p,
            "effect_size": h / (n - 1), "effect_measure": "epsilon_squared", "n": n}


def chi2_test(df, a, b):
    """Chi-square test of independence with Cramer's V; reports the smallest expected count."""
    table = pd.crosstab(df[a], df[b])
    chi2, p, dof, expected = stats.chi2_contingency(table)
    v = np.sqrt(chi2 / (table.values.sum() * (min(table.shape) - 1)))
    return {"test": "Chi-square", "statistic": chi2, "p_value": p, "effect_size": v,
            "effect_measure": "cramers_v", "n": int(table.values.sum()),
            "min_expected": float(expected.min())}


def holm(pvals):
    """Holm-Bonferroni adjusted p-values (controls family-wise error rate)."""
    p = np.asarray(pvals, dtype=float)
    order = np.argsort(p)
    m = len(p)
    adj = np.empty(m)
    running = 0.0
    for rank, i in enumerate(order):
        running = max(running, (m - rank) * p[i])
        adj[i] = min(1.0, running)
    return adj


def run_family(df, specs):
    """specs: list of (label, kind, x, y). kind is 'kruskal' (value x by group y) or 'chi2'."""
    rows = []
    for label, kind, x, y in specs:
        r = kruskal_test(df, x, y) if kind == "kruskal" else chi2_test(df, x, y)
        r["comparison"] = label
        rows.append(r)
    out = pd.DataFrame(rows).set_index("comparison")
    out["p_holm"] = holm(out["p_value"])
    out["significant_at_0.05_after_holm"] = out["p_holm"] < 0.05
    return out
