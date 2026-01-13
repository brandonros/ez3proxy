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

locals {
  ssh_public_key = file("${path.module}/../secrets/deploy-key.pub")
}

resource "vultr_ssh_key" "default" {
  name    = "ez3proxy-key"
  ssh_key = local.ssh_public_key
}

resource "vultr_instance" "server1" {
  plan        = "vc2-2c-4gb"
  region      = "atl"
  os_id       = 2136  # Debian bookworm
  hostname    = "ez3proxy"
  ssh_key_ids = [vultr_ssh_key.default.id]
}

output "server_id" {
  value = vultr_instance.server1.id
}

output "server_ipv4" {
  value = vultr_instance.server1.main_ip
}
