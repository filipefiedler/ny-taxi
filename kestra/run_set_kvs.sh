#!/bin/bash

echo "Uploading/updating flow to Kestra..."
curl -X PUT "http://localhost:8080/api/v1/flows/ingestion/set_gcp_kvs" \
  -H "Content-Type: application/x-yaml" \
  -u "admin@kestra.io:Admin1234" \
  --data-binary @/workspaces/ny-taxi/kestra/set_kvs.yaml

echo -e "\n\nExecuting flow..."
curl -X POST "http://localhost:8080/api/v1/main/executions/ingestion/set_gcp_kvs" \
  -u "admin@kestra.io:Admin1234"