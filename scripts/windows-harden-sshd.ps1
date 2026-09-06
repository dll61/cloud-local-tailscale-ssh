#Requires -RunAsAdministrator
param(
  [Parameter(Mandatory = $true)][string]$PublicKeyLine,
  [string]$TailscaleCidr = '100.64.0.0/10'
)

$ErrorActionPreference = 'Stop'
$f = 'C:\ProgramData\ssh\administrators_authorized_keys'
Set-Content -Path $f -Value $PublicKeyLine.Trim() -Encoding ascii
icacls $f /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null

New-NetFirewallRule -Name 'SSHD-Tailscale-Only' -DisplayName 'OpenSSH over Tailscale only' `
  -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -RemoteAddress $TailscaleCidr -ErrorAction SilentlyContinue | Out-Null
Get-NetFirewallRule -DisplayName '*OpenSSH*' -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -ne 'SSHD-Tailscale-Only' } |
  Disable-NetFirewallRule

$cfg = 'C:\ProgramData\ssh\sshd_config'
Add-Content $cfg "`nPasswordAuthentication no`nPubkeyAuthentication yes`nKbdInteractiveAuthentication no"
Restart-Service sshd
Write-Output 'DONE'
