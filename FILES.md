# 项目文件清单

## 📂 目录结构

```
xray-reality-bootstrap/
├── 📄 入口脚本
│   ├── install.sh           (主安装脚本)
│   └── remove.sh            (卸载脚本)
│
├── 📂 core/                 (核心模块 - 7个文件)
│   ├── preflight.sh         (环境检查)
│   ├── system.sh            (系统初始化)
│   ├── network.sh           (网络检测)
│   ├── kernel.sh            (内核优化)
│   ├── xray.sh              (安装 Xray)
│   ├── reality.sh           (Reality 配置)
│   └── firewall.sh          (防火墙配置)
│
├── 📂 ui/                   (交互层 - 4个文件)
│   ├── color.sh             (颜色封装)
│   ├── prompt.sh            (交互输入)
│   ├── spinner.sh           (加载动画)
│   └── banner.sh            (Logo 显示)
│
├── 📂 lib/                  (工具库 - 1个文件)
│   └── validator.sh         (参数校验)
│
├── 📂 tools/                (管理工具 - 1个文件)
│   └── install_tools.sh     (生成 xinfo 命令)
│
├── 📂 runtime/              (运行时数据 - 自动生成)
│   ├── network.env
│   ├── kernel.env
│   ├── xray.env
│   └── firewall.env
│
└── 📚 文档                  (6个文件)
    ├── README.md            (项目说明)
    ├── QUICKSTART.md        (快速开始)
    ├── ARCHITECTURE.md      (架构设计)
    ├── CHANGELOG.md         (更新日志)
    ├── CHEATSHEET.md        (快速参考)
    ├── PROJECT_SUMMARY.md   (实现总结)
    ├── LICENSE              (开源协议)
    └── .gitignore           (Git 配置)
```

---

## 📊 文件统计

### 脚本文件（13个）

| 类型 | 数量 | 总行数 |
|------|------|--------|
| 核心模块 | 7 | ~850 |
| UI 组件 | 4 | ~150 |
| 工具库 | 1 | ~25 |
| 管理工具 | 1 | ~100 |
| **合计** | **13** | **~1000** |

### 文档文件（8个）

| 文件 | 字数 | 用途 |
|------|------|------|
| README.md | ~4000 | 项目概览 |
| QUICKSTART.md | ~3000 | 快速开始 |
| ARCHITECTURE.md | ~2500 | 架构设计 |
| CHEATSHEET.md | ~1500 | 快速参考 |
| PROJECT_SUMMARY.md | ~2000 | 实现总结 |
| CHANGELOG.md | ~500 | 更新日志 |
| LICENSE | ~1000 | 开源协议 |
| FILES.md | ~1000 | 文件清单 |

---

## 🎯 核心文件说明

### install.sh
**职责:** 主入口，流程调度  
**核心逻辑:**
- 加载所有模块
- 按顺序执行各阶段
- 显示 Banner 和警告
- 安装管理工具

**关键代码:**
```bash
cmd_install() {
    print_banner
    ui_warning
    
    preflight_run    # 环境检查
    system_run       # 系统初始化
    network_run      # 网络检测
    kernel_run       # 内核优化
    xray_run         # 安装 Xray
    reality_run      # Reality 配置
    firewall_run     # 防火墙配置
    
    install_tools    # 安装管理工具
}
```

---

### core/preflight.sh
**职责:** 环境检查，确保满足部署条件  
**检查项:**
- Root 权限
- 系统版本（Debian/Ubuntu）
- Systemd 支持
- APT 锁状态
- 网络连通性

**输出:** 锁文件（防止重复运行）

---

### core/system.sh
**职责:** 系统初始化  
**功能:**
- 配置 APT（DEBIAN_FRONTEND / needrestart）
- 更新系统软件包
- 批量安装依赖（curl / jq / qrencode 等）
- 设置时区

**输出:** 无持久化文件

---

### core/network.sh
**职责:** 网络检测与策略推荐  
**功能:**
- 探测 IPv4 连通性
- 探测 IPv6 连通性
- 识别网络类型（dual_stack / ipv4_only / ipv6_only）
- 推荐策略并让用户确认

**输出:** `runtime/network.env`

---

### core/kernel.sh
**职责:** 内核优化  
**功能:**
- 检测并启用 BBR 拥塞控制
- 低内存 VPS 自动创建 Swap
- 记录优化状态

**输出:** `runtime/kernel.env`

---

### core/xray.sh
**职责:** 安装 Xray Core  
**功能:**
- 检查是否已安装
- 调用官方安装脚本
- 版本校验

**输出:** `/usr/local/bin/xray`

---

### core/reality.sh
**职责:** Reality 配置生成（最复杂模块）  
**功能:**
- 交互选择端口
- SNI 域名自动测速优选
- 生成 UUID / 密钥对 / ShortID
- 下载 GeoIP / Geosite 数据
- 生成 config.json
- 启动 Xray 服务

