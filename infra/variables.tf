variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:DNS:Edit and Tunnel:Edit permissions"
  sensitive   = true
}

variable "domain" {
  description = "Root domain managed by Cloudflare, e.g. yourdomain.com"
}

variable "tunnel_secret" {
  description = "Secret for the cloudflared tunnel — base64 encoded 32-byte value"
  sensitive   = true
}
