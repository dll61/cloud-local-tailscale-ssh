# Windows reboot survival

## Problem

After reboot (or a bad uninstall), Windows may leave Tailscale in `NoState`, duplicate `tailscaled.exe`, or OpenSSH not listening—so the cloud host cannot SSH home.

## Solution

1. Services: `Tailscale` (prefer delayed-auto), `sshd`, `ssh-agent` → Automatic / Running.
2. Firewall: allow TCP/22 only from `100.64.0.0/10`; disable the broad OpenSSH allow-anywhere rule.
3. Administrators accounts: keys in `C:\ProgramData\ssh\administrators_authorized_keys`.
4. Heal script + tasks:
   - Logon scheduled task + Startup folder cmd
   - Optional SYSTEM `ONSTART` task for pre-logon heal
5. Heal must **not** modify Clash; only ensure Tailscale/sshd and re-`up` if logged out / NoState.

See `scripts/windows/Ensure-CloudLocalMesh.ps1`.
