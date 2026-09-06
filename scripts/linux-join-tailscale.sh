#!/usr/bin/env bash
set -euo pipefail
# Usage: TAILSCALE_AUTHKEY=... ./linux-join-tailscale.sh [hostname]
HOSTNAME_ARG="${1:-cloud-box}"
if [[ -z "${TAILSCALE_AUTHKEY:-}" ]]; then
  echo "Set TAILSCALE_AUTHKEY first (do not commit it)." >&2
  exit 1
fi
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
# Environments without systemd may need: sudo tailscaled --state=... &
sudo tailscale up --hostname="$HOSTNAME_ARG" --authkey="$TAILSCALE_AUTHKEY" --ssh=false --accept-dns=false --reset
sudo tailscale status
sudo tailscale ip -4
