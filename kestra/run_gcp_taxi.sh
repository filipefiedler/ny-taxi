#!/bin/bash

echo "Uploading/updating gcp_taxi flow to Kestra..."
curl -X PUT "http://localhost:8080/api/v1/flows/ingestion/gcp_taxi_scheduled_ingestion" \
  -H "Content-Type: application/x-yaml" \
  -u "admin@kestra.io:Admin1234" \
  --data-binary @/workspaces/ny-taxi/kestra/gcp_taxi.yaml

echo -e "\n\nStarting backfill ingestion for green taxi (2024)..."
echo "Note: Backfill via API endpoint not available in this Kestra version."
echo "Please use the UI to trigger backfill:"
echo "1. Go to: http://localhost:8080/ui/main/flows/ingestion/gcp_taxi_scheduled_ingestion"
echo "2. Click on 'Triggers' tab"
echo "3. Click the backfill icon next to 'green_schedule'"
echo "4. Set date range: 2024-01-01 to 2024-12-31"
echo "5. Add label: backfill=true"
echo "6. Click 'Backfill'"

echo -e "\n\nAlternatively, execute a single run:"
curl -X POST "http://localhost:8080/api/v1/main/executions/ingestion/gcp_taxi_scheduled_ingestion" \
  -H "Content-Type: application/json" \
  -u "admin@kestra.io:Admin1234" \
  -d '{"inputs": {"taxi": "green"}}'

echo -e "\n\nDone! Check executions in UI:"
echo "http://localhost:8080/ui/main/executions/ingestion/gcp_taxi_scheduled_ingestion"