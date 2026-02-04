#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/color.sh"

print_banner() {
    clear
    echo -e "${BLUE}"
    cat <<'BANNER'
==================================================
   __  __                  ____             _ _ _         
  \ \/ /_ __ __ _ _   _   |  _ \ ___  __ _| (_) |_ _   _ 
   \  /| '__/ _` | | | |  | |_) / _ \/ _` | | | __| | | |
   /  \| | | (_| | |_| |  |  _ <  __/ (_| | | | |_| |_| |
  /_/\_\_|  \__,_|\__, |  |_| \_\___|\__,_|_|_|\__|\__, |
                  |___/                            |___/ 
  Bootstrap - Minimal • Secure • Reproducible
==================================================
BANNER
    echo -e "${PLAIN}"
}

ui_warning() {
    echo -e "${YELLOW}"
    echo "⚠️  警告 (WARNING)"
    echo ""
    echo "本脚本将执行以下操作："
    echo "  • 安装系统依赖并更新软件包"
    echo "  • 配置网络策略 (IPv4/IPv6)"
    echo "  • 优化内核参数 (BBR / Swap)"
    echo "  • 配置防火墙规则 (iptables / Fail2ban)"
    echo "  • 部署 Xray Reality 节点"
    echo ""
    echo "请确保："
    echo "  1. 你有服务器的完整控制权"
    echo "  2. 已备份重要数据"
    echo "  3. 了解 Reality 协议用途"
    echo -e "${PLAIN}"
}
