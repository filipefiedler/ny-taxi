
# Move models to bucket
bq --project_id ny-taxi-485717 extract -m ny_taxi_data.tip_model gs://ny-taxi-485717-bucket/tip_model_green
bq --project_id ny-taxi-485717 extract -m ny_taxi_data.tip_hyperparam_model gs://ny-taxi-485717-bucket/tip_model_green_hyperparam
bq --project_id ny-taxi-485717 extract -m ny_taxi_data.tip_model_yellow gs://ny-taxi-485717-bucket/tip_model_yellow

# Copy models locally
mkdir /tmp/models
gsutil cp -r gs://ny-taxi-485717-bucket/tip_model_green /tmp/models
gsutil cp -r gs://ny-taxi-485717-bucket/tip_model_green_hyperparam /tmp/models
gsutil cp -r gs://ny-taxi-485717-bucket/tip_model_yellow /tmp/models

# Create models directory if not exists
mkdir -p /workspaces/ny-taxi/serving_dir/tip_model_green/1
mkdir -p /workspaces/ny-taxi/serving_dir/tip_model_green_hyperparam/1
mkdir -p /workspaces/ny-taxi/serving_dir/tip_model_yellow/1

# Copy models from /tmp/models to serving directories
cp -r /tmp/models/tip_model_green/* /workspaces/ny-taxi/serving_dir/tip_model_green/1/
cp -r /tmp/models/tip_model_green_hyperparam/* /workspaces/ny-taxi/serving_dir/tip_model_green_hyperparam/1/
cp -r /tmp/models/tip_model_yellow/* /workspaces/ny-taxi/serving_dir/tip_model_yellow/1/