terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.19"
    }
  }
}

provider "vultr" {
  # VULTR_API_KEY comes from env var
}

variable "hostname" {
  type        = string
  default     = "ez3proxy"
  description = "Instance hostname"
}

variable "plan" {
  type        = string
  default     = "vc2-2c-4gb"
  description = "Vultr plan (vc2-1c-1gb, vc2-2c-4gb, etc.)"
}

variable "region" {
  type        = string
  default     = "atl"
  description = "Vultr region (atl, ewr, lax, etc.)"
}

variable "enable_ipv6" {
  type        = bool
  default     = false
  description = "Enable IPv6 on the instance"
}

locals {
  ssh_public_key = file("${path.module}/../secrets/deploy-key.pub")
}

resource "vultr_ssh_key" "default" {
  name    = "${var.hostname}-key"
  ssh_key = local.ssh_public_key
}

resource "vultr_instance" "server1" {
  plan              = var.plan
  region            = var.region
  os_id             = 2136  # Debian bookworm
  hostname          = var.hostname
  ssh_key_ids       = [vultr_ssh_key.default.id]
  enable_ipv6       = var.enable_ipv6
}

output "server_id" {
  value = vultr_instance.server1.id
}

output "server_ipv4" {
  value = vultr_instance.server1.main_ip
}
