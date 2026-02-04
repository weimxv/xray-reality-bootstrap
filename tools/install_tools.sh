#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$BASE_DIR/runtime"

# 检查是否已部署
if [[ ! -f "$RUNTIME_DIR/xray.env" ]]; then
    echo "错误: 未检测到 Xray 部署信息，请先运行 install.sh"
    exit 1
fi

source "$RUNTIME_DIR/xray.env"
source "$RUNTIME_DIR/network.env" 2>/dev/null || true

# -------------------------------
# 生成 info 工具
# -------------------------------
cat > /usr/local/bin/xinfo <<'EOF'
#!/usr/bin/env bash
set -e

CFG="/usr/local/etc/xray/config.json"
BIN="/usr/local/bin/xray"

if [[ ! -f "$CFG" || ! -x "$BIN" ]]; then
    echo "错误: Xray 未安装或配置文件缺失"
    exit 1
fi

# 提取参数
UUID=$(jq -r '.inbounds[0].settings.clients[0].id' "$CFG")
PORT=$(jq -r '.inbounds[0].port' "$CFG")
SNI=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' "$CFG")
PRIV=$(jq -r '.inbounds[0].streamSettings.realitySettings.privateKey' "$CFG")
SID=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' "$CFG")

# 计算公钥
PUB=$($BIN x25519 -i "$PRIV" 2>/dev/null | grep -oP 'Public key: \K.*')

# 获取 IP
IPV4=$(curl -s4m 2 https://api.ipify.org 2>/dev/null || echo "N/A")
IPV6=$(curl -s6m 2 https://api64.ipify.org 2>/dev/null || echo "N/A")

# 生成链接
LINK_V4="vless://${UUID}@${IPV4}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PUB}&sid=${SID}&type=tcp&headerType=none#xray-reality-v4"
LINK_V6="vless://${UUID}@[${IPV6}]:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PUB}&sid=${SID}&type=tcp&headerType=none#xray-reality-v6"

# 输出
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

# 二维码
if command -v qrencode >/dev/null 2>&1; then
    read -n 1 -p "生成二维码? (y/n): " ans
    echo ""
    if [[ "$ans" =~ ^[yY]$ ]]; then
        echo ""
        echo "【IPv4 二维码】"
        qrencode -t ANSIUTF8 "$LINK_V4"
        
        if [[ "$IPV6" != "N/A" ]]; then
            read -n 1 -p "生成 IPv6 二维码? (y/n): " ans2
            echo ""
            if [[ "$ans2" =~ ^[yY]$ ]]; then
                echo "【IPv6 二维码】"
                qrencode -t ANSIUTF8 "$LINK_V6"
            fi
        fi
    fi
fi
EOF

chmod +x /usr/local/bin/xinfo

echo "[OK] 已安装工具: xinfo"
echo "运行 'xinfo' 查看节点信息"
