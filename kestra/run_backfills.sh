echo -e "\n\nCreating trigger with backfill..."
curl -X PUT http://localhost:8080/api/v1/main/triggers \
  -u "admin@kestra.io:Admin1234" \
  -H "Content-Type: application/json" \
  -d '{
    "namespace": "ingestion",
    "flowId":    "gcp_taxi_scheduled_ingestion",
    "triggerId": "yellow_schedule",
    "backfill":  {
      "start": "2019-01-01T00:00:00Z",
      "end":   "2019-01-31T23:59:59Z",
      "labels": [
        {
          "key": "backfill",
          "value": "true"
        }
      ]
    }
  }' | jq '.'