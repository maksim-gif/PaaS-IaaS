# Data source для flavor БД
data "vkcs_compute_flavor" "db" {
  name = "Standard-2-8-50"
}

# Network infrastructure for database
resource "vkcs_networking_network" "db_net" {
  name           = "${var.lastname}-db-network"
  admin_state_up = true
}

resource "vkcs_networking_subnet" "db_subnet" {
  name            = "${var.lastname}-db-subnet"
  network_id      = vkcs_networking_network.db_net.id
  cidr            = "10.100.0.0/16"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Router for database network
resource "vkcs_networking_router" "db_router" {
  name                = "${var.lastname}-db-router"
  admin_state_up      = true
  external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_router_interface" "db_router_interface" {
  router_id = vkcs_networking_router.db_router.id
  subnet_id = vkcs_networking_subnet.db_subnet.id
}

# Managed Database Instance с публичным IP
resource "vkcs_db_instance" "mysql" {
  name              = "${var.lastname}-mysql-db"
  availability_zone = "GZ1"
  flavor_id         = data.vkcs_compute_flavor.db.id

  datastore {
    type    = "mysql"
    version = "8.0"
  }

  # Включаем публичный IP для БД
  floating_ip_enabled = true

  network {
    uuid            = vkcs_networking_network.db_net.id
    security_groups = [vkcs_networking_secgroup.db_sg.id]
  }

  size        = 20
  volume_type = "ceph-ssd"
  
  disk_autoexpand {
    autoexpand    = true
    max_disk_size = 1000
  }

  # Добавляем расширение для мониторинга
  capabilities {
    name = "node_exporter"
    settings = {
      "listen_port" = "9100"
    }
  }

  depends_on = [
    vkcs_networking_router_interface.db_router_interface
  ]
}

# Database creation
resource "vkcs_db_database" "app_db" {
  name    = var.db_name
  dbms_id = vkcs_db_instance.mysql.id
}

# Database user creation
resource "vkcs_db_user" "app_user" {
  name      = var.db_username
  password  = var.db_password
  dbms_id   = vkcs_db_instance.mysql.id
  databases = [vkcs_db_database.app_db.name]
}
