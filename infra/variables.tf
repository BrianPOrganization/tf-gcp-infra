variable "vpc_list" {
  description = "List of VPCs to be created"
  type        = list(string)
  default     = ["vpc-1", "vpc-2", "vpc-3", "vpc-4"]
}

variable "webapp_cidr_range" {
  description = "CIDR range for the webapp"
  type        = string
  default     = "10.168.0.0/24"
}

variable "db_cidr_range" {
  description = "CIDR range for the webapp"
  type        = string
  default     = "10.168.1.0/24"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east1-c"
}

variable "project" {
  description = "GCP project"
  type        = string
  default     = "brian-csye6225"
}

variable "routing_mode" {
  description = "Routing mode"
  type        = string
  default     = "REGIONAL"
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "n1-standard-1"
}

variable "image" {
  description = "Custom Image"
  type        = string
  default     = "packer-1708537706"
}

variable "image_size" {
  description = "Image size"
  type        = number
  default     = 100
}

variable "image_type" {
  description = "Image type"
  type        = string
  default     = "pd-balanced"
}

variable "database_version" {
  description = "Database version"
  type        = string
  default     = "MYSQL_8_0_36"
}

variable "database_tier" {
  description = "Database tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_disk_size" {
  description = "Database disk size"
  type        = number
  default     = 100
}

variable "database_disk_type" {
  description = "Database disk type"
  type        = string
  default     = "PD_SSD"
}

variable "database_availability_type" {
  description = "Database availability type"
  type        = string
  default     = "REGIONAL"
}

variable "database_deletion_protection" {
  description = "Database deletion protection"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "brianmarcelpatrao.me."
}

variable "zone_name" {
  description = "Zone name"
  type        = string
  default     = "brian-zone"
}

variable "ttl" {
  description = "TTL"
  type        = number
  default     = 30
}

variable "cloud_function_name" {
  description = "Cloud function name"
  type        = string
  default     = "email_subscription"
}

variable "cloud_function_entrypoint" {
  description = "Cloud function entrypoint"
  type        = string
  default     = "gcfv2pubsub.PubSubFunction"
}

variable "cloud_function_runtime" {
  description = "Cloud function runtime"
  type        = string
  default     = "java17"
}

variable "cloud_storage_bucket" {
  description = "Cloud storage bucket"
  type        = string
  default     = "csy6225-bucket"
}

variable "cloud_storage_bucket_object" {
  description = "Cloud storage bucket object"
  type        = string
  default     = "serverlesszip.zip"
}

variable "cloud_function_event_trigger" {
  description = "Cloud function event trigger"
  type        = string
  default     = "google.cloud.pubsub.topic.v1.messagePublished"
}

variable "cloud_function_retry_policy" {
  description = "Cloud function retry policy"
  type        = string
  default     = "RETRY_POLICY_RETRY"
}

variable "cloud_function_available_memory" {
  description = "Cloud function available memory"
  type        = string
  default     = "256M"
}

variable "cloud_function_timeout" {
  description = "Cloud function timeout"
  type        = number
  default     = 60
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "vpc_connector_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.8.0.0/28"
}

variable "vpc_connector_name" {
  description = "VPC connector name"
  type        = string
  default     = "vpc-connector"
}