
import pandas as pd

def create_recency(df):
    reference_date = df['last_purchase_date'].max()
    df['recency'] = (reference_date - df['last_purchase_date']).dt.days
    return df

def create_monetary(df):
    df['monetary'] = df['monetary_value']
    return df
