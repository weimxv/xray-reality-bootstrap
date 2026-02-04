#!/usr/bin/env bash
# 网络策略切换（IPv4/IPv6 优先、仅 IPv4、仅 IPv6）
set -e

XRAY_ETC="/usr/local/etc/xray-reality"
CFG="/usr/local/etc/xray/config.json"

get_runtime_dir() {
    if [[ -f "$XRAY_ETC/runtime_dir" ]]; then
        source "$XRAY_ETC/runtime_dir"
    else
        RUNTIME_DIR="/opt/xray-reality-bootstrap/runtime"
    fi
}
get_runtime_dir

[[ -f "$RUNTIME_DIR/network.env" ]] || { echo "错误: 未找到 network.env，请先完成部署"; exit 1; }
[[ -f "$CFG" ]] || { echo "错误: 未找到 Xray 配置"; exit 1; }

source "$RUNTIME_DIR/network.env"

echo "=========================================="
echo "  网络策略 (net)"
echo "=========================================="
echo "当前策略: $NET_STRATEGY"
echo "  (ipv4_only=仅IPv4  ipv6_only=仅IPv6  dual_stack=双栈)"
echo ""
echo "请选择新策略:"
echo "  1) dual_stack  - 双栈（IPv4+IPv6，推荐）"
echo "  2) ipv4_only   - 仅 IPv4"
echo "  3) ipv6_only   - 仅 IPv6"
echo "  0) 取消"
echo ""
read -p "请输入 [0-3]: " choice

case "$choice" in
    1) NEW_STRATEGY="dual_stack" ;;
    2) NEW_STRATEGY="ipv4_only" ;;
    3) NEW_STRATEGY="ipv6_only" ;;
    0) echo "已取消"; exit 0 ;;
    *) echo "无效输入"; exit 1 ;;
esac

# 更新 network.env
sed -i "s/^NET_STRATEGY=.*/NET_STRATEGY=$NEW_STRATEGY/" "$RUNTIME_DIR/network.env"
echo "[OK] 已写入 network.env: NET_STRATEGY=$NEW_STRATEGY"

# 更新 Xray 配置中的 domainStrategy
case "$NEW_STRATEGY" in
    ipv4_only)  DOMAIN_STRATEGY="UseIPv4" ;;
    ipv6_only)  DOMAIN_STRATEGY="UseIPv6" ;;
    *)          DOMAIN_STRATEGY="IPIfNonMatch" ;;
esac
jq --arg s "$DOMAIN_STRATEGY" '.routing.domainStrategy = $s' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
echo "[OK] 已更新 Xray 路由策略: $DOMAIN_STRATEGY"

systemctl restart xray
echo "[OK] 已重启 Xray"
echo ""
echo "当前策略: $NEW_STRATEGY"
