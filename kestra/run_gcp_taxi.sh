#!/bin/bash

echo "Uploading/updating gcp_taxi flow to Kestra..."
curl -X POST "http://localhost:8080/api/v1/main/flows" \
  -H "Content-Type: application/x-yaml" \
  -u "admin@kestra.io:Admin1234" \
  --data-binary @/workspaces/ny-taxi/kestra/gcp_taxi.yaml | jq '.'