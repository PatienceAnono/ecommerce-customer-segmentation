
import pandas as pd

def remove_duplicates(df):
    return df.drop_duplicates()

def handle_missing_values(df):
    df['age'] = df['age'].fillna(df['age'].median())
    df['frequency'] = df['frequency'].fillna(df['frequency'].median())
    return df

def standardize_categories(df):
    df['preferred_category'] = df['preferred_category'].str.strip().str.title()
    return df
