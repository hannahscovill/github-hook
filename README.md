# github-hook

A GitHub webhook receiver running on a local Mac exposed via Cloudflare Tunnel. Listens for GitHub events, verifies HMAC signatures, and will eventually invoke a Claude agent to create PRs.

## Running locally

Start the tunnel (keeps your Mac reachable at `agent.scovill.dev`):

```
cloudflared tunnel run github-webhook-agent
```

In a separate terminal, start the webhook server:

```
GITHUB_WEBHOOK_SECRET=your-secret node webhook.js
```

The secret must match what you configured in GitHub under **Settings → Webhooks → Secret** for the repo you're listening to. Incoming requests without a valid signature are rejected with 403.

## Infrastructure

Cloudflare Tunnel, DNS, and IP allowlist are managed with Terraform in `infra/` and deployed automatically via GitHub Actions on push to `main`.

The GitHub Actions IAM role (`GitHubActions-github-hook`) was bootstrapped locally once and lives outside Terraform management.
