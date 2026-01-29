# NYC Taxi Tips (BigQuery ML + Kestra + Terraform + TF Serving)

This repository contains an end-to-end example of a simple ML workflow using a large public dataset (NYC TLC trips) and a lightweight serving setup. It includes:
- ingestion of NYC TLC data into BigQuery via Kestra,
- model training in BigQuery ML (target: **tip amount**),
- exporting the trained model to a TensorFlow SavedModel format,
- local serving with TensorFlow Serving (Docker),
- infrastructure setup with Terraform (BigQuery + GCS).

The exported models are included in `serving_dir/`, so you can run the local serving demo without retraining.

---

## What’s in here (high level)

**Pipeline**
1. **Terraform** provisions GCS + BigQuery resources.
2. **Kestra** ingests NYC TLC data (GCS → BigQuery).
3. **BigQuery ML** trains a tip-amount model on the BigQuery table.
4. **Export script** saves the trained model into `serving_dir/`.
5. **TensorFlow Serving** serves the SavedModel locally over HTTP.

**Data scale (full run)**
- Rows: **132 million**
- Size: **28 GB**

---

## Quickstart (no GCP, no training)

This runs the already-exported model in `serving_dir/` and sends a prediction request.

### Requirements
- Docker

### Serve the model (yellow)
```bash
docker pull tensorflow/serving

docker run -d --name tf_serving_yellow   -p 8501:8501   --mount type=bind,source=$(pwd)/serving_dir/tip_model_yellow,target=/models/tip_model_yellow   -e MODEL_NAME=tip_model_yellow   -t tensorflow/serving
```

### Test with a single request
```bash
curl -d '{"instances": [{"passenger_count":1, "trip_distance":12.2, "PULocationID":"193", "DOLocationID":"264", "payment_type":"2","fare_amount":20.4,"tolls_amount":0.0}]}'   -X POST http://localhost:8501/v1/models/tip_model_yellow:predict
```

### Predict from the sample CSV
```bash
bash example/create_predictions.sh
```

### Stop / clean up local container
```bash
docker rm -f tf_serving_yellow
```

---

## Model Details

### Model Type
**Linear Regression** (BigQuery ML `LINEAR_REG`)

### Target Variable
- `tip_amount` (FLOAT64) - The tip amount in USD paid by the passenger

### Input Features (Predictors)
The model uses 7 features from NYC TLC trip records:

| Feature | Type | Description |
|---------|------|-------------|
| `passenger_count` | INTEGER | Number of passengers in the vehicle |
| `trip_distance` | FLOAT64 | Trip distance in miles |
| `PULocationID` | STRING | Pickup location ID (TLC Taxi Zone) |
| `DOLocationID` | STRING | Dropoff location ID (TLC Taxi Zone) |
| `payment_type` | STRING | Payment method (1=Credit card, 2=Cash, etc.) |
| `fare_amount` | FLOAT64 | Base fare amount in USD |
| `tolls_amount` | FLOAT64 | Total tolls paid during the trip |

### Data Preprocessing
- **Filtering**: Removes records where `fare_amount = 0` or `tip_amount IS NULL`
- **Type Casting**: Location IDs and payment type are cast to STRING for categorical encoding
- **Train/Test Split**: `AUTO_SPLIT` (BigQuery ML automatically splits data ~80/20)

### Model Performance
Model evaluation is produced by BigQuery ML during training:

| Model | RMSE | MAE | Dataset Size | Records |
|-------|------|-----|--------------|---------|
| Yellow Taxi | 10.1751 | 1.0846 | 27.8 GB | ~124M rows |
| Green Taxi | 3.5716 | 0.8853 | 1.8 GB | ~8M rows |

**Note**: RMSE is higher for yellow taxis due to greater variance in tip amounts across diverse trip patterns and zones.

### Model Variants
- **tip_model_yellow** - Trained on yellow taxi trips
- **tip_model_green** - Trained on green taxi trips  
- **tip_model_green_hyperparam** - Green taxi elastic net model with hyperparameter tuning 

---

## Full replication (GCP + Terraform + Kestra + BigQuery ML)

This reproduces the ingestion + training workflow. It assumes you have a GCP project and permissions to create resources.

### Requirements
- Docker + Docker Compose
- Terraform
- A GCP project

### 1) Set up GCP authentication (Codespaces-friendly)
1. Create a GCP project.
2. Create a **Terraform service account** with permissions to create/manage:
   - BigQuery datasets/tables
   - GCS buckets/objects
3. Create a **Kestra service account** with permissions to:
   - read/write to the relevant GCS bucket(s)
   - run BigQuery load jobs / queries

> Note: This repo uses broad roles in places to keep setup simple. A “least privilege” version is listed under **Next improvements**.

4. Save keys in GitHub Codespaces secrets:
   - `GCP_CREDENTIALS_TERRAFORM`
   - `GCP_CREDENTIALS_KESTRA`
5. Write the credentials to temp files and set permissions:
```bash
bash utils/set_keys.sh
```

### 2) Provision infrastructure with Terraform
1. Install Terraform (if needed):
```bash
bash terraform/install_terraform.sh
```

2. Update your GCP project ID in:
- `terraform/variables.tf`

3. Run Terraform:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3) Run Kestra locally
```bash
docker-compose up -d
```

Then, in the Kestra UI:
1. Create a new flow and paste `kestra/gcp_taxi.yaml`.
2. Trigger a backfill to ingest a date range (e.g., multiple months) for both taxi types (`yellow`, `green`).

*(Automation of flow deployment is listed under “Next improvements.”)*

### 4) Train the model in BigQuery ML
Run the SQL in:
- `bigquery/create_model_yellow.sql`
- `bigquery/create_model_green.sql`

### 5) Export the trained model into `serving_dir/`
1. Install gcloud SDK (if needed):
```bash
bash bigquery/install_gcsdk.sh
```

2. Set gcloud config:
- Edit `bigquery/settings_gcc.sh` with your project ID, then run:
```bash
bash bigquery/settings_gcc.sh
```

3. Export models:
```bash
bash bigquery/set_models.sh
```

### 6) Serve locally (same as Quickstart)
Use the **Quickstart** instructions above.

---

## Repository structure

- `terraform/` – GCS + BigQuery infrastructure
- `kestra/` – flows and helper scripts for ingestion/orchestration
- `bigquery/` – BigQuery ML training + export scripts
- `serving_dir/` – exported SavedModel artifacts (checked into git)
- `example/` – example CSV + scripts to request predictions
- `utils/` – local helper scripts (e.g., writing credentials files)

---

## Notes on cost
This is intended as a low-cost demo. BigQuery and GCS may incur small charges depending on your usage and free tier status.

---

## Next improvements (planned)
- **Reduce IAM permissions** (replace broad roles with least-privilege roles for:
  - Terraform SA (only what’s needed for GCS + BigQuery provisioning)
  - Kestra SA (only what’s needed for GCS read/write + BigQuery jobs))
- **Automate Kestra flow deployment** (import flows via Kestra API instead of pasting YAML in the UI)
- **One-command reproducibility** (single `make` or `task` entry point to:
  - provision infra → start Kestra → deploy flows → backfill → train → export → serve)
- **Documentation polish**
  - add a small architecture diagram image
  - add a short “troubleshooting” section (common auth/permission issues)
---

## Acknowledgements
This project was developed as part of the DataTalksClub Data Engineering Zoomcamp (workflow orchestration / GCP modules), with modifications for a complete “train → export → serve” example.
Thanks to the DataTalksClub community for inspiration and feedback!