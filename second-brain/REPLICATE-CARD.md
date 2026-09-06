# 复刻卡：云端 ↔ 本地 Tailscale SSH

- **是什么**：官方 Tailscale 组网 + Windows OpenSSH 密钥登录，实现云端控本机与双向文件传输。
- **解决什么**：不暴露公网端口、不经聊天 Bot 中转，让云端 Agent/终端直接操作本机。
- **最终方案**：同一 tailnet；Windows 管理员账号用 `administrators_authorized_keys`；防火墙仅放行 `100.64.0.0/10`；大文件日常仍走 Git。
- **关键坑**：Windows `NoState`/双进程；Administrators 不读用户 `authorized_keys`；跨国 DERP 慢。
- **已验证**：SSH 命令、双向小文件、数 MB～数十 MB SCP（中继）。
- **GitHub**：https://github.com/dll61/cloud-local-tailscale-ssh
- **下次先想**：要控机 → Tailscale SSH；要狂同步代码/大货 → GitHub。

- **后补坑**：Clash 与 Tailscale 抢控制面 → bypass + Merge DIRECT + 进程级清代理自愈；开机 delayed-auto + heal。
- **原则**：机场模式随便切；只护 mesh；改动能回滚。
