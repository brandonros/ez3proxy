terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.19"
    }
  }
}

provider "vultr" {}

module "vps" {
  source         = "github.com/brandonros/nix-vps-template//terraform"
  hostname       = "ez3proxy"
  ssh_public_key = file("${path.root}/../secrets/deploy-key.pub")
}

output "server_id" {
  value = module.vps.server_id
}

output "server_ipv4" {
  value = module.vps.server_ipv4
}
