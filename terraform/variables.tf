variable "credentials" {
    description = "My GCP Credentials"
    default     = "/tmp/gcp-key.json"
}

variable "project" {
    description = "Project"
    default     = "ny-taxi-485717"
}

variable "region" {
    description = "Region"
    #Update the below to your desired region
    default     = "us-central1"
}

variable "location" {
    description = "Project Location"
    #Update the below to your desired location
    default     = "us-central1"
}

variable "bq_dataset_name" {
    description = "My BigQuery Dataset Name"
    #Update the below to what you want your dataset to be called
    default     = "ny_taxi_data"
}

variable "gcs_bucket_name" {
    description = "My Storage Bucket Name"
    #Update the below to a unique bucket name
    default     = "ny-taxi-485717-bucket"
}

variable "gcs_storage_class" {
    description = "Bucket Storage Class"
    default     = "STANDARD"
}