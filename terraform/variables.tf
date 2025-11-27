# Authentication variables
variable "username" {
  description = "VK Cloud username"
  type        = string
}

variable "password" {
  description = "VK Cloud password"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "VK Cloud project ID"
  type        = string
}

variable "region" {
  description = "VK Cloud region"
  type        = string
  default     = "RegionOne"
}

variable "vkcs_auth_url" {
  description = "VK Cloud auth URL"
  type        = string
  default     = "https://infra.mail.ru:35357/v3/"
}

# Project variables
variable "lastname" {
  description = "Lastname for resource naming"
  type        = string
}

# Compute variables
variable "compute_flavor" {
  description = "Flavor for compute instances"
  type        = string
  default     = "Standard-2-4-50"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["GZ1", "MS1", "ME1"]
}

# Database variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "7h78gs.p70aG85wU0"
}
