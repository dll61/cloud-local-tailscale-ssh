# Cloud ↔ Local Tailscale SSH Mesh

> 把「云端 Linux」和「本地 Windows」做成一张安全内网：云端可以直接 SSH/SFTP 控本机、互传文件，**不把 22 端口暴露到公网**。

**解决什么问题**
- 云端 Agent / Codex / 终端想读写本机文件、执行本机命令，又不想走 Bot 中转、也不想开公网端口。
- 需要长期可复用、可撤销的双机通道。

**适合谁**
- 本地 Windows 开发机 + 云端 Linux 工作站/Agent 沙箱的人
- 需要「控机」优先于「狂拉大文件」的工作流

**最后能得到什么**
- 官方 Tailscale 组网 + Windows OpenSSH（密钥登录）+ SCP/SFTP
- 云端：`ssh local-win` 即可进入本机
- 大文件通道可用；跨国场景常走 DERP 中继（见限制）

## Quick Start

### 前置
- 两边都能装 [Tailscale](https://tailscale.com/)
- 本地 Windows 可启用 OpenSSH Server
- 同一 Tailscale 账号（或同一 tailnet）
- 管理员权限（Windows 装服务 / 写 `administrators_authorized_keys` / 防火墙）

### 1) 两边加入同一张 Tailscale 网
云端 Linux：

```bash
# 安装官方 Tailscale 后
sudo tailscale up --hostname=cloud-box --accept-dns=false
# 无图形界面时用 auth key（在 Tailscale Admin → Settings → Keys 创建，Reusable、非 Ephemeral）
sudo tailscale up --hostname=cloud-box --authkey=YOUR_TAILSCALE_AUTHKEY --accept-dns=false --reset
```

本地 Windows（PowerShell）：

```powershell
winget install --id Tailscale.Tailscale -e --accept-package-agreements --accept-source-agreements
# 登录同一账号，或：
& 'C:\Program Files\Tailscale\tailscale.exe' up --hostname=local-win --auth-key=YOUR_TAILSCALE_AUTHKEY --accept-dns=$false --reset
```

确认两边 `tailscale status` 能互相看见，并记下本机 Tailscale IP（形如 `100.x.y.z`）。

### 2) 本机启用 OpenSSH Server（密钥登录）
```powershell
winget install --id Microsoft.OpenSSH.Preview -e --accept-package-agreements --accept-source-agreements
# 或 Windows 可选功能 OpenSSH Server
```

在**云端**生成密钥（不要用密码）：

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_cloud_to_win -N '' -C 'cloud-to-local-win'
cat ~/.ssh/id_ed25519_cloud_to_win.pub
```

若 Windows 用户属于 Administrators，公钥必须写入：

`C:\ProgramData\ssh\administrators_authorized_keys`

（普通用户才读 `%USERPROFILE%\.ssh\authorized_keys`。）

管理员 PowerShell 示例：

```powershell
$pub = 'ssh-ed25519 YOUR_PUBLIC_KEY_BODY cloud-to-local-win'
$f = 'C:\ProgramData\ssh\administrators_authorized_keys'
Set-Content -Path $f -Value $pub -Encoding ascii
icacls $f /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
# 仅允许 Tailscale CGNAT 访问 22
New-NetFirewallRule -Name 'SSHD-Tailscale-Only' -DisplayName 'OpenSSH over Tailscale only' `
  -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -RemoteAddress 100.64.0.0/10 -ErrorAction SilentlyContinue
Get-NetFirewallRule -DisplayName '*OpenSSH*' | Where-Object { $_.Name -ne 'SSHD-Tailscale-Only' } | Disable-NetFirewallRule
Add-Content C:\ProgramData\ssh\sshd_config "`nPasswordAuthentication no`nPubkeyAuthentication yes`nKbdInteractiveAuthentication no"
Restart-Service sshd
```

也可用仓库脚本：`scripts/windows-harden-sshd.ps1`。

### 3) 云端连接
`~/.ssh/config`：

```
Host local-win
  HostName 100.x.y.z
  User YOUR_WINDOWS_USER
  IdentityFile ~/.ssh/id_ed25519_cloud_to_win
  IdentitiesOnly yes
```

```bash
ssh local-win "hostname"
scp ./file.bin local-win:/Users/YOUR_WINDOWS_USER/xfer/
scp local-win:/Users/YOUR_WINDOWS_USER/xfer/out.bin ./
```

## Architecture

```text
[Cloud Linux] --Tailscale (WireGuard / DERP)--> [Local Windows]
     | SSH/SFTP key auth                              | sshd
     | no public port 22                              | firewall: 100.64.0.0/10 only
```

- **控制面**：Tailscale 负责发现与加密通道
- **执行面**：OpenSSH 负责命令与文件
- **不同路径**：代码/大文件日常同步仍建议 Git（GitHub 等 CDN）；本方案补的是「实时控机」

## Before / After

| Before | After |
|---|---|
| 只能靠聊天 Bot 中转读本机，耗额度 | 云端直接 `ssh` / `scp` |
| 公网开 22 / 改端口 / 动态 DNS | 不暴露公网端口 |
| 大文件硬拷到云盘再下 | 可直传；跨国慢时改走 Git |

## Limits（务必读）

1. **跨国（例如国内宽带 ↔ 美区云）经常无法 P2P**，会走 Tailscale DERP 中继 → 大文件偏慢。这是网络拓扑限制，不是“没配好”。
2. **控机用 Tailscale；常同步大货/代码用 GitHub（或对象存储）**，两者互补。
3. Windows Tailscale 偶发 `NoState` / 双 `tailscaled`：优先 `Restart-Service Tailscale`；顽固则干净重装后再 `tailscale up`。
4. 无 systemd 的精简 Linux 环境，重启后可能要手动拉起 `tailscaled`。

## Troubleshooting

见 [docs/troubleshooting.md](docs/troubleshooting.md)。

常见搜索词：`tailscale NoState windows`、`OpenSSH administrators_authorized_keys`、`Permission denied publickey windows`、`tailscale DERP slow`、`cloud ssh to home pc without port forward`。

## Security & Revoke

- 只用密钥，关闭密码登录；22 仅放行 `100.64.0.0/10`
- 撤销：Tailscale Admin 移除节点 / 作废 auth key；删除本机 `administrators_authorized_keys` 对应行并 `Restart-Service sshd`
- 详见 [SECURITY.md](SECURITY.md)

## Verified scope

在真实双机环境验证过：
- 云端 → 本机 SSH 命令执行
- 双向小文件 SCP
- 数 MB～数十 MB 文件传输（中继路径下）

未宣称：稳定千兆直连、替代 Git 做大仓库同步、任意防火墙下必直连。

## License

MIT — 见 [LICENSE](LICENSE)
