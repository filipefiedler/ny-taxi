#!/usr/bin/env python3
import pandas as pd
import requests
import json
import sys

def predict_from_csv(csv_file, model_url, output_file=None):
    """
    Read CSV file and make predictions using TensorFlow Serving
    """
    # Read CSV file
    df = pd.read_csv(csv_file)
    
    # Ensure required columns exist
    required_cols = ['passenger_count', 'trip_distance', 'PULocationID', 
                     'DOLocationID', 'payment_type', 'fare_amount', 'tolls_amount']
    
    for col in required_cols:
        if col not in df.columns:
            print(f"Error: Missing required column: {col}")
            sys.exit(1)
    
    # Convert DataFrame to list of instances
    instances = []
    for _, row in df.iterrows():
        instance = {
            "passenger_count": int(row['passenger_count']) if pd.notna(row['passenger_count']) else 0,
            "trip_distance": float(row['trip_distance']),
            "PULocationID": str(int(row['PULocationID'])) if pd.notna(row['PULocationID']) else "0",
            "DOLocationID": str(int(row['DOLocationID'])) if pd.notna(row['DOLocationID']) else "0",
            "payment_type": str(int(row['payment_type'])) if pd.notna(row['payment_type']) else "0",
            "fare_amount": float(row['fare_amount']),
            "tolls_amount": float(row['tolls_amount'])
        }
        instances.append(instance)
    
    # Make prediction request
    headers = {"Content-Type": "application/json"}
    payload = {"instances": instances}
    
    r = requests.post(model_url, headers=headers, json=payload)
    r.raise_for_status()
    
    # Print raw response
    print(json.dumps(r.json(), indent=2))
    
    # Extract predictions
    predictions = r.json()
    if 'predictions' in predictions:
        pred_values = predictions['predictions']
        df['predicted_tip'] = [p[0] if isinstance(p, list) else p for p in pred_values]
    else:
        print("Error: Unexpected response format")
        sys.exit(1)
    
    # Display results
    print("\n=== Predictions ===")
    print(df[['passenger_count', 'trip_distance', 'fare_amount', 'predicted_tip']].to_string())
    
    # Save to file if specified
    if output_file:
        df.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")
    
    return df

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python predict_from_csv.py <csv_file> [output_file] [model_url]")
        print("Example: python predict_from_csv.py taxi_data_sample_yellow.csv predictions_yellow.csv")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Default to yellow taxi model
    model_url = sys.argv[3] if len(sys.argv) > 3 else "http://localhost:8501/v1/models/tip_model_yellow:predict"
    
    predict_from_csv(csv_file, model_url, output_file)