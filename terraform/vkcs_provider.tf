terraform {
  required_version = ">= 1.0"
  
  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.12.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.1"
    }
  }
}

provider "vkcs" {
  username   = var.username
  password   = var.password
  project_id = var.project_id
  region     = var.region
  auth_url   = var.vkcs_auth_url
}