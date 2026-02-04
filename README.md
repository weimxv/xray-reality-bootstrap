# Xray Reality Bootstrap

<div align="center">

**极简 · 安全 · 可重复部署**

一个专注于 **VLESS + Reality** 的 VPS 节点部署脚本  
无 Web UI、无面板、无冗余 —— 只做一件事：**把全新 VPS 引导到可用节点**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-5.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Xray](https://img.shields.io/badge/Xray-Latest-purple.svg)](https://github.com/XTLS/Xray-core)

</div>

---

## ✨ 核心特性

| 特性 | 说明 |
|------|------|
| 🚫 **无 UI 面板** | 不暴露管理端口，降低攻击面 |
| 🧩 **模块化设计** | 每个功能独立脚本，易于维护 |
| 🔁 **可重复部署** | VPS 重装后快速恢复 |
| 🌐 **智能双栈** | 自动检测并适配 IPv4/IPv6 |
| ⚡ **性能优化** | BBR + Swap 智能配置 |
| 🛡️ **安全加固** | iptables + Fail2ban 自动部署 |

---

## 🎯 设计理念

### 1. **Reality 应该"看起来不存在"**
- 不运行多余服务
- 不暴露管理端口
- 不引入复杂依赖

### 2. **Bootstrap ≠ 运维面板**
- 专注部署引导
- 不做长期管理
- 不集成订阅系统

### 3. **脚本是工程，不是黑盒**
- 所有操作可追溯
- 所有修改有明确来源
- 模块化结构便于审计

---

## 📁 项目结构

```
xray-reality-bootstrap/
│
├── install.sh              # 主入口（全自动部署）
├── remove.sh               # 卸载脚本
│
├── core/                   # 核心模块（无 UI 耦合）
│   ├── preflight.sh        # 环境检查（root / 系统 / 锁）
│   ├── system.sh           # 系统初始化（apt / 依赖 / 时间）
│   ├── network.sh          # 网络检测（IPv4/IPv6 双栈）
│   ├── kernel.sh           # 内核优化（BBR / Swap）
│   ├── xray.sh             # 安装 Xray Core
│   ├── reality.sh          # Reality 配置生成
│   └── firewall.sh         # 防火墙配置（iptables / Fail2ban）
│
├── ui/                     # 交互体验层
│   ├── color.sh            # 颜色标签封装
│   ├── prompt.sh           # 倒计时输入
│   ├── spinner.sh          # 加载动画 + 重试
│   └── banner.sh           # Logo + 风险提示
│
├── lib/                    # 共享函数库
│   └── validator.sh        # 参数校验（端口 / 域名 / IP）
│
├── tools/                  # 管理工具生成
│   └── install_tools.sh    # 自动安装 xinfo 命令
│
└── runtime/                # 运行时数据（自动生成）
    ├── network.env         # 网络策略记录
    ├── kernel.env          # 内核优化记录
    ├── firewall.env        # 防火墙配置记录
    └── xray.env            # Reality 参数记录
```

---

## 🚀 快速开始

### 环境要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Debian 11/12 或 Ubuntu 20.04+ |
| 架构 | x86_64 / arm64 |
| 权限 | root 用户 |
| 网络 | 可访问 GitHub（IPv4 或 IPv6） |

### 一键部署（推荐，无需预装 git）

在新 VPS 上以 root 执行一条命令即可，脚本会自动安装所需依赖并完成部署：

```bash
# 方式 A：有 curl 时（多数系统已预装）
bash <(curl -fsSL https://raw.githubusercontent.com/weimxv/xray-reality-bootstrap/main/bootstrap.sh)

# 方式 B：没有 curl 但有 wget 时
bash <(wget -qO- https://raw.githubusercontent.com/weimxv/xray-reality-bootstrap/main/bootstrap.sh)

# 方式 C：curl 和 wget 都没有时，先装 curl 再执行
apt update && apt install -y curl
bash <(curl -fsSL https://raw.githubusercontent.com/weimxv/xray-reality-bootstrap/main/bootstrap.sh)
```

安装目录：`/opt/xray-reality-bootstrap`，部署完成后可用 `xinfo` 查看节点信息。若在 Reality 配置步骤失败，可进入该目录执行 `bash install.sh reality` 仅重跑该步。

### 方式二：克隆后部署

若已安装 git，也可克隆后本地执行：

```bash
git clone https://github.com/weimxv/xray-reality-bootstrap.git
cd xray-reality-bootstrap
bash install.sh
```

> 💡 **首次使用？** 查看 [详细部署指南](QUICKSTART.md)

### 部署流程

脚本将按顺序执行以下阶段：

1. **环境检查** - 验证 root 权限、系统版本、网络连通性
2. **系统初始化** - 更新软件包、安装依赖（jq / curl / qrencode）
3. **网络检测** - 探测 IPv4/IPv6，推荐最佳策略
4. **内核优化** - 启用 BBR、按需创建 Swap
5. **安装 Xray** - 下载官方最新版本
6. **Reality 配置** - 生成 UUID / 密钥 / SNI 优选
7. **防火墙部署** - 配置 iptables + Fail2ban

---

## 📱 管理工具

部署完成后，系统会自动安装以下命令（与 [Xray-Auto](https://github.com/ISFZY/Xray-Auto) 风格一致）：

| 命令 | 功能 |
|------|------|
| **xinfo** | 查看节点信息、分享链接与二维码 |
| **net** | 切换网络策略（双栈 / 仅 IPv4 / 仅 IPv6） |
| **ports** | 查看或修改 SSH、Xray 端口 |
| **sni** | 修改 SNI 伪装域名 |
| **f2b** | Fail2ban 状态与配置路径 |
| **bbr** | BBR 拥塞控制启用/禁用 |
| **swap** | Swap 虚拟内存查看与创建 |
| **bt** | BT/P2P 与私有 IP 封禁管理 |
| **name** | 节点别名（分享链接/客户端显示名，支持中文如 香港-V4） |

### `xinfo` - 查看节点信息

```bash
xinfo
```

输出当前 UUID、端口、SNI、公钥、ShortID、IPv4/IPv6 地址及分享链接，可选生成二维码。

### 自定义节点别名

分享链接中 `#` 后的名称即节点别名，导入客户端后会显示为节点名称。支持中文（如「香港-V4」）：

```bash
name
```

按提示输入 IPv4/IPv6 节点别名后，再运行 `xinfo` 即可得到带新别名的链接。

---

## 🔧 常见操作

### 查看服务状态

```bash
systemctl status xray
```

### 查看日志

```bash
journalctl -u xray -f
```

### 重启服务

```bash
systemctl restart xray
```

### 卸载

```bash
bash remove.sh
```

> ⚠️ 卸载不会删除系统配置（BBR / 防火墙 / 依赖包）

---

## 📋 配置说明

### 网络策略

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| `dual_stack` | IPv4 + IPv6 | 推荐，兼容性最好 |
| `ipv4_only` | 仅 IPv4 | 纯 IPv4 VPS |
| `ipv6_only` | 仅 IPv6 | 需客户端支持 IPv6 |

### 端口配置

- **默认端口：** 443
- **修改方法：** 部署时交互选择或编辑 `/usr/local/etc/xray/config.json`

### SNI 伪装域名

脚本会自动测速以下域名并推荐最快的：

- `www.microsoft.com`
- `www.apple.com`
- `www.cloudflare.com`

也可手动输入自定义域名。

---

## 🔄 使用场景

### ✅ 适合

- 新 VPS 首次部署
- IP 被封后快速迁移
- 系统重装后恢复
- 个人学习 Reality 协议

### ❌ 不适合

- 多用户商业运营
- 需要 Web 管理面板
- 需要订阅系统
- 需要流量统计

---

## 🛡️ 安全建议

1. **SSH 防护**
   - 修改 SSH 默认端口
   - 使用密钥登录
   - 启用 Fail2ban（脚本自动配置）

2. **防火墙**
   - 仅开放必要端口（SSH + Xray）
   - 定期检查规则：`iptables -L -n`

3. **定期更新**
   ```bash
   # 更新 Xray
   bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
   
   # 更新系统
   apt update && apt upgrade -y
   ```

---

## 🐛 故障排查

### Reality 密钥生成失败 / 安装在此步退出

若在「Reality 配置」步骤提示「Xray 密钥生成或解析失败」并退出，可仅重跑该步骤（无需从头安装）：

```bash
cd /opt/xray-reality-bootstrap && bash install.sh reality
```

脚本会再次生成密钥并写配置、重启 Xray、更新防火墙与工具。若仍失败，请确认 Xray 版本与输出格式（执行 `xray x25519` 查看输出），或先执行一次完整安装再使用上述命令重试。

### Xray 启动失败

若日志出现 `invalid character '\x1b' in string literal`，多为 config 中混入了终端颜色码，当前版本已修复（SNI 等提示统一输出到 stderr，写入 JSON 前会过滤控制字符）。若仍出现，可执行 `bash install.sh reality` 重新生成配置。

`Special user nobody configured, this is not safe!` 为 systemd 提示，可忽略，不影响运行；若需消除可编辑 `/etc/systemd/system/xray.service` 将 `User=nobody` 改为 `User=root` 后 `systemctl daemon-reload && systemctl restart xray`。

```bash
# 查看详细日志
journalctl -u xray -n 50 --no-pager

# 检查配置语法
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
```

### 无法连接节点

1. **检查防火墙：** 确保 Xray 端口已放行
2. **检查服务：** `systemctl status xray`
3. **检查 IP：** 确认客户端使用的 IP 正确

### SNI 握手失败

- 尝试更换伪装域名
- 确保目标域名支持 TLS 1.3

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发规范

- 每个模块职责单一
- 避免 UI 与逻辑耦合
- 所有外部命令需检查返回值
- 优先使用 `spinner_run` 而非直接执行

---

## ⚠️ 免责声明

本项目仅供 **学习、研究与个人网络技术实践** 使用。

- ✅ 学习 Bash 脚本编程
- ✅ 研究 Xray / Reality 协议
- ✅ 个人 VPS 安全加固
- ❌ 商业运营
- ❌ 违反当地法律法规

**使用者需自行遵守所在地法律，作者不对任何使用行为承担责任。**

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 🙏 致谢

- [Xray-core](https://github.com/XTLS/Xray-core) - 核心代理工具
- [Xray-install](https://github.com/XTLS/Xray-install) - 官方安装脚本
- [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat) - GeoIP / Geosite 数据

---

<div align="center">

**Made with ❤️ for Privacy**

如果这个项目对你有帮助，欢迎 ⭐ Star

</div>
