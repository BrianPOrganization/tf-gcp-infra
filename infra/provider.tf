terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~>4"
    }
  }
}

provider "google" {
  # project id
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
