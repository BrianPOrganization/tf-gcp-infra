resource "google_compute_network" "vpc_list" {
  count                           = length(var.vpc_list)
  name                            = var.vpc_list[count.index]
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = var.routing_mode
}

resource "google_dns_record_set" "dns_record" {
  count = length(var.vpc_list)
  name = var.domain_name
  type = "A"
  ttl  = var.ttl
  managed_zone = var.zone_name
  rrdatas = [google_compute_instance.webapp_instance[count.index].network_interface[0].access_config[0].nat_ip]
}

resource "google_service_account" "service_account" {
  account_id   = "csye6225-dev"
  display_name = "csye6225-dev"
  project = var.project
}

resource "google_project_iam_binding" "logging_admin" {
  project = var.project
  role    = "roles/logging.admin"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

resource "google_project_iam_binding" "monitring_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
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
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-sql-webapp-conn" {
  name    = "allow-sql-webapp-conn-${count.index}"
  count   = length(var.vpc_list)
  network = google_compute_network.vpc_list[count.index].name
  allow {
      protocol = "tcp"
      ports    = ["3306"]
  }
  source_ranges = [google_compute_instance.webapp_instance[count.index].network_interface[0].network_ip]
  destination_ranges = ["${google_compute_global_address.private_ip_range[count.index].address}/${google_compute_global_address.private_ip_range[count.index].prefix_length}"]
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
  service_account {
    email  = google_service_account.service_account.email
    scopes = ["logging-write", "monitoring"]
  }
  metadata_startup_script = <<EOF
#!/usr/bin/bash
if [ ! -f "/opt/application/application.properties" ]; then
{
  echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.cloudsql_instance[count.index].private_ip_address}:3306/${google_sql_database.mysql_database[count.index].name}?createDatabaseIfNotExist=true"
  echo "spring.datasource.username=${google_sql_user.mysql_user[count.index].name}"
  echo "spring.datasource.password=${random_password.password.result}"
  echo "spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver"
  echo "spring.main.banner-mode=off"
  echo "spring.jpa.hibernate.ddl-auto=update"
  echo "spring.jpa.database=mysql"
  echo "spring.jpa.show-sql=true"
  echo "server.servlet.context-path=/"
} >> /opt/application/application.properties
fi
if [ ! -f "/opt/application/application-test.properties" ]; then
{
  echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.cloudsql_instance[count.index].private_ip_address}:3306/test?createDatabaseIfNotExist=true"
  echo "spring.datasource.username=${google_sql_user.mysql_user[count.index].name}"
  echo "spring.datasource.password=${random_password.password.result}"
  echo "spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver"
  echo "spring.main.banner-mode=off"
  echo "spring.jpa.hibernate.ddl-auto=create"
  echo "spring.jpa.database=mysql"
  echo "spring.jpa.show-sql=true"
  echo "logging.level.org.springframework.boot.test.context.SpringBootTestContextBootstrapper=WARN"
  echo "logging.level.org.springframework.context.support.AbstractContextLoader=WARN"
  echo "logging.level.org.springframework.context.support.AnnotationConfigContextLoaderUtils=WARN"
} >> /opt/application/application-test.properties
fi
sudo chown csye6225:csye6225 /opt/application/application.properties
sudo chown csye6225:csye6225 /opt/application/application-test.properties
sudo chmod 440 /opt/application/application.properties
sudo chmod 440 /opt/application/application-test.properties
touch test.txt
EOF
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  count                   = length(var.vpc_list)
  network                 = google_compute_network.vpc_list[count.index].self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[count.index].name]
}

resource "google_compute_global_address" "private_ip_range" {
  provider      = google-beta
  count         = length(var.vpc_list)
  name          = "private-ip-range-${count.index}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_list[count.index].self_link
}

resource "google_sql_database_instance" "cloudsql_instance" {
  count               = length(var.vpc_list)
  name                = "mysql-instance-${count.index}"
  project             = var.project
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.database_deletion_protection
  settings {
    tier              = var.database_tier
    availability_type = var.database_availability_type
    disk_type         = var.database_disk_type
    disk_size         = var.database_disk_size
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_list[count.index].self_link
    }
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
    }
  }
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "mysql_database" {
  count    = length(var.vpc_list)
  name     = "webapp-${count.index}"
  instance = google_sql_database_instance.cloudsql_instance[count.index].name
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "mysql_user" {
  count    = length(var.vpc_list)
  name     = "webapp-${count.index}"
  instance = google_sql_database_instance.cloudsql_instance[count.index].name
  password = random_password.password.result
}

