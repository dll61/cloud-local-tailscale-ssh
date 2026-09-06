# Lightweight heal for Tailscale + OpenSSH. Does not touch Clash/airport.
$ErrorActionPreference = 'Continue'
$env:HTTP_PROXY = ''; $env:HTTPS_PROXY = ''; $env:ALL_PROXY = ''
$env:http_proxy = ''; $env:https_proxy = ''; $env:all_proxy = ''
$env:NO_PROXY = 'localhost,127.0.0.1,::1,100.64.0.0/10,.tailscale.com,.tailscale.io,.ts.net'

function Ensure-Service([string]$Name) {
  try {
    $s = Get-Service -Name $Name -ErrorAction Stop
    if ($s.StartType -eq 'Disabled') { return }
    if ($s.Status -ne 'Running') { Start-Service -Name $Name -ErrorAction SilentlyContinue }
  } catch {}
}

Ensure-Service 'Tailscale'
Ensure-Service 'sshd'
Ensure-Service 'ssh-agent'

$ts = 'C:\Program Files\Tailscale\tailscale.exe'
if (Test-Path $ts) {
  $st = & $ts status 2>&1 | Out-String
  if ($st -match 'NoState|Logged out|NeedsLogin') {
    & $ts up --accept-dns=$false --hostname=$env:COMPUTERNAME.ToLower() --timeout=60s 2>&1 | Out-Null
  }
}
