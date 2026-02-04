#!/usr/bin/env bash
# BBR 拥塞控制查看与开关
set -e

echo "=========================================="
echo "  BBR (bbr)"
echo "=========================================="

CURRENT=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
AVAILABLE=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || echo "unknown")

echo "当前拥塞控制: $CURRENT"
echo "可用算法: $AVAILABLE"
echo ""

if echo "$AVAILABLE" | grep -q bbr; then
    if [[ "$CURRENT" == "bbr" ]]; then
        echo "BBR 已启用"
        read -p "是否禁用 BBR? (y/n): " ans
        if [[ "$ans" =~ ^[yY]$ ]]; then
            echo "net.core.default_qdisc = fq_codel" > /etc/sysctl.d/99-xray-reality-bbr.conf
            echo "net.ipv4.tcp_congestion_control = cubic" >> /etc/sysctl.d/99-xray-reality-bbr.conf
            sysctl --system
            echo "[OK] BBR 已禁用"
        fi
    else
        echo "BBR 未启用"
        read -p "是否启用 BBR? (y/n): " ans
        if [[ "$ans" =~ ^[yY]$ ]]; then
            echo "net.core.default_qdisc = fq" > /etc/sysctl.d/99-xray-reality-bbr.conf
            echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.d/99-xray-reality-bbr.conf
            sysctl --system
            echo "[OK] BBR 已启用"
        fi
    fi
else
    echo "当前内核不支持 BBR，请升级内核"
fi
[[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
