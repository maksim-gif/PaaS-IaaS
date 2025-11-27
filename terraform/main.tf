# Data sources
data "vkcs_compute_flavor" "compute" {
  name = var.compute_flavor
}

data "vkcs_images_image" "compute" {
  visibility = "public"
  default    = true
  properties = {
    mcs_os_distro  = "ubuntu"
    mcs_os_version = "20.04"
  }
}

data "vkcs_networking_network" "extnet" {
  name = "ext-net"
}

# Network infrastructure for application
resource "vkcs_networking_network" "app_net" {
  name           = "${var.lastname}-app-network"
  admin_state_up = true
}

resource "vkcs_networking_subnet" "app_subnet" {
  name            = "${var.lastname}-app-subnet"
  network_id      = vkcs_networking_network.app_net.id
  cidr            = "192.168.100.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "vkcs_networking_router" "app_router" {
  name                = "${var.lastname}-app-router"
  admin_state_up      = true
  external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_router_interface" "app_router_interface" {
  router_id = vkcs_networking_router.app_router.id
  subnet_id = vkcs_networking_subnet.app_subnet.id
}

# Security Groups
resource "vkcs_networking_secgroup" "haproxy_sg" {
  name = "${var.lastname}-haproxy-sg"
}

resource "vkcs_networking_secgroup" "app_sg" {
  name = "${var.lastname}-app-sg"
}

# Database Security Group - исправленная версия
resource "vkcs_networking_secgroup" "db_sg" {
  name        = "${var.lastname}-db-sg"
  description = "Security group for MySQL database with app server access"
}

# HAProxy Security Group Rules
resource "vkcs_networking_secgroup_rule" "haproxy_http" {
  direction         = "ingress"
  port_range_min    = 80
  port_range_max    = 80
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.haproxy_sg.id
}

resource "vkcs_networking_secgroup_rule" "haproxy_https" {
  direction         = "ingress"
  port_range_min    = 443
  port_range_max    = 443
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.haproxy_sg.id
}

resource "vkcs_networking_secgroup_rule" "haproxy_ssh" {
  direction         = "ingress"
  port_range_min    = 22
  port_range_max    = 22
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.haproxy_sg.id
}

# App Servers Security Group Rules
resource "vkcs_networking_secgroup_rule" "app_ssh" {
  direction         = "ingress"
  port_range_min    = 22
  port_range_max    = 22
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.app_sg.id
}

resource "vkcs_networking_secgroup_rule" "app_flask" {
  direction         = "ingress"
  port_range_min    = 5000
  port_range_max    = 5000
  protocol          = "tcp"
  remote_ip_prefix  = "192.168.100.0/24"  # Allow from HAProxy private network
  security_group_id = vkcs_networking_secgroup.app_sg.id
}

# Database Security Group Rules - исправленные
# Разрешаем MySQL доступ с app серверов (приватная сеть)
resource "vkcs_networking_secgroup_rule" "db_mysql_from_apps_private" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = "192.168.100.0/24"  # Private network of app servers
  security_group_id = vkcs_networking_secgroup.db_sg.id
  description       = "Allow MySQL from app servers private network"
}

# Разрешаем исходящие соединения от БД
resource "vkcs_networking_secgroup_rule" "db_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.db_sg.id
  description       = "Allow all outbound traffic"
}

# Keypair
resource "vkcs_compute_keypair" "app_keypair" {
  name       = "${var.lastname}-keypair"
  public_key = var.ssh_public_key
}

# HAProxy Load Balancer
resource "vkcs_compute_instance" "haproxy" {
  name               = "${var.lastname}-haproxy"
  flavor_id          = data.vkcs_compute_flavor.compute.id
  key_pair           = vkcs_compute_keypair.app_keypair.name
  security_group_ids = [vkcs_networking_secgroup.haproxy_sg.id]
  availability_zone  = var.availability_zones[0]

  block_device {
    uuid                  = data.vkcs_images_image.compute.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 15
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.app_net.id
  }

  depends_on = [
    vkcs_networking_router_interface.app_router_interface
  ]
}

# Application Servers
resource "vkcs_compute_instance" "app" {
  count              = 2
  name               = "${var.lastname}-app-${count.index}"
  flavor_id          = data.vkcs_compute_flavor.compute.id
  key_pair           = vkcs_compute_keypair.app_keypair.name
  security_group_ids = [vkcs_networking_secgroup.app_sg.id]
  availability_zone  = var.availability_zones[count.index + 1]

  block_device {
    uuid                  = data.vkcs_images_image.compute.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 15
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.app_net.id
  }

  depends_on = [
    vkcs_networking_router_interface.app_router_interface,
    vkcs_db_instance.mysql
  ]
}

# Floating IP для HAProxy
resource "vkcs_networking_floatingip" "haproxy_fip" {
  pool = "ext-net"
}

resource "vkcs_compute_floatingip_associate" "haproxy_fip" {
  floating_ip = vkcs_networking_floatingip.haproxy_fip.address
  instance_id = vkcs_compute_instance.haproxy.id
}

# Floating IP для app1
resource "vkcs_networking_floatingip" "app1_fip" {
  pool = "ext-net"
}

resource "vkcs_compute_floatingip_associate" "app1_fip" {
  floating_ip = vkcs_networking_floatingip.app1_fip.address
  instance_id = vkcs_compute_instance.app[0].id
}

# Floating IP для app2
resource "vkcs_networking_floatingip" "app2_fip" {
  pool = "ext-net"
}

resource "vkcs_compute_floatingip_associate" "app2_fip" {
  floating_ip = vkcs_networking_floatingip.app2_fip.address
  instance_id = vkcs_compute_instance.app[1].id
}
