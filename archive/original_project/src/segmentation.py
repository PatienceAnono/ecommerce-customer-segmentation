
import pandas as pd

def build_rfm(df):
    rfm = df.groupby('customer_id').agg({
        'recency':'min',
        'frequency':'sum',
        'monetary':'sum'
    }).reset_index()
    return rfm

def assign_segment(score):
    if score in ['444','434','344']:
        return 'Champions'
    return 'Other'
