# Architecture notes

## Why Tailscale + SSH
Tailscale gives a private mesh (WireGuard) without opening inbound ports on the home router. SSH remains the familiar remote shell/file protocol for agents and humans.

## Why not only GitHub
GitHub is excellent for versioned code and large artifact distribution via CDN. It does not give interactive shell on your laptop, nor instant read/write of arbitrary local paths.

## Why DERP happens
If UDP hole punching fails (symmetric NAT, cloud egress policies, CGNAT, cross-region filters), peers fall back to DERP relays. Connectivity remains; throughput drops.

## Operational ownership
| Component | Owner tip |
|---|---|
| Tailscale node identity | One tailnet; hostname stable |
| `sshd` on Windows | Auto start; key-only |
| Cloud `tailscaled` | Ensure start-on-boot in your environment |
| Secrets | Auth keys + SSH private keys stay off git |
