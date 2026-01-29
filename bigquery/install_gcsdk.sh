#!/bin/bash

# Download the package to /tmp
cd /tmp
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz

# Extract it to /usr/local
sudo tar -xf google-cloud-cli-linux-x86_64.tar.gz -C /usr/local

# Install it non-interactively
sudo /usr/local/google-cloud-sdk/install.sh --quiet --usage-reporting=false --path-update=true

# Add to PATH for current session
export PATH=$PATH:/usr/local/google-cloud-sdk/bin

# Add to shell profile permanently
echo 'export PATH=$PATH:/usr/local/google-cloud-sdk/bin' >> ~/.bashrc

# Clean up download
rm google-cloud-cli-linux-x86_64.tar.gz

echo "Google Cloud SDK installed to /usr/local/google-cloud-sdk"
echo "Run 'source ~/.bashrc' or restart your terminal to use gcloud/bq commands"