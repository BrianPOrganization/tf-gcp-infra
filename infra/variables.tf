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