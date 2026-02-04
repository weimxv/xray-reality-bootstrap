#!/usr/bin/env bash
# Fail2ban 状态与配置路径
set -e

echo "=========================================="
echo "  Fail2ban (f2b)"
echo "=========================================="

if ! command -v fail2ban-client &>/dev/null; then
    echo "Fail2ban 未安装"
    echo "安装: apt install -y fail2ban"
    exit 0
fi

echo "状态:"
systemctl status fail2ban --no-pager 2>/dev/null || true
echo ""
echo "Jail 列表:"
fail2ban-client status 2>/dev/null || true
echo ""
echo "配置文件: /etc/fail2ban/jail.local"
echo "修改后重启: systemctl restart fail2ban"
