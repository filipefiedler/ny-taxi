#!/bin/bash

# Remove any existing keys if necessary
# sudo rm -f /tmp/gcp-key-terraform.json
# sudo rm -f /tmp/gcp-key-kestra.json

echo $GCP_CREDENTIALS_TERRAFORM > /tmp/gcp-key-terraform.json
chmod 600 /tmp/gcp-key-terraform.json

echo $GCP_CREDENTIALS_KESTRA > /tmp/gcp-key-kestra.json
chmod 600 /tmp/gcp-key-kestra.json