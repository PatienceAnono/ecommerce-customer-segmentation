"""Project-wide constants. Every threshold used in the analysis lives here."""
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW_PATH = ROOT / "data" / "raw" / "customer_segmentation_dataset.csv"
CLEAN_PATH = ROOT / "data" / "cleaned" / "customer_segmentation_cleaned.csv"
PROCESSED_DIR = ROOT / "data" / "processed"
CHART_DIR = ROOT / "visuals" / "charts"
REPORT_TABLE_DIR = ROOT / "reports" / "tables"

# All recency values in the raw file are measured against this date
# (verified: last_purchase_date + recency_days == 2025-05-01 for every row).
ANALYSIS_DATE = pd.Timestamp("2025-05-01")
RANDOM_STATE = 42

# Rule-based segmentation thresholds (business-readable, fixed, not data-order dependent)
RECENCY_BANDS = [-1, 90, 180, 365, float("inf")]
RECENCY_LABELS = ["Active", "Cooling", "Lapsing", "Lapsed"]   # 0-90, 91-180, 181-365, >365 days
HIGH_VALUE_QUANTILE = 0.80        # top 20% of customers by total (uncapped) spend
NEWER_CUSTOMER_MAX_TENURE = 180   # days since signup; used as a flag, not a segment

# Frequency score bins (orders): 1 | 2 | 3-4 | 5-6 | 7+
FREQUENCY_BINS = [0, 1, 2, 4, 6, float("inf")]

HIGH_CHURN_THRESHOLD = 0.70
