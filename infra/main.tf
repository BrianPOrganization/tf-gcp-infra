resource "google_compute_network" "vpc_list" {
  count                           = length(var.vpc_list)
  name                            = var.vpc_list[count.index]
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = var.routing_mode
}

resource "google_dns_record_set" "dns_record" {
  count        = length(var.vpc_list)
  name         = var.domain_name
  type         = "A"
  ttl          = var.ttl
  managed_zone = var.zone_name
  rrdatas      = [module.gce-lb-http[0].external_ip]
}

resource "google_service_account" "service_account" {
  account_id   = "csye6225-dev"
  display_name = "csye6225-dev"
  project      = var.project
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

resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

resource "google_project_iam_binding" "event_receiver" {
  members = ["serviceAccount:${google_service_account.service_account.email}"]
  project = var.project
  role    = "roles/eventarc.eventReceiver"
}

resource "google_project_iam_binding" "cloudfunctions_invoker" {
  project = var.project
  role    = "roles/cloudfunctions.invoker"
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
  source_tags        = ["webapp-instance"]
  destination_ranges = ["${google_compute_global_address.private_ip_range[count.index].address}/${google_compute_global_address.private_ip_range[count.index].prefix_length}"]
}

resource "google_compute_firewall" "lb_firewall" {
  count   = length(var.vpc_list)
  name    = "lb-firewall"
  network = google_compute_network.vpc_list[count.index].name
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["webapp-instance"]
}

#resource "google_compute_instance" "webapp_instance" {
#  machine_type = var.machine_type
#  count        = length(var.vpc_list)
#  name         = "webapp-instance-${count.index}"
#  zone         = var.zone
#  boot_disk {
#    initialize_params {
#      image = var.image
#      type  = var.image_type
#      size  = var.image_size
#    }
#  }
#  network_interface {
#    network    = google_compute_network.vpc_list[count.index].name
#    subnetwork = google_compute_subnetwork.webapp_subnet[count.index].name
#    access_config {}
#  }
#  service_account {
#    email  = google_service_account.service_account.email
#    scopes = ["logging-write", "monitoring", "pubsub"]
#  }
#  metadata_startup_script = <<EOF
##!/usr/bin/bash
#if [ ! -f "/opt/application/application.properties" ]; then
#{
#  echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.cloudsql_instance[count.index].private_ip_address}:3306/${google_sql_database.mysql_database[count.index].name}?createDatabaseIfNotExist=true"
#  echo "spring.datasource.username=${google_sql_user.mysql_user[count.index].name}"
#  echo "spring.datasource.password=${random_password.password.result}"
#  echo "spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver"
#  echo "spring.main.banner-mode=off"
#  echo "spring.jpa.hibernate.ddl-auto=update"
#  echo "spring.jpa.database=mysql"
#  echo "spring.jpa.show-sql=false"
#  echo "server.servlet.context-path=/"
#  echo "server.port=8080"
#  echo "gcp.project_id=${var.project}"
#  echo "gcp.topic_name=${google_pubsub_topic.topic.name}"
#  echo "gcp.email_time_duration=2"
#  echo "app.environment=prod"
#} >> /opt/application/application.properties
#fi
#sudo chown csye6225:csye6225 /opt/application/application.properties
#sudo chown csye6225:csye6225 /opt/application/application-test.properties
#sudo chmod 440 /opt/application/application.properties
#sudo chmod 440 /opt/application/application-test.properties
#touch test.txt
#EOF
#}

resource "google_compute_instance_template" "webapp_instance_template" {
  machine_type = var.machine_type
  count        = length(var.vpc_list)
  name         = "webapp-instance-${count.index}"
  tags         = ["webapp-instance"]
  disk {
    source_image = var.image
    auto_delete  = true
    boot         = true
    type = var.image_type
    disk_size_gb = var.image_size
  }
  network_interface {
    network    = google_compute_network.vpc_list[count.index].name
    subnetwork = google_compute_subnetwork.webapp_subnet[count.index].name
    access_config {}
  }
  service_account {
    email  = google_service_account.service_account.email
    scopes = ["logging-write", "monitoring", "pubsub"]
  }
  lifecycle {
    create_before_destroy = true
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
  echo "spring.jpa.show-sql=false"
  echo "server.servlet.context-path=/"
  echo "server.port=8080"
  echo "gcp.project_id=${var.project}"
  echo "gcp.topic_name=${google_pubsub_topic.topic.name}"
  echo "gcp.email_time_duration=2"
  echo "app.environment=prod"
} >> /opt/application/application.properties
fi
sudo chown csye6225:csye6225 /opt/application/application.properties
sudo chown csye6225:csye6225 /opt/application/application-test.properties
sudo chmod 440 /opt/application/application.properties
sudo chmod 440 /opt/application/application-test.properties
touch test.txt
EOF
}

resource "google_compute_region_health_check" "health_check" {
  name                = "health-check"
  check_interval_sec  = var.health_check.check_interval_sec
  timeout_sec         = var.health_check.timeout_sec
  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_request_path
  }
  log_config {
    enable = true
  }
}