**输出:** 
- `runtime/xray.env`
- `/usr/local/etc/xray/config.json`
- `/usr/local/share/xray/geo*.dat`

---

### core/firewall.sh
**职责:** 防火墙配置  
**功能:**
- 检测 SSH 端口
- 放行 SSH + Xray 端口
- 配置 iptables 规则（默认 DROP）
- 配置 Fail2ban（可选）

**输出:** `runtime/firewall.env`

---

### ui/color.sh
**职责:** 颜色和标签封装  
**提供函数:**
- `ui_ok()` - 成功提示（绿色）
- `ui_err()` - 错误提示（红色）
- `ui_warn()` - 警告提示（黄色）
- `ui_info()` - 信息提示（蓝色）

---

### ui/prompt.sh
**职责:** 交互输入封装  
**提供函数:**
- `ui_read_timeout()` - 倒计时输入
- `ui_confirm()` - 确认（返回布尔值）
- `ui_read()` - 普通输入

---

### ui/spinner.sh
**职责:** 加载动画 + 重试机制  
**功能:**
- 显示旋转 Spinner
- 任务失败自动重试（最多3次）
- 失败后显示错误日志

---

### ui/banner.sh
**职责:** Logo 和警告显示  
**提供函数:**
- `print_banner()` - ASCII Logo
- `ui_warning()` - 风险提示

---

### lib/validator.sh
**职责:** 参数校验  
**提供函数:**
- `validate_port()` - 端口校验（1-65535）
- `validate_domain()` - 域名校验（正则）
- `validate_ip()` - IP 地址校验（v4/v6）

---

### tools/install_tools.sh
**职责:** 生成管理工具  
**功能:**
- 读取 `runtime/xray.env`
- 生成 `/usr/local/bin/xinfo` 脚本
- 设置可执行权限

---

## 🔄 数据流向

```
1. install.sh
   ↓
2. preflight_run()
   ↓
3. system_run()
   ↓
4. network_run() → runtime/network.env
   ↓
5. kernel_run() → runtime/kernel.env
   ↓
6. xray_run() → /usr/local/bin/xray
   ↓
7. reality_run() → runtime/xray.env
                 → /usr/local/etc/xray/config.json
   ↓
8. firewall_run() → runtime/firewall.env
   ↓
9. install_tools() → /usr/local/bin/xinfo
```

---

## 📝 runtime/ 文件说明

### network.env
```bash
NET_TYPE=dual_stack        # 网络类型
NET_STRATEGY=dual_stack    # 用户选择的策略
HAS_IPV4=true             # 是否有 IPv4
HAS_IPV6=true             # 是否有 IPv6
```

### kernel.env
```bash
BBR_ENABLED=true          # BBR 是否启用
SWAP_ENABLED=false        # Swap 是否创建
RAM_MB=2048               # 物理内存大小
```

### xray.env
```bash
XRAY_PORT=443                      # 监听端口
XRAY_UUID=de305d54-...             # UUID
XRAY_PUBLIC_KEY=B9s7XgK2...        # 公钥
XRAY_SHORT_ID=a1b2c3d4e5f6g7h8     # ShortID
XRAY_SNI=www.microsoft.com         # SNI 域名
```

### firewall.env
```bash
SSH_PORT=22                # SSH 端口
XRAY_PORTS="443"           # Xray 端口列表
FAIL2BAN_ENABLED=true      # Fail2ban 是否启用
```

---

## 🎓 文档索引

### 用户文档
- **快速开始:** [QUICKSTART.md](QUICKSTART.md)
- **快速参考:** [CHEATSHEET.md](CHEATSHEET.md)

### 技术文档
- **项目说明:** [README.md](README.md)
- **架构设计:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **实现总结:** [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

### 维护文档
- **更新日志:** [CHANGELOG.md](CHANGELOG.md)
- **文件清单:** [FILES.md](FILES.md)

---

## ✅ 文件清单检查

### 核心功能（完整）
- [x] 环境检查
- [x] 系统初始化
- [x] 网络检测
- [x] 内核优化
- [x] Xray 安装
- [x] Reality 配置
- [x] 防火墙配置

### 交互体验（完整）
- [x] 颜色封装
- [x] 倒计时输入
- [x] 加载动画
- [x] Logo 显示

### 工具库（完整）
- [x] 参数校验
- [x] 管理工具生成

### 文档（完整）
- [x] 项目说明
- [x] 快速开始
- [x] 架构设计
- [x] 快速参考
- [x] 实现总结
- [x] 更新日志
- [x] 文件清单

---

**最后更新:** 2024-02-04  
**文件总数:** 21 个（13 脚本 + 8 文档）  
**总代码量:** ~1000 行
