.PHONY: start check stop restart logs clean

start:
	@echo "Setting up GCP credentials..."
	@bash utils/set_keys.sh
	@echo "✅ GCP credentials set!"
	@echo "Setting up infrastructure with Terraform..."
	@echo "Checking Terraform installation..."
	@bash terraform/install_terraform.sh
	@echo "Initializing Terraform..."
	@cd terraform && terraform init
	@echo "Applying Terraform configuration..."
	@terraform apply -auto-approve
	@echo "✅ Infrastructure is set up!"
	@cd ..
	@echo "Starting Docker Compose..."
	@docker compose up -d
	@echo "✅ Services started!"
	@echo "Waiting for Kestra to be ready..."
	@until curl -s -u "admin@kestra.io:Admin1234" http://localhost:8080/api/v1/configs > /dev/null 2>&1; do \
		echo "  Still waiting..."; \
		sleep 5; \
	done
	@echo "✅ Kestra is ready!"
	@echo "Setting keys in Kestra..."
	@bash kestra/run_set_kvs.sh
	@echo "Uploading gcp_taxi flow to Kestra..."
	@bash kestra/run_gcp_taxi.sh
	@echo "Files are being uploaded to GCP... This may take a few minutes."


run-backfills:
	@bash kestra/run_backfills.sh

check:
# Check if last execution was successful and print the execution file name
	@bash check_last_execution.sh

stop:
	@docker compose down

restart: stop start

logs:
	@docker compose logs -f

clean:
	@docker compose down -v
	@docker system prune -f
