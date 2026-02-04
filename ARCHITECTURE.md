# 项目架构说明

## 📋 设计原则

### 1. 模块化 (Modularity)
- 每个模块职责单一
- 模块间通过 `runtime/*.env` 文件通信
- 避免循环依赖

### 2. 分离关注点 (Separation of Concerns)
- **core/**: 纯业务逻辑，无 UI 交互
- **ui/**: 纯交互体验，不包含业务逻辑
- **lib/**: 工具函数，可独立测试

### 3. 可追溯性 (Traceability)
- 所有状态写入 `runtime/*.env`
- 可随时查看部署历史
- 支持部分模块重新执行

---

## 🗂️ 目录结构

### 📂 core/ - 核心模块

| 文件 | 职责 | 依赖 | 输出 |
|------|------|------|------|
| `preflight.sh` | 环境检查 | ui/color.sh, ui/prompt.sh | 锁文件 |
| `system.sh` | 系统初始化 | ui/spinner.sh | - |
| `network.sh` | 网络检测 | ui/spinner.sh | runtime/network.env |
| `kernel.sh` | 内核优化 | ui/spinner.sh, runtime/network.env | runtime/kernel.env |
| `xray.sh` | 安装 Xray | ui/spinner.sh | - |
| `reality.sh` | Reality 配置 | ui/prompt.sh, lib/validator.sh | runtime/xray.env |
| `firewall.sh` | 防火墙配置 | ui/prompt.sh, runtime/xray.env | runtime/firewall.env |

### 📂 ui/ - 交互层

| 文件 | 功能 | 使用示例 |
|------|------|----------|
| `color.sh` | 颜色封装 | `ui_ok "成功"` |
| `prompt.sh` | 交互输入 | `ui_confirm "继续?" 10` |
| `spinner.sh` | 加载动画 | `spinner_run "任务" command` |
| `banner.sh` | Logo 显示 | `print_banner` |

### 📂 lib/ - 工具库

| 文件 | 功能 | 函数列表 |
|------|------|----------|
| `validator.sh` | 参数校验 | `validate_port`, `validate_domain`, `validate_ip` |

### 📂 tools/ - 管理工具

| 文件 | 功能 | 输出 |
|------|------|------|
| `install_tools.sh` | 生成管理命令 | `/usr/local/bin/xinfo` |

---

## 🔄 执行流程

### 主流程 (install.sh)

```
1. 环境检查 (preflight_run)
   ├─ 检查 root 权限
   ├─ 检查系统版本
   ├─ 检查 systemd
   ├─ 检查 apt 锁
   └─ 检查网络连通

2. 系统初始化 (system_run)
   ├─ 配置 apt
   ├─ 更新系统
   ├─ 安装依赖
   └─ 设置时区

3. 网络检测 (network_run)
   ├─ 探测 IPv4
   ├─ 探测 IPv6
   ├─ 推荐策略
   └─ 写入 runtime/network.env

4. 内核优化 (kernel_run)
   ├─ 启用 BBR（可选）
   ├─ 创建 Swap（低内存）
   └─ 写入 runtime/kernel.env

5. 安装 Xray (xray_run)
   ├─ 检查是否已安装
   └─ 执行官方安装脚本

6. Reality 配置 (reality_run)
   ├─ 选择端口
   ├─ 优选 SNI
   ├─ 生成密钥
   ├─ 下载 GeoData
   ├─ 生成配置文件
   ├─ 启动服务
   └─ 写入 runtime/xray.env

7. 防火墙配置 (firewall_run)
   ├─ 放行 SSH
   ├─ 放行 Xray 端口
   ├─ 配置 Fail2ban
   └─ 写入 runtime/firewall.env

8. 安装工具 (install_tools.sh)
   └─ 生成 xinfo 命令
```

---

## 📦 数据流

### runtime/ 环境变量文件

#### network.env
```bash
NET_TYPE=dual_stack        # ipv4_only / ipv6_only / dual_stack
NET_STRATEGY=dual_stack    # 用户选择的策略
HAS_IPV4=true
HAS_IPV6=true
```

#### kernel.env
```bash
BBR_ENABLED=true
SWAP_ENABLED=false
RAM_MB=2048
```

#### xray.env
```bash
XRAY_PORT=443
XRAY_UUID=de305d54-...
XRAY_PUBLIC_KEY=B9s7XgK2...
XRAY_SHORT_ID=a1b2c3d4e5f6g7h8
XRAY_SNI=www.microsoft.com
```

#### firewall.env
```bash
SSH_PORT=22
XRAY_PORTS="443"
FAIL2BAN_ENABLED=true
```

---

## 🔧 关键设计

### 1. 锁机制 (preflight.sh)

防止多实例运行：

```bash
LOCK_DIR="/tmp/xray-reality-bootstrap.lock"
PID_FILE="$LOCK_DIR/pid"

acquire_lock() {
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        echo $$ > "$PID_FILE"
        return 0
    fi
    # 检查进程是否存活
    ...
}
```

### 2. 重试机制 (spinner.sh)

自动重试失败任务：

```bash
spinner_run() {
    local max_retries=3
    local attempt=1
    
    while [[ $attempt -le $max_retries ]]; do
        # 执行命令
        if [[ $rc -eq 0 ]]; then
            return 0
        else
            ((attempt++))
        fi
    done
}
```

### 3. 倒计时交互 (prompt.sh)

避免长时间等待：

```bash
ui_read_timeout() {
    local timeout="$3"
    local end=$(($(date +%s) + timeout))
    
    while true; do
        local remain=$((end - $(date +%s)))
        [[ $remain -le 0 ]] && break
        echo -ne "\r... [ ${remain}s ] : "
        read -t 1 -n 1 input && break
    done
}
```

### 4. SNI 优选 (reality.sh)

自动测速选择最快域名：

```bash
select_sni() {
    for domain in "${domains[@]}"; do
        time_ms=$(curl -w '%{time_connect}' ...)
        if [[ "$time_ms" -lt "$best_time" ]]; then
            best_domain="$domain"
        fi
    done
}
```

---

## 🧪 测试策略

### 1. 单元测试

每个模块应可独立测试：

```bash
# 测试网络检测
source core/network.sh
network_run

# 检查输出
cat runtime/network.env
```

### 2. 集成测试

完整部署流程测试：

```bash
# 在干净的 VPS 上执行
bash install.sh

# 验证服务
systemctl status xray
xinfo
```

### 3. 回归测试

确保修改不破坏现有功能：

```bash
# 重新部署
bash remove.sh
bash install.sh
```

---

## 📈 性能优化

### 1. 批量安装依赖

```bash
# 不推荐：逐个安装
for pkg in "${deps[@]}"; do
    apt-get install -y "$pkg"
done

# 推荐：批量安装
apt-get install -y "${deps[@]}"
```

### 2. 并行检测

```bash
# 同时探测 IPv4 和 IPv6
check_ipv4 & pid1=$!
check_ipv6 & pid2=$!
wait $pid1 $pid2
```

### 3. 跳过已完成步骤

```bash
if [[ -f "$XRAY_ENV" ]]; then
    ui_ok "Xray 已部署，跳过"
    return
fi
```

---

## 🔐 安全设计

### 1. 不存储敏感信息

- 私钥仅写入 `/usr/local/etc/xray/config.json`
- `runtime/xray.env` 只存储公钥

### 2. 最小权限原则

- 仅开放必要端口（SSH + Xray）
- Fail2ban 自动封禁暴力破解

### 3. 防火墙默认拒绝

```bash
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
```

---

## 🚀 扩展指南

### 添加新模块

1. 在 `core/` 创建 `<module>.sh`
2. 定义 `<module>_run()` 函数
3. 在 `install.sh` 中调用
4. （可选）输出到 `runtime/<module>.env`

### 添加新工具

1. 在 `tools/install_tools.sh` 中添加生成逻辑
2. 输出到 `/usr/local/bin/<tool_name>`
3. 设置可执行权限

---

## 📚 参考资料

- [Xray 官方文档](https://xtls.github.io/)
- [Reality 协议说明](https://github.com/XTLS/REALITY)
- [Bash 最佳实践](https://google.github.io/styleguide/shellguide.html)

---

## 🤝 贡献规范

### 代码风格

- 使用 4 空格缩进
- 函数名使用 `snake_case`
- 变量名使用 `UPPER_CASE`（全局） 或 `lower_case`（局部）
- 每个函数前添加注释说明

### 提交信息

```
<type>: <subject>

<body>

<footer>
```

**类型：**
- `feat`: 新功能
- `fix`: 修复 Bug
- `docs`: 文档更新
- `refactor`: 代码重构
- `test`: 测试相关

---

最后更新: 2024-02-04
