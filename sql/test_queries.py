"""Load the export into an in-memory SQLite database, run schema.sql and analysis_queries.sql,
and check the SQL results against reports/metrics.json.  Usage (from repo root):  python sql/test_queries.py
"""
import json
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
con = sqlite3.connect(":memory:")
con.executescript((ROOT / "sql" / "schema.sql").read_text())

data = pd.read_csv(ROOT / "data" / "processed" / "customer_segments.csv")
cols = [c.lower() for c in data.columns]
data.columns = cols
for c in ["age_imputed", "age_under_18", "newer_customer"]:
    data[c] = data[c].astype(int)
data.to_sql("customer_segments", con, if_exists="append", index=False)

statements = [s.strip() for s in (ROOT / "sql" / "analysis_queries.sql").read_text().split(";") if "SELECT" in s.upper()]
results = [pd.read_sql_query(s, con) for s in statements]
for i, r in enumerate(results, 1):
    print(f"--- query {i} ---\n{r.head(10).to_string(index=False)}\n")

m = json.loads((ROOT / "reports" / "metrics.json").read_text())
overview = results[0].iloc[0]
assert overview["customers"] == m["customers"]
assert abs(overview["total_revenue_uncapped"] - m["behaviour"]["total_revenue_uncapped"]) < 0.01
assert abs(overview["aov_order_weighted"] - m["behaviour"]["aov_order_weighted"]) < 0.01
assert abs(overview["aov_mean_of_customer_aov"] - m["behaviour"]["aov_mean_of_customer_aov"]) < 0.01
assert overview["churn_score_ge_070"] == m["churn"]["high_churn_count"]
assert abs(results[3].iloc[0, 0] - round(100 * m["concentration"]["top_20pct_revenue_share"], 1)) < 0.11
seg = results[1].set_index("segment")["customers"].to_dict()
assert seg == {p["segment"]: p["customers"] for p in m["segment_profiles"]}
print("All SQL results match reports/metrics.json")
