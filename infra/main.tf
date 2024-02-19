resource "google_compute_network" "vpc_list" 
  count                           = length(var.vpc_list)
  name                            = var.vpc_list[count.index]
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "REGIONAL"
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



