#!/usr/bin/env bash
# 流量拦截管理：BT/P2P & 私有 IP 封禁
set -e

echo "=========================================="
echo "  流量拦截管理 (bt)"
echo "=========================================="

command -v iptables >/dev/null 2>&1 || {
    echo "错误: 未找到 iptables"
    exit 1
}

# 检查是否已存在带有特定 comment 的规则
bt_block_enabled() {
    iptables -S OUTPUT 2>/dev/null | grep -q "XRAY_BT_BLOCK" || \
    iptables -S FORWARD 2>/dev/null | grep -q "XRAY_BT_BLOCK"
}

lan_block_enabled() {
    iptables -S OUTPUT 2>/dev/null | grep -q "XRAY_LAN_BLOCK" || \
    iptables -S FORWARD 2>/dev/null | grep -q "XRAY_LAN_BLOCK"
}

echo "当前状态:"
if bt_block_enabled; then
    echo "  BT/P2P 下载   : 已封禁 (Blocked)"
else
    echo "  BT/P2P 下载   : 未封禁 (Allowed)"
fi
if lan_block_enabled; then
    echo "  私有 IP (局域网): 已封禁 (Blocked)"
else
    echo "  私有 IP (局域网): 未封禁 (Allowed)"
fi
echo "------------------------------------------"
echo "1. 开启/关闭 BT 下载封禁"
echo "2. 开启/关闭 私有 IP 封禁"
echo "0. 退出 (Exit)"
echo "------------------------------------------"
read -p "请输入选项 [0-2]: " choice

enable_bt_block() {
    # 常见 BT 端口与特征匹配（简单版）
    iptables -A OUTPUT -p tcp --dport 6881:6999 -m comment --comment XRAY_BT_BLOCK -j REJECT
    iptables -A OUTPUT -p udp --dport 6881:6999 -m comment --comment XRAY_BT_BLOCK -j REJECT
    iptables -A FORWARD -p tcp --dport 6881:6999 -m comment --comment XRAY_BT_BLOCK -j REJECT
    iptables -A FORWARD -p udp --dport 6881:6999 -m comment --comment XRAY_BT_BLOCK -j REJECT
}

disable_bt_block() {
    # 删除所有带 XRAY_BT_BLOCK 注释的规则
    for chain in OUTPUT FORWARD; do
        while iptables -S "$chain" 2>/dev/null | grep -q "XRAY_BT_BLOCK"; do
            # 获取第一条匹配规则的完整定义并删除
            rule=$(iptables -S "$chain" | grep "XRAY_BT_BLOCK" | head -n1 | sed 's/^-A //')
            iptables -D "$chain" $rule || break
        done
    done
}

enable_lan_block() {
    for chain in OUTPUT FORWARD; do
        iptables -A "$chain" -d 10.0.0.0/8 -m comment --comment XRAY_LAN_BLOCK -j REJECT
        iptables -A "$chain" -d 172.16.0.0/12 -m comment --comment XRAY_LAN_BLOCK -j REJECT
        iptables -A "$chain" -d 192.168.0.0/16 -m comment --comment XRAY_LAN_BLOCK -j REJECT
    done
}

disable_lan_block() {
    for chain in OUTPUT FORWARD; do
        while iptables -S "$chain" 2>/dev/null | grep -q "XRAY_LAN_BLOCK"; do
            rule=$(iptables -S "$chain" | grep "XRAY_LAN_BLOCK" | head -n1 | sed 's/^-A //')
            iptables -D "$chain" $rule || break
        done
    done
}

case "$choice" in
    1)
        if bt_block_enabled; then
            echo "正在关闭 BT/P2P 封禁..."
            disable_bt_block
            echo "[OK] 已关闭 BT/P2P 下载封禁"
        else
            echo "正在开启 BT/P2P 封禁..."
            enable_bt_block
            echo "[OK] 已开启 BT/P2P 下载封禁"
        fi
        ;;
    2)
        if lan_block_enabled; then
            echo "正在关闭 私有 IP 封禁..."
            disable_lan_block
            echo "[OK] 已关闭 私有 IP 封禁"
        else
            echo "正在开启 私有 IP 封禁..."
            enable_lan_block
            echo "[OK] 已开启 私有 IP 封禁"
        fi
        ;;
    0)
        exit 0
        ;;
    *)
        echo "无效输入"
        exit 1
        ;;
esac

