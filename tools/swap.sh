#!/usr/bin/env bash
# Swap 虚拟内存查看与建议
set -e

echo "=========================================="
echo "  Swap (swap)"
echo "=========================================="

echo "内存与 Swap:"
free -h
echo ""

if swapon --show 2>/dev/null | grep -q .; then
    echo "当前已启用 Swap:"
    swapon --show
else
    echo "当前未启用 Swap"
    RAM_MB=$(free -m | awk '/Mem:/ {print $2}')
    echo "物理内存: ${RAM_MB}MB"
    if [[ "$RAM_MB" -lt 2048 ]]; then
        read -p "是否创建 1GB Swap 文件? (y/n): " ans
        if [[ "$ans" =~ ^[yY]$ ]]; then
            swapoff /swapfile 2>/dev/null; rm -f /swapfile
            fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            grep -q /swapfile /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
            echo "[OK] 已创建并启用 1GB Swap"
        fi
    fi
fi
[[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
