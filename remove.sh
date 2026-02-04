#!/usr/bin/env bash

set -e

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

echo -e "${YELLOW}"
echo "===================================="
echo " Xray Reality 卸载工具"
echo "===================================="
echo -e "${PLAIN}"
echo ""
echo -e "${RED}警告: 此操作将：${PLAIN}"
echo "  • 停止并删除 Xray 服务"
echo "  • 删除 Xray 配置文件"
echo "  • 删除管理工具 (xinfo)"
echo "  • 删除运行时数据"
echo ""
echo -e "${YELLOW}不会删除：${PLAIN}"
echo "  • 系统依赖包"
echo "  • 防火墙规则"
echo "  • 内核优化配置"
echo ""

read -rp "确认卸载？(yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "取消卸载"
    exit 0
fi

echo ""
echo "正在卸载..."

# 停止服务
systemctl stop xray 2>/dev/null || true
systemctl disable xray 2>/dev/null || true

# 删除文件
rm -f /etc/systemd/system/xray.service
rm -rf /usr/local/etc/xray
rm -f /usr/local/bin/xray
rm -f /usr/local/bin/xinfo

# 清理运行时
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
rm -rf "$BASE_DIR/runtime"

systemctl daemon-reload

echo ""
echo -e "${GREEN}卸载完成！${PLAIN}"
echo ""
echo "提示: 如需重新部署，请运行:"
echo "  bash install.sh"
