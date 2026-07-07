terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-state-calamari"
    key     = "github-hooks/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  account_id   = "0b6d074787cce9c80cdaf6c282d419d0"
  tunnel_id    = "c86527c9-d108-4758-a493-ef42656cdcb8"
  tunnel_name  = "github-webhook-agent"
  subdomain    = "agent"
  state_prefix = "github-hooks" # must match backend key prefix above
}

data "cloudflare_zone" "domain" {
  name = var.domain
}

# This tunnel already exists — import it before applying:
# terraform import cloudflare_zero_trust_tunnel_cloudflared.agent 0b6d074787cce9c80cdaf6c282d419d0/c86527c9-d108-4758-a493-ef42656cdcb8
resource "cloudflare_zero_trust_tunnel_cloudflared" "agent" {
  account_id = local.account_id
  name       = local.tunnel_name
  secret     = var.tunnel_secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "agent" {
  account_id = local.account_id
  tunnel_id  = local.tunnel_id

  config {
    ingress_rule {
      hostname = "${local.subdomain}.${var.domain}"
      service  = "http://localhost:3000"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "agent" {
  zone_id = data.cloudflare_zone.domain.id
  name    = local.subdomain
  content = "${local.tunnel_id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# IP allowlist — populated by update-cf-ips.yml workflow
resource "cloudflare_list" "github_hooks" {
  account_id  = local.account_id
  name        = "github_hooks"
  kind        = "ip"
  description = "GitHub webhook source IPs — synced from api.github.com/meta"
}
