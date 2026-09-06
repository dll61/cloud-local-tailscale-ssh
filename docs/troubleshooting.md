# Troubleshooting

## `Permission denied (publickey)` on Windows
- If the Windows user is in **Administrators**, `sshd` ignores `%USERPROFILE%\.ssh\authorized_keys` and only reads `C:\ProgramData\ssh\administrators_authorized_keys`.
- Fix ACL: `icacls administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"`.

## Tailscale `unexpected state: NoState`
- Check `Get-Service Tailscale` and whether multiple `tailscaled.exe` exist.
- Admin: stop service, `taskkill /F /IM tailscaled.exe`, start service, then `tailscale up --reset ...`.
- If still broken: winget uninstall/reinstall Tailscale, then re-auth. Avoid leaving `msiexec` hung mid-uninstall.

## Slow transfers / `relay "hkg"` (or other DERP)
- `tailscale status` / `tailscale ping` showing relay means no direct WireGuard path.
- Common with hard NAT on cloud VMs + cross-border paths.
- For bulk sync, use Git/object storage; keep Tailscale for control.

## Auth URL / OAuth `403 session expired`
- Prefer **auth key** join for headless cloud nodes instead of browser login links.

## Local HTTP proxy breaks control plane
- User-level `HTTP_PROXY=http://127.0.0.1:PORT` may affect Tailscale CLI. Clear proxy env for `tailscale up` / diagnosis.
