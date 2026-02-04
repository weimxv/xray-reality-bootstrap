# 快速参考手册

## 🚀 一键部署

```bash
git clone https://github.com/yourusername/xray-reality-bootstrap.git
cd xray-reality-bootstrap
bash install.sh
```

---

## 📱 常用命令

| 命令 | 功能 |
|------|------|
| `xinfo` | 查看节点信息 + 生成二维码 |
| `systemctl status xray` | 查看服务状态 |
| `systemctl restart xray` | 重启服务 |
| `journalctl -u xray -f` | 实时查看日志 |
| `bash remove.sh` | 卸载 Xray |

---

## 📁 重要文件

| 路径 | 说明 |
|------|------|
| `/usr/local/bin/xray` | Xray 可执行文件 |
| `/usr/local/etc/xray/config.json` | Reality 配置文件 |
| `/usr/local/share/xray/geo*.dat` | GeoIP / Geosite 数据 |
| `/etc/systemd/system/xray.service` | Systemd 服务文件 |
| `/etc/fail2ban/jail.local` | Fail2ban 配置 |

---

## 🔧 配置修改

### 修改端口

```bash
nano /usr/local/etc/xray/config.json
# 修改 "port": 443
systemctl restart xray
```

### 修改 SNI

```bash
nano /usr/local/etc/xray/config.json
# 修改 "dest": "www.microsoft.com:443"
# 修改 "serverNames": ["www.microsoft.com"]
systemctl restart xray
```

### 查看运行参数

```bash
cat runtime/xray.env
```

---

## 🛡️ 防火墙管理

### 查看规则

```bash
iptables -L -n
```

### 放行新端口

```bash
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
netfilter-persistent save
```

### Fail2ban 状态

```bash
systemctl status fail2ban
fail2ban-client status sshd
```

---

## 🐛 故障排查

### Xray 无法启动

```bash
# 查看日志
journalctl -u xray -n 50 --no-pager

# 检查配置
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json

# 检查端口占用
ss -tulpn | grep <端口>
```

### 客户端无法连接

```bash
# 1. 检查服务
systemctl status xray

# 2. 检查防火墙
iptables -L -n | grep <端口>

# 3. 检查监听
ss -tulpn | grep xray

# 4. 测试端口
curl -v https://<SNI域名>:443
```

### SNI 握手失败

```bash
# 测试目标域名
curl -I https://www.microsoft.com

# 更换 SNI 域名
# 推荐: www.apple.com, www.cloudflare.com
```

---

## 📊 性能优化

### 检查 BBR

```bash
sysctl net.ipv4.tcp_congestion_control
# 输出: bbr
```

### 检查 Swap

```bash
free -h
swapon --show
```

### 调整 Swap 亲和度

```bash
# 查看当前值
cat /proc/sys/vm/swappiness

# 临时修改（推荐 10-30）
sysctl -w vm.swappiness=10

# 永久修改
echo "vm.swappiness = 10" >> /etc/sysctl.conf
sysctl -p
```

---

## 🔄 更新维护

### 更新 Xray

```bash
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
systemctl restart xray
```

### 更新 GeoData

```bash
cd /usr/local/share/xray
curl -fsSL -o geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
curl -fsSL -o geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
systemctl restart xray
```

### 更新系统

```bash
apt update && apt upgrade -y
```

---

## 🔐 安全加固

### SSH 密钥登录

```bash
# 生成密钥（本地）
ssh-keygen -t ed25519

# 上传公钥（本地）
ssh-copy-id root@<服务器IP>

# 禁用密码登录（服务器）
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh
```

### 修改 SSH 端口

```bash
nano /etc/ssh/sshd_config
# Port 22 -> Port 2222

# 放行新端口
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
netfilter-persistent save

# 重启 SSH
systemctl restart ssh
```

### 查看 Fail2ban 封禁

```bash
# 查看封禁列表
fail2ban-client status sshd

# 解封 IP
fail2ban-client set sshd unbanip <IP>
```

---

## 📋 客户端配置

### 参数对照表

| 参数 | 位置 | 说明 |
|------|------|------|
| 地址 (Address) | `xinfo` | 服务器 IP |
| 端口 (Port) | `xinfo` | 默认 443 |
| UUID | `xinfo` | 用户 ID |
| 流控 (Flow) | 固定 | `xtls-rprx-vision` |
| 传输 (Network) | 固定 | `tcp` |
| 安全 (Security) | 固定 | `reality` |
| SNI | `xinfo` | 伪装域名 |
| 指纹 (Fingerprint) | 固定 | `chrome` |
| PublicKey | `xinfo` | 公钥 |
| ShortID | `xinfo` | 短 ID |

### 导入方式

1. **分享链接** - 复制 `xinfo` 输出的链接
2. **二维码** - `xinfo` 选择生成二维码
3. **手动配置** - 参考上表手动填写

---

## 💡 实用技巧

### 查看实时连接

```bash
ss -tunp | grep xray
```

### 测试配置语法

```bash
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
```

### 备份配置

```bash
cp /usr/local/etc/xray/config.json ~/config.json.backup
```

### 恢复配置

```bash
cp ~/config.json.backup /usr/local/etc/xray/config.json
systemctl restart xray
```

---

## 📞 获取帮助

- **文档:** 查看 `README.md` 和 `QUICKSTART.md`
- **架构:** 查看 `ARCHITECTURE.md`
- **Issues:** 提交 Bug 或建议

---

**提示:** 本手册适合已完成部署的用户快速查询使用。  
**首次部署请参考:** [QUICKSTART.md](QUICKSTART.md)
