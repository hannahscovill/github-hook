terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-calamari"
    key    = "github-hooks/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name        = "GitHubActions-github-hook"
  description = "GitHub Actions role for github-hook - Terraform state access only"

  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:hannahscovill/github-hook:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "terraform_state" {
  name = "TerraformStateAccess"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetBucketVersioning"]
        Resource = "arn:aws:s3:::terraform-state-calamari"
        Condition = {
          StringLike = { "s3:prefix" = ["${local.state_prefix}/*"] }
        }
      },
      {
        Sid    = "S3StateObjects"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::terraform-state-calamari/${local.state_prefix}/*"
      },
    ]
  })
}

output "github_actions_role_arn" {
  description = "Set this as AWS_OIDC_ROLE_ARN in GitHub Actions variables"
  value       = aws_iam_role.github_actions.arn
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
# terraform import cloudflare_tunnel.agent 0b6d074787cce9c80cdaf6c282d419d0/c86527c9-d108-4758-a493-ef42656cdcb8
resource "cloudflare_tunnel" "agent" {
  account_id = local.account_id
  name       = local.tunnel_name
  secret     = var.tunnel_secret
}

resource "cloudflare_tunnel_config" "agent" {
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
  value   = "${local.tunnel_id}.cfargotunnel.com"
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
