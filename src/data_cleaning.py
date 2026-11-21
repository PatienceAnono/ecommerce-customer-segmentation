"""Load and clean the raw customer file. Every change is logged and flagged per row."""
import numpy as np
import pandas as pd

from .config import ANALYSIS_DATE, RAW_PATH

GENDER_MAP = {"M": "Male", "F": "Female", "Male": "Male", "Female": "Female"}


def load_raw(path=RAW_PATH):
    return pd.read_csv(path)


def quality_report(raw):
    """Facts about the raw file, before any cleaning."""
    ref = pd.to_datetime(raw["last_purchase_date"]) + pd.to_timedelta(raw["recency_days"], unit="D")
    return {
        "rows": len(raw),
        "columns": raw.shape[1],
        "exact_duplicate_rows": int(raw.duplicated().sum()),
        "duplicate_customer_ids": int(raw["customer_id"].duplicated().sum()),
        "missing_gender": int(raw["gender"].isna().sum()),
        "missing_age": int(raw["age"].isna().sum()),
        "missing_frequency": int(raw["frequency"].isna().sum()),
        "zero_frequency_with_spend": int(((raw["frequency"] == 0) & (raw["monetary_value"] > 0)).sum()),
        "age_under_18": int((raw["age"] < 18).sum()),
        "signup_after_last_purchase": int((pd.to_datetime(raw["signup_date"]) > pd.to_datetime(raw["last_purchase_date"])).sum()),
        "recency_reference_dates": sorted(ref.dt.strftime("%Y-%m-%d").unique().tolist()),
        "monetary_max": float(raw["monetary_value"].max()),
        "monetary_skew": round(float(raw["monetary_value"].skew()), 2),
    }


def clean(raw):
    """Return (clean_df, log). The raw frame is never modified."""
    df = raw.copy()
    log = []

    def note(step, rows, detail):
        log.append({"step": step, "rows_affected": int(rows), "detail": detail})

    n = len(df)
    df = df.drop_duplicates().reset_index(drop=True)
    note("Drop exact duplicate rows", n - len(df), "Every duplicated customer_id was an exact copy")
    assert df["customer_id"].is_unique

    unknown = df["gender"].isna().sum()
    df["gender"] = df["gender"].map(GENDER_MAP).fillna("Unknown")
    note("Standardise gender", unknown, "M/F mapped to Male/Female; missing kept as 'Unknown' (not imputed)")

    df["preferred_category"] = df["preferred_category"].str.strip().str.title()
    note("Standardise category case", 0, "Title case")

    df["signup_date"] = pd.to_datetime(df["signup_date"])
    df["last_purchase_date"] = pd.to_datetime(df["last_purchase_date"])
    df["tenure_days"] = (ANALYSIS_DATE - df["signup_date"]).dt.days
    note("Parse dates, derive tenure_days", 0, f"Reference date {ANALYSIS_DATE.date()}")

    # Zero orders with recorded spend and a purchase date is impossible.
    df["frequency_flag"] = "observed"
    zero = (df["frequency"] == 0) & (df["monetary_value"] > 0)
    df.loc[zero, "frequency_flag"] = "zero_with_spend_set_to_1"
    df.loc[zero, "frequency"] = 1
    note("Correct impossible frequency", zero.sum(),
         "frequency 0 with spend > 0 set to 1 (minimum consistent value) and flagged")

    missing_f = df["frequency"].isna()
    median_f = df.loc[~missing_f, "frequency"].median()
    df.loc[missing_f, "frequency_flag"] = "imputed_median"
    df.loc[missing_f, "frequency"] = median_f
    note("Impute missing frequency", missing_f.sum(), f"Median of observed values ({median_f:.0f}); flagged")
    df["frequency"] = df["frequency"].astype(int)

    missing_age = df["age"].isna()
    df["age_imputed"] = missing_age
    df["age"] = df["age"].fillna(df["age"].median()).round().astype(int)
    note("Impute missing age", missing_age.sum(), "Median; flagged. Age is not used for segmentation")

    df["age_under_18"] = df["age"] < 18
    note("Flag customers under 18", df["age_under_18"].sum(), "Kept; flagged for marketing-consent review")

    # Spend: uncapped value for every revenue figure; log transform for modelling (no winsorising).
    df["log_monetary"] = np.log1p(df["monetary_value"])
    note("Add log1p(monetary_value)", 0,
         "Used for clustering instead of a 99th-percentile cap; revenue always uses uncapped spend")

    # Average order value only where the order count was actually observed.
    df["aov"] = np.where(df["frequency_flag"] == "observed", df["monetary_value"] / df["frequency"], np.nan)
    note("Derive average order value", (df["frequency_flag"] != "observed").sum(),
         "AOV = spend / orders; left blank where frequency was corrected or imputed")

    return df, pd.DataFrame(log)
