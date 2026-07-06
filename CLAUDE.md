# Claude Code Guidelines

## Git workflow

- Never commit directly to `main`. Always create a feature branch and open a PR.
- Branch naming: `feat/`, `fix/`, `chore/` prefixes, e.g. `feat/add-signature-verification`
- Keep commits focused — one logical change per commit.

## Secrets and sensitive files

- Never commit `infra/terraform.tfvars` — it contains secrets.
- Never commit `.cloudflared/` credentials.
- Never log or print webhook secrets or signatures.

## Project context

This repo is a GitHub webhook receiver running on a local Mac exposed via Cloudflare Tunnel.
It listens for GitHub issue events, verifies HMAC signatures, and will eventually invoke a Claude agent to create PRs.

Infrastructure is managed with Terraform in `infra/` and deployed via GitHub Actions.
