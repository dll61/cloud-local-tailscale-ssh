# Clash Verge / Mihomo isolation (airport vs Tailscale lane)

## Problem we solved

On a Windows PC that also runs **Clash Verge** (system proxy / rule / global / TUN), Tailscale’s **control plane** may be forced through `HTTP_PROXY=http://127.0.0.1:MIXED_PORT`. Symptoms: slow bring-up, `NoState`, flaky reconnect after reboot—while the airport itself is fine.

People often “fix the network” and break either the VPN or the proxy. We needed **two separate lanes**:

| Lane | Role |
|---|---|
| Airport (Clash) | Browse / AI APIs / blocked sites — modes can change freely |
| Tailscale mesh | Cloud ↔ local SSH/SFTP — must stay DIRECT and stable |

## Solution (minimal, reversible)

1. **System proxy bypass** (Clash Verge `system_proxy_bypass`): keep default LAN bypass, add `*.tailscale.com`, `*.tailscale.io`, `*.ts.net`, `100.*`.
2. **TUN future-proof**: `tun.route-exclude-address` includes `100.64.0.0/10` and Tailscale IPv6 ULA `fd7a:115c:a1e0::/48` so enabling TUN later does not swallow the mesh.
3. **Profile Merge `prepend-rules`**: `PROCESS-NAME` for `tailscaled` / `Tailscale` / `ssh*` → `DIRECT`, plus Tailscale domains and `IP-CIDR,100.64.0.0/10,DIRECT,no-resolve`.
4. **User `NO_PROXY`**: append Tailscale hosts/CIDR; **do not** remove `HTTP_PROXY` pointing at Clash.
5. **Heal script**: clear proxy env **only inside that process** before calling `tailscale`; never stop Clash.

Back up `verge.yaml` / `config.yaml` / merge files before editing. Prefer soft reload over killing the UI.

## What this is not

- Not a recommendation to disable your airport.
- Not a guarantee of LAN-speed cross-border transfers (DERP may still apply).
- Global mode historically ignores most rules; bypass + TUN exclude + process DIRECT + `NO_PROXY` together cover the common breakage.

## Verify

- Clash process still running; `HTTP_PROXY` still your mixed-port.
- `tailscale status` shows both nodes; `ssh` to the Windows host succeeds.
