echo "Fetching last execution..."

# Get the last execution
LAST_EXECUTION=$(curl -s -u "admin@kestra.io:Admin1234" \
  "http://localhost:8080/api/v1/main/executions/search?size=1&sort=state.startDate:DESC" | jq '.results[0]')

# Last processed file
FILE=$(echo "$LAST_EXECUTION" | jq -r '.labels[] | select(.key == "file") | .value')
echo "Last processed file: $FILE"

# Check if last_execution state is SUCCESS
STATE=$(echo "$LAST_EXECUTION" | jq -r '.state.current')
if [ "$STATE" != "SUCCESS" ]; then
  echo "Last execution state is not SUCCESS. Please check the execution logs."
else
  echo "Last execution was successful."
fi