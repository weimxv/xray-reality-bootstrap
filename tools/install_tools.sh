#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$BASE_DIR/runtime"

# 检查是否已部署
if [[ ! -f "$RUNTIME_DIR/xray.env" ]]; then
    echo "错误: 未检测到 Xray 部署信息，请先运行 install.sh"
    exit 1
fi

# 写入 runtime 路径与默认节点别名
mkdir -p /usr/local/etc/xray-reality
echo "RUNTIME_DIR=\"$RUNTIME_DIR\"" > /usr/local/etc/xray-reality/runtime_dir
if [[ ! -f /usr/local/etc/xray-reality/node_alias ]]; then
    cat > /usr/local/etc/xray-reality/node_alias <<'ALIASEOF'
NODE_ALIAS_V4="xray-reality-v4"
NODE_ALIAS_V6="xray-reality-v6"
ALIASEOF
fi

source "$RUNTIME_DIR/xray.env"
source "$RUNTIME_DIR/network.env" 2>/dev/null || true

# -------------------------------
# 生成 xinfo 工具
# -------------------------------
cat > /usr/local/bin/xinfo <<'XINFO_EOF'
#!/usr/bin/env bash
set -e

CFG="/usr/local/etc/xray/config.json"
BIN="/usr/local/bin/xray"

if [[ ! -f "$CFG" || ! -x "$BIN" ]]; then
    echo "错误: Xray 未安装或配置文件缺失"
    exit 1
fi

UUID=$(jq -r '.inbounds[0].settings.clients[0].id' "$CFG")
PORT=$(jq -r '.inbounds[0].port' "$CFG")
SNI=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' "$CFG")
PRIV=$(jq -r '.inbounds[0].streamSettings.realitySettings.privateKey' "$CFG")
SID=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' "$CFG")
PUB=$($BIN x25519 -i "$PRIV" 2>/dev/null | grep -oP 'Public key: \K.*')

IPV4=$(curl -s4m 2 https://api.ipify.org 2>/dev/null || echo "N/A")
IPV6=$(curl -s6m 2 https://api64.ipify.org 2>/dev/null || echo "N/A")

ALIAS_FILE="/usr/local/etc/xray-reality/node_alias"
NODE_ALIAS_V4="xray-reality-v4"
NODE_ALIAS_V6="xray-reality-v6"
[[ -f "$ALIAS_FILE" ]] && source "$ALIAS_FILE" 2>/dev/null || true

LINK_V4="vless://${UUID}@${IPV4}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PUB}&sid=${SID}&type=tcp&headerType=none#${NODE_ALIAS_V4}"
LINK_V6="vless://${UUID}@[${IPV6}]:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PUB}&sid=${SID}&type=tcp&headerType=none#${NODE_ALIAS_V6}"

clear
echo "===================================="
echo " Xray Reality 节点信息"
echo "===================================="
echo "UUID       : $UUID"
echo "端口       : $PORT"
echo "SNI        : $SNI"
echo "PublicKey  : $PUB"
echo "ShortID    : $SID"
echo "------------------------------------"
echo "IPv4 地址  : $IPV4"
echo "IPv6 地址  : $IPV6"
echo "===================================="
echo ""
echo "【IPv4 分享链接】"
echo "$LINK_V4"
echo ""
if [[ "$IPV6" != "N/A" ]]; then
    echo "【IPv6 分享链接】"
    echo "$LINK_V6"
    echo ""
fi
if command -v qrencode >/dev/null 2>&1; then
    read -n 1 -p "生成二维码? (y/n): " ans
    echo ""
    if [[ "$ans" =~ ^[yY]$ ]]; then
        echo ""; echo "【IPv4 二维码】"
        qrencode -t ANSIUTF8 "$LINK_V4"
        if [[ "$IPV6" != "N/A" ]]; then
            read -n 1 -p "生成 IPv6 二维码? (y/n): " ans2
            echo ""
            if [[ "$ans2" =~ ^[yY]$ ]]; then
                echo "【IPv6 二维码】"; qrencode -t ANSIUTF8 "$LINK_V6"
            fi
        fi
    fi
fi
XINFO_EOF

chmod +x /usr/local/bin/xinfo

# -------------------------------
# 安装子命令: net, ports, sni, f2b, bbr, swap, bt
# -------------------------------
for cmd in net ports sni f2b bbr swap bt name; do
    if [[ -f "$BASE_DIR/tools/${cmd}.sh" ]]; then
        cp "$BASE_DIR/tools/${cmd}.sh" "/usr/local/bin/$cmd"
        chmod +x "/usr/local/bin/$cmd"
        echo "[OK] 已安装: $cmd"
    fi
done

echo ""
echo "=========================================="
echo "  常用命令"
echo "=========================================="
echo "  xinfo  - 查看节点信息与分享链接"
echo "  net    - 切换网络策略 (IPv4/IPv6)"
echo "  ports  - 修改 SSH / Xray 端口"
echo "  sni    - 修改 SNI 伪装域名"
echo "  f2b    - Fail2ban 状态与配置"
echo "  bbr    - BBR 拥塞控制开关"
echo "  swap   - Swap 虚拟内存查看与创建"
echo "  bt     - BT/P2P 与私有 IP 封禁管理"
echo "  name   - 节点别名（分享链接/客户端显示名，支持中文如 香港-V4）"
echo "=========================================="
