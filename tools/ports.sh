#!/usr/bin/env bash
# 端口管理：查看/修改 SSH、Xray 端口
set -e

XRAY_ETC="/usr/local/etc/xray-reality"
CFG="/usr/local/etc/xray/config.json"

get_runtime_dir() {
    if [[ -f "$XRAY_ETC/runtime_dir" ]]; then source "$XRAY_ETC/runtime_dir"; else RUNTIME_DIR="/opt/xray-reality-bootstrap/runtime"; fi
}
get_runtime_dir

[[ -f "$CFG" ]] || { echo "错误: 未找到 Xray 配置"; exit 1; }

SSH_PORT=$(ss -lntp 2>/dev/null | awk '/sshd/ && /LISTEN/ {print $4}' | head -1 | awk -F: '{print $NF}')
[[ -z "$SSH_PORT" ]] && SSH_PORT=22
XRAY_PORT=$(jq -r '.inbounds[0].port' "$CFG")

echo "=========================================="
echo "  端口管理 (ports)"
echo "=========================================="
echo "当前端口:"
echo "  SSH  : $SSH_PORT"
echo "  Xray : $XRAY_PORT"
echo ""
echo "请选择操作:"
echo "  1) 修改 Xray 端口"
echo "  2) 修改 SSH 端口（需自行编辑 /etc/ssh/sshd_config 并重启 sshd）"
echo "  0) 退出"
echo ""
read -p "请输入 [0-2]: " choice

case "$choice" in
    1)
        read -p "请输入新 Xray 端口 [1-65535] (当前 $XRAY_PORT): " new_port
        new_port=${new_port:-$XRAY_PORT}
        if [[ ! "$new_port" =~ ^[0-9]+$ ]] || [[ "$new_port" -lt 1 ]] || [[ "$new_port" -gt 65535 ]]; then
            echo "错误: 端口无效"; exit 1
        fi
        jq --argjson p "$new_port" '.inbounds[0].port = $p' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
        [[ -f "$RUNTIME_DIR/xray.env" ]] && sed -i "s/^XRAY_PORT=.*/XRAY_PORT=$new_port/" "$RUNTIME_DIR/xray.env"
        systemctl restart xray
        echo "[OK] Xray 端口已改为 $new_port，请更新防火墙放行该端口"
        echo "     若使用 iptables: iptables -A INPUT -p tcp --dport $new_port -j ACCEPT"
        ;;
    2)
        echo "请手动执行:"
        echo "  nano /etc/ssh/sshd_config   # 修改 Port"
        echo "  systemctl restart sshd"
        echo "  # 并确保防火墙已放行新 SSH 端口后再断开当前连接"
        ;;
    0)
        [[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
        exit 0
        ;;
    *) echo "无效输入"; exit 1 ;;
esac
[[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
