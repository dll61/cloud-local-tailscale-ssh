# Security

## Do
- Prefer Tailscale auth keys that are **Reusable** and **not Ephemeral** for servers; store keys in a secret manager, never in git or chat.
- Use ed25519 SSH keys; disable password and keyboard-interactive auth on Windows `sshd`.
- Restrict inbound TCP/22 to Tailscale CGNAT `100.64.0.0/10` (or your tailnet ranges only).
- On Windows Administrators accounts, put keys in `C:\ProgramData\ssh\administrators_authorized_keys` with tight ACLs (Administrators + SYSTEM only).

## Don't
- Do not publish real auth keys, private keys, user profile paths, emails, phone numbers, or host IPs.
- Do not leave the default “allow OpenSSH from anywhere” firewall rule enabled after install.
- Do not assume DERP relay traffic is “LAN speed”.

## Incident response
1. Remove/disable the node in Tailscale Admin.
2. Expire/rotate the auth key.
3. Remove the SSH public key from the Windows authorized_keys file and restart `sshd`.
4. Rotate any credentials that may have been exposed in logs or chat.
