CSV_FILE=${1:-/workspaces/ny-taxi/example/taxi_data_sample_yellow.csv}
OUTPUT_FILE=${2:-/workspaces/ny-taxi/example/predictions_yellow.csv}
MODEL_URL=${3:-http://localhost:8501/v1/models/tip_model_yellow:predict}

echo "Processing CSV file: $CSV_FILE"
echo "Model URL: $MODEL_URL"
echo ""

# Check if Python script exists
if [ ! -f /workspaces/ny-taxi/example/predict_from_csv.py ]; then
    echo "Error: predict_from_csv.py not found"
    exit 1
fi

# Install required Python packages if needed
pip install -q pandas requests

# Run prediction
python3 /workspaces/ny-taxi/example/predict_from_csv.py "$CSV_FILE" "$OUTPUT_FILE" "$MODEL_URL"

echo ""
echo "Done!"