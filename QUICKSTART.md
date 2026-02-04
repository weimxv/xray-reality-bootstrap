# 快速开始指南

## 📋 前置准备

### 1. 准备 VPS

- **系统：** Debian 11/12 或 Ubuntu 20.04+
- **内存：** 建议 ≥ 512MB
- **网络：** 可访问 GitHub

### 2. 获取 root 权限

```bash
# 切换到 root（如果是普通用户）
sudo su -

# 或者每条命令前加 sudo
sudo bash install.sh
```

### 3. 安装必要工具

**首次使用的干净 VPS 需要先安装 git：**

```bash
# Debian/Ubuntu 系统
apt update && apt install -y git

# CentOS/RHEL 系统
yum install -y git
```

> 💡 **提示：** 如果不想使用 git，可以选择「方式二：直接下载」（见下方部署步骤）

---

## 🚀 部署步骤

### 方式一：克隆仓库（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/weimxv/xray-reality-bootstrap.git
cd xray-reality-bootstrap

# 2. 执行部署
bash install.sh
```

### 方式二：直接下载

```bash
# 1. 下载压缩包
wget https://github.com/weimxv/xray-reality-bootstrap/archive/refs/heads/main.zip
unzip main.zip
cd xray-reality-bootstrap-main

# 2. 执行部署
bash install.sh
```

---

## 📝 部署过程

### 阶段 1: 环境检查

脚本会自动检查：
- Root 权限
- 系统版本（Debian/Ubuntu）
- 网络连通性
- APT 锁状态

### 阶段 2: 系统初始化

```
[ ? ] 是否设置为 Asia/Shanghai (y/n) [默认: n] [ 10s ] :
```

**建议：** 按 `y` 设置时区，或等待倒计时使用默认值

### 阶段 3: 网络检测

脚本会自动测试 IPv4/IPv6 连通性并推荐策略：

```
推荐网络策略: IPv4 + IPv6 双栈（默认推荐，最稳妥）
是否接受该策略? (y/n) [默认: n] [ 12s ] :
```

**建议：** 接受推荐策略

### 阶段 4: 内核优化

#### BBR 拥塞控制
```
是否启用 BBR 拥塞控制? (y/n) [默认: n] [ 10s ] :
```

**建议：** 启用（提升网络性能）

#### Swap 虚拟内存
```
内存 < 2GB，是否创建 1GB Swap? (y/n) [默认: n] [ 12s ] :
```

**建议：** 
- 内存 < 1GB: 必须启用
- 内存 1-2GB: 建议启用
- 内存 > 2GB: 可跳过

### 阶段 5: Xray 安装

自动下载并安装最新版 Xray Core，无需操作。

### 阶段 6: Reality 配置

#### 端口选择
```
使用默认端口 443 (y/n) [默认: n] [ 8s ] :
```

**建议：**
- **443**: 伪装性最好（推荐）
- **自定义**: 如 8443、2053 等

#### SNI 域名
```
推荐 SNI: www.microsoft.com (23ms)
使用推荐域名 www.microsoft.com (y/n) [默认: n] [ 10s ] :
```

**建议：** 接受推荐（已自动测速优选）

### 阶段 7: 防火墙配置

```
是否启用 Fail2ban (SSH 防暴力破解) (y/n) [默认: n] [ 8s ] :
```

**建议：** 启用（保护 SSH）

---

## ✅ 部署完成

看到以下提示表示部署成功：

```
==================================
 部署完成！
==================================
运行 'xinfo' 查看节点信息
```

---

## 📱 查看节点信息

```bash
xinfo
```

输出示例：

```
====================================
 Xray Reality 节点信息
====================================
UUID       : de305d54-75b4-431b-adb2-eb6b9e546014
端口       : 443
SNI        : www.microsoft.com
PublicKey  : B9s7XgK2...
ShortID    : a1b2c3d4e5f6g7h8
------------------------------------
IPv4 地址  : 1.2.3.4
IPv6 地址  : N/A
====================================

【IPv4 分享链接】
vless://de305d54-...

生成二维码? (y/n):
```

### 二维码生成

输入 `y` 后会在终端显示二维码，手机扫描即可导入。

---

## 📲 导入客户端

### v2rayN (Windows)

1. 复制分享链接
2. 打开 v2rayN
3. 点击「服务器」→「从剪贴板导入」

### v2rayNG (Android)

1. 复制分享链接
2. 打开 v2rayNG
3. 点击右上角「+」→「从剪贴板导入」

### Shadowrocket (iOS)

1. 扫描二维码或复制链接
2. 自动识别并导入

### Clash Meta / Mihomo

需手动配置，参数如下：

```yaml
proxies:
  - name: "Xray Reality"
    type: vless
    server: 1.2.3.4
    port: 443
    uuid: de305d54-...
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: www.microsoft.com
    reality-opts:
      public-key: B9s7XgK2...
      short-id: a1b2c3d4e5f6g7h8
    client-fingerprint: chrome
```

---

## 🔧 常用命令

### 服务管理

```bash
# 查看状态
systemctl status xray

# 重启服务
systemctl restart xray

# 查看日志
journalctl -u xray -f
```

### 配置文件

```bash
# Xray 配置
nano /usr/local/etc/xray/config.json

# 修改后重启
systemctl restart xray
```

### 卸载

```bash
bash remove.sh
```

---

## ❓ 常见问题

### 1. 部署失败：网络超时

**原因：** GitHub 访问受限

**解决：**
```bash
# 使用代理
export https_proxy=http://proxy-server:port
bash install.sh
```

### 2. Xray 启动失败

```bash
# 查看日志
journalctl -u xray -n 50 --no-pager

# 检查配置
/usr/local/bin/xray run -test -config /usr/local/etc/xray/config.json
```

### 3. 无法连接节点

**检查清单：**
1. 防火墙是否放行端口：`iptables -L -n | grep 443`
2. 服务是否运行：`systemctl status xray`
3. 客户端参数是否正确（UUID / PublicKey / SNI）

### 4. SNI 握手失败

**解决方案：**
- 更换 SNI 域名（如 `www.apple.com`）
- 确保客户端支持 Reality 协议

---

## 🛡️ 安全提示

1. **修改 SSH 端口**
   ```bash
   nano /etc/ssh/sshd_config
   # 修改 Port 22 为其他端口
   systemctl restart ssh
   ```

2. **使用密钥登录**
   ```bash
   # 禁用密码登录
   sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   systemctl restart ssh
   ```

3. **定期更新**
   ```bash
   apt update && apt upgrade -y
   ```

---

## 📞 获取帮助

- **Issues:** https://github.com/yourusername/xray-reality-bootstrap/issues
- **文档:** 查看 `README.md`
- **Xray 官方:** https://github.com/XTLS/Xray-core

---

祝你使用愉快！🎉
