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