#!/usr/bin/env bash
# SNI 伪装域名修改
set -e

CFG="/usr/local/etc/xray/config.json"

[[ -f "$CFG" ]] || { echo "错误: 未找到 Xray 配置"; exit 1; }

SNI=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' "$CFG")
DEST=$(jq -r '.inbounds[0].streamSettings.realitySettings.dest' "$CFG")

echo "=========================================="
echo "  SNI 域名 (sni)"
echo "=========================================="
echo "当前 SNI: $SNI"
echo "当前 dest: $DEST"
echo ""
read -p "请输入新 SNI 域名 (直接回车保持不变): " new_sni
new_sni=${new_sni:-$SNI}

if [[ -z "$new_sni" ]]; then
    [[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
    echo "未修改"; exit 0
fi

# dest 格式为 sni:443
new_dest="${new_sni}:443"
jq --arg s "$new_sni" --arg d "$new_dest" \
   '.inbounds[0].streamSettings.realitySettings.serverNames[0] = $s | .inbounds[0].streamSettings.realitySettings.dest = $d' \
   "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"

systemctl restart xray
echo "[OK] SNI 已改为: $new_sni，Xray 已重启"
[[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
