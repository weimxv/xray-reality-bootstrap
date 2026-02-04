#!/usr/bin/env bash
# 实时查看 Xray 连接日志（Ctrl+C 退出）
set -e

if ! command -v journalctl &>/dev/null; then
    echo "错误: 未找到 journalctl"
    exit 1
fi

if ! systemctl is-active --quiet xray 2>/dev/null; then
    echo "提示: Xray 服务未运行，将只显示历史日志"
fi

echo "=========================================="
echo "  Xray 实时日志 (log)"
echo "=========================================="
echo "按 Ctrl+C 退出"
echo "------------------------------------------"
journalctl -u xray -f --no-pager
