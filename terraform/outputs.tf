output "public_ips" {
  description = "Public IP addresses for SSH access"
  value = {
    haproxy = vkcs_networking_floatingip.haproxy_fip.address
    app1    = vkcs_networking_floatingip.app1_fip.address
    app2    = vkcs_networking_floatingip.app2_fip.address
  }
}

output "database_public_ip" {
  description = "Public IP address of Managed Database"
  value       = vkcs_db_instance.mysql.ip[0]
}

output "private_ips" {
  description = "Private IP addresses for internal communication"
  value = {
    haproxy = vkcs_compute_instance.haproxy.network[0].fixed_ip_v4
    app1    = vkcs_compute_instance.app[0].network[0].fixed_ip_v4
    app2    = vkcs_compute_instance.app[1].network[0].fixed_ip_v4
    db      = vkcs_db_instance.mysql.ip[0]
  }
}

output "application_urls" {
  description = "URLs to access the application"
  value = {
    haproxy_public = "http://${vkcs_networking_floatingip.haproxy_fip.address}"
    app_servers = [
      "http://${vkcs_compute_instance.app[0].network[0].fixed_ip_v4}:5000",
      "http://${vkcs_compute_instance.app[1].network[0].fixed_ip_v4}:5000"
    ]
    database = "mysql://${var.db_username}@${vkcs_db_instance.mysql.ip[0]}:3306/${var.db_name}"
  }
}

output "security_groups" {
  description = "Security groups created"
  value = {
    haproxy = vkcs_networking_secgroup.haproxy_sg.name
    app     = vkcs_networking_secgroup.app_sg.name
    db      = vkcs_networking_secgroup.db_sg.name
  }
}

output "managed_database_info" {
  description = "Managed Database information"
  value = {
    name        = vkcs_db_instance.mysql.name
    host        = vkcs_db_instance.mysql.ip[0]
    database    = var.db_name
    username    = var.db_username
    flavor      = vkcs_db_instance.mysql.flavor_id
    size_gb     = vkcs_db_instance.mysql.size
    volume_type = vkcs_db_instance.mysql.volume_type
    public_ip   = vkcs_db_instance.mysql.ip[0]
  }
  sensitive = true
}

output "keypair_name" {
  description = "Name of the created keypair"
  value       = vkcs_compute_keypair.app_keypair.name
}

output "availability_zones_used" {
  description = "Availability zones used for deployment"
  value = {
    haproxy = var.availability_zones[0]
    app_1   = var.availability_zones[1]
    app_2   = var.availability_zones[2]
    db      = "GZ1"
  }
}
