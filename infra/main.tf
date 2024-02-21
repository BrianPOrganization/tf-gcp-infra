resource "google_compute_network" "vpc_list" {
  count                           = length(var.vpc_list)
  name                            = var.vpc_list[count.index]
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = var.routing_mode
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "webapp-${count.index}"
  ip_cidr_range = var.webapp_cidr_range
  count         = length(var.vpc_list)
  network       = google_compute_network.vpc_list[count.index].name
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "db-${count.index}"
  ip_cidr_range = var.db_cidr_range
  count         = length(var.vpc_list)
  network       = google_compute_network.vpc_list[count.index].name
}

resource "google_compute_route" "webapp_route" {
  dest_range       = "0.0.0.0/0"
  name             = "webapp-route-${count.index}"
  count            = length(var.vpc_list)
  network          = google_compute_network.vpc_list[count.index].name
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_firewall" "vpc_firewall" {
  name    = "webapp-firewall-${count.index}"
  count   = length(var.vpc_list)
  network = google_compute_network.vpc_list[count.index].name
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "no_ssh" {
  name    = "no-ssh-${count.index}"
  count   = length(var.vpc_list)
  network = google_compute_network.vpc_list[count.index].name
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "webapp_instance" {
  machine_type = var.machine_type
  count        = length(var.vpc_list)
  name         = "webapp-instance-${count.index}"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.image
      type  = var.image_type
      size  = var.image_size
    }
  }
  network_interface {
    network    = google_compute_network.vpc_list[count.index].name
    subnetwork = google_compute_subnetwork.webapp_subnet[count.index].name
    access_config {}
  }
}

