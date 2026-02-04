#!/usr/bin/env bash
# Fail2ban 状态与配置
set -e

echo "=========================================="
echo "  Fail2ban (f2b)"
echo "=========================================="

if ! command -v fail2ban-client &>/dev/null; then
    echo "Fail2ban 未安装"
    echo "安装: apt install -y fail2ban"
    [[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
    exit 0
fi

echo "状态:"
systemctl status fail2ban --no-pager 2>/dev/null || true
echo ""
# 若因「找不到 sshd log file」失败，提示改用 systemd 后端
if ! systemctl is-active --quiet fail2ban 2>/dev/null; then
    echo "[提示] 若上方报错 Have not found any log file for sshd jail，可在 /etc/fail2ban/jail.local 的 [sshd] 下添加: backend = systemd"
    echo "        然后执行: systemctl restart fail2ban"
    echo ""
fi
echo "Jail 列表:"
fail2ban-client status 2>/dev/null || true
echo ""
echo "配置文件: /etc/fail2ban/jail.local"
echo "修改后重启: systemctl restart fail2ban"
[[ -f /usr/local/etc/xray-reality/common_commands.sh ]] && source /usr/local/etc/xray-reality/common_commands.sh && show_common_commands
