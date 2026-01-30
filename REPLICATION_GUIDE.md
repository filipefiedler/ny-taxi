# Full Replication Guide (GCP + Terraform + Kestra + BigQuery ML)

This reproduces the complete ingestion + training workflow using a single automated command.

## Requirements
- Docker + Docker Compose
- Make
- A GCP project with billing enabled

## 1) Set up GCP authentication (GitHub Codespaces)

### Create GCP Project
- Create a new GCP project or use an existing one
- Enable billing

### Create Service Accounts

**Terraform Service Account** - create/manage:
- BigQuery datasets/tables
- GCS buckets/objects

**Kestra Service Account** - permissions for:
- Read/write to GCS buckets
- Run BigQuery load jobs and queries

> **Note**: This repo uses broad roles to simplify setup. For production, use least-privilege principles.

### Save Credentials in GitHub Codespaces Secrets
- `GCP_CREDENTIALS_TERRAFORM` - JSON key for Terraform SA
- `GCP_CREDENTIALS_KESTRA` - JSON key for Kestra SA

### Update Configuration Files

**`kestra/set_kvs.yaml`**:
```yaml
value: your-project-id          # Replace with your project ID
value: your-bucket-name         # Replace with your bucket name
value: ny_taxi_data            # Your dataset name
```

**`docker-compose.yaml`** (lines 55-58):
```yaml
GCP_PROJECT_ID: your-project-id
GCP_LOCATION: us-central1
GCP_BUCKET_NAME: your-bucket-name
GCP_DATASET: ny_taxi
```

## 2) Run Complete Setup (One Command!)

```bash
make start
```

### What happens automatically:
1. ✅ Sets up GCP credentials from Codespaces secrets
2. ✅ Installs Terraform (if not already installed)
3. ✅ Initializes and applies Terraform (creates GCS bucket + BigQuery dataset)
4. ✅ Starts Docker Compose services (Kestra, PostgreSQL, pgAdmin)
5. ✅ Waits for Kestra to be ready with health checks
6. ✅ Configures Kestra with your GCP settings (KV store)
7. ✅ Uploads the `gcp_taxi_scheduled_ingestion` flow to Kestra

## 3) Trigger Data Ingestion

The flow is uploaded but needs to be triggered. Choose one of the following methods:

📅 **Available data**: January 2019 - July 2021  
📦 **File format**: `{taxi}_tripdata_YYYY-MM.csv.gz`

### Option A: Automatized Backfill (API for multiple months)
1. In `kestra/run_backfills.sh`, modify the `start_date` and `end_date` variables to specify the date range to ingest and the taxi type (`yellow` or `green`).
2. Run the script: `make run-backfills`. This might take some time depending on the date range.
3. Check if the ingestion completed successfully by runnin `make check` and verifying the last processed file.

### Option B: Manual Execution (UI)
1. Go to http://localhost:8080/ui/flows/ingestion/gcp_taxi_scheduled_ingestion
2. Go to triggers tab and click on backfill
3. Select taxi type: `green` or `yellow`
4. Monitor execution in real-time in the Executions tab

## 4) Train Model in BigQuery ML

Once data is loaded to BigQuery:

### Authenticate with GCP:
```bash
bash bigquery/install_gcsdk.sh
bash bigquery/settings_gcc.sh
```

### Run training SQL:

**Yellow taxi model:**
```bash
bq query --use_legacy_sql=false < bigquery/create_model_yellow.sql
```

**Green taxi model:**
```bash
bq query --use_legacy_sql=false < bigquery/create_model_green.sql
```

⏱️ **Training time**: ~5-10 minutes depending on data volume

### Evaluate model performance:
```sql
SELECT * FROM ML.EVALUATE(MODEL `your-project.ny_taxi_data.tip_model_yellow`)
```

## 5) Export Trained Model

Export to TensorFlow SavedModel format:

```bash
bash bigquery/set_models.sh
```

**Models exported to:**
- `serving_dir/tip_model_yellow/`
- `serving_dir/tip_model_green/`

## 6) Serve Locally

Use the **Quickstart** instructions in the main README to serve the exported model with TensorFlow Serving.

## Cleanup

```bash
# Stop containers (preserves data)
make stop

# Remove everything (deletes volumes)
make clean

# Destroy GCP infrastructure
cd terraform && terraform destroy
```

## Makefile Commands Reference

```bash
make start    # Complete setup (credentials + terraform + docker + kestra)
make check    # Check last execution status and processed file
make stop     # Stop all containers
make restart  # Stop then start
make logs     # Follow container logs
make clean    # Remove containers and volumes
```

## Troubleshooting

### Kestra connection issues:
```bash
# Check if Kestra is running
docker ps | grep kestra

# View Kestra logs
make logs

# Restart Kestra
docker compose restart kestra
```

### Authentication errors:
- Verify Codespaces secrets are set correctly: `echo $GCP_CREDENTIALS_KESTRA | head -c 50`
- Check service account has required permissions in GCP IAM
- Ensure billing is enabled on GCP project
- Verify credentials are valid JSON: `echo $GCP_CREDENTIALS_KESTRA | jq`

### Data ingestion failures:
- Check file availability at https://github.com/DataTalksClub/nyc-tlc-data/releases
- Verify GCS bucket exists: `gsutil ls gs://your-bucket-name`
- Confirm BigQuery dataset exists: `bq ls your-project:ny_taxi_data`
- Use `make check` to see last execution status
- View execution logs in Kestra UI

### Terraform errors:
- Check if resources already exist: `cd terraform && terraform state list`
- Verify service account permissions
- Check project quota limits

### Docker disk space issues:
```bash
# Check disk usage
df -h /workspaces

# Clean up Docker
docker system prune -a --volumes -f

# Remove orphaned volumes
docker volume prune -f
```

## Data Flow Architecture

```
GitHub Release (CSV.gz)
    ↓ wget + gunzip
Kestra Worker (local)
    ↓ upload
GCS Bucket
    ↓ load job
BigQuery Table
    ↓ SQL training
BigQuery ML Model
    ↓ export
TensorFlow SavedModel
    ↓ serve
TF Serving (HTTP)
```

## Next Steps

After successful replication:
1. Experiment with different date ranges
2. Try hyperparameter tuning (see `bigquery/create_model_green_hyperparam.sql`)
3. Compare yellow vs green taxi model performance
4. Create visualizations of predictions
5. Deploy to production with proper IAM and monitoring