resource "google_compute_region_autoscaler" "autoscaler" {
  count  = length(var.vpc_list)
  name   = "autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.manager[count.index].self_link

  autoscaling_policy {
    max_replicas    = var.autoscaler.max_replicas
    min_replicas    = var.autoscaler.min_replicas
    cooldown_period = var.autoscaler.cooldown_period

    cpu_utilization {
      target = var.autoscaler.target_cpu_utilization
    }
  }
}

resource "google_compute_region_instance_group_manager" "manager" {
  count              = length(var.vpc_list)
  name               = "instance-group-manager"
  base_instance_name = "instance"
  region             = var.region
  target_size        = var.autoscaler.min_replicas
  distribution_policy_zones = [var.zone,var.zone1,var.zone2]

  version {
    instance_template = google_compute_instance_template.webapp_instance_template[count.index].self_link
    name              = "version-1"
  }

  named_port {
    name = var.named_port
    port = var.health_check_port
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.health_check.id
    initial_delay_sec = var.instance_group_manager_autohealing_delay
  }
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

resource "google_pubsub_topic" "topic" {
  name = "verify_email"
}

resource "google_pubsub_subscription" "subscription" {
  name  = "topic_subscription"
  topic = google_pubsub_topic.topic.name
}

resource "google_cloudfunctions2_function" "email_subscription" {
  count    = length(var.vpc_list)
  location = var.region
  name     = var.cloud_function_name
  build_config {
    entry_point = var.cloud_function_entrypoint
    runtime     = var.cloud_function_runtime
    source {
      storage_source {
        bucket = var.cloud_storage_bucket
        object = var.cloud_storage_bucket_object
      }
    }
  }
  event_trigger {
    trigger_region = var.region
    event_type     = var.cloud_function_event_trigger
    pubsub_topic   = google_pubsub_topic.topic.id
    retry_policy   = var.cloud_function_retry_policy
  }
  service_config {
    max_instance_count = 1
    available_memory   = var.cloud_function_available_memory
    timeout_seconds    = var.cloud_function_timeout
    vpc_connector      = google_vpc_access_connector.connector[count.index].id
    environment_variables = {
      DB_USER = google_sql_user.mysql_user[count.index].name
      DB_PASS = random_password.password.result
      DB_NAME = google_sql_database.mysql_database[count.index].name
      DB_PORT = var.db_port
      DB_HOST = google_sql_database_instance.cloudsql_instance[count.index].private_ip_address
    }
    service_account_email = google_service_account.service_account.email
  }
}

resource "google_vpc_access_connector" "connector" {
  count         = length(var.vpc_list)
  name          = var.vpc_connector_name
  ip_cidr_range = var.vpc_connector_cidr
  network       = google_compute_network.vpc_list[count.index].name
}

#resource "google_compute_region_backend_service" "backend_service" {
#  load_balancing_scheme = "INTERNAL_MANAGED"
#  count = length(var.vpc_list)
#  region = var.region
#  name        = "backend-service"
#  port_name = "http-server"
#  protocol    = "HTTP"
#  timeout_sec = 10
#
#  health_checks = [google_compute_region_health_check.health_check.self_link]
#
#  backend {
#    group = google_compute_region_instance_group_manager.manager[count.index].instance_group
#    balancing_mode = "UTILIZATION"
#    capacity_scaler = 1.0
#  }
#}
#
#resource "google_compute_region_url_map" "url_map" {
#  count = length(var.vpc_list)
#  name            = "url-map"
#  region = var.region
#  default_service = google_compute_region_backend_service.backend_service[count.index].self_link
#}
#
#resource "google_compute_managed_ssl_certificate" "managed_ssl_certificate" {
#  name = "managed-ssl-certificate"
#  managed {
#    domains = [var.domain_name]
#  }
#}
#
#resource "google_compute_region_target_https_proxy" "https_proxy" {
#  count = length(var.vpc_list)
#  region = var.region
#  name             = "https-proxy"
#  url_map          = google_compute_region_url_map.url_map[count.index].id
#  ssl_certificates = [google_compute_managed_ssl_certificate.managed_ssl_certificate.name]
#  depends_on = [google_compute_region_url_map.url_map]
#}
#
#resource "google_compute_global_address" "global_ip_address" {
#  name = "global-ip-address"
#}
#
#resource "google_compute_forwarding_rule" "https_forwarding_rule" {
#  count      = length(var.vpc_list)
#  region     = var.region
#  name       = "http-forwarding-rule"
#  target     = google_compute_region_target_https_proxy.https_proxy[count.index].self_link
#  port_range = "443"
#  ip_address = google_compute_global_address.global_ip_address.address
#}

module "gce-lb-http" {
  count                           = length(var.vpc_list)
  source                          = "GoogleCloudPlatform/lb-http/google"
  version                         = "~> 9.0"
  project                         = var.project
  name                            = "group-http-lb"
  ssl                             = true
  managed_ssl_certificate_domains = ["brianmarcelpatrao.me"]
  http_forward                    = false
  backends = {
    default = {
      port        = var.service_port
      protocol    = "HTTP"
      port_name   = var.named_port
      timeout_sec = var.autoscaler.cooldown_period
      enable_cdn  = false
      health_check = {
        request_path = var.health_check_request_path
        port         = var.service_port
      }
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = google_compute_region_instance_group_manager.manager[count.index].instance_group
        },
      ]
      iap_config = {
        enable = false
      }
    }
  }
}

