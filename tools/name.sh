#!/usr/bin/env bash
# 节点别名设置（分享链接中 # 后的名称，支持中文如 香港-V4）
set -e

ALIAS_FILE="/usr/local/etc/xray-reality/node_alias"

mkdir -p /usr/local/etc/xray-reality
[[ -f "$ALIAS_FILE" ]] && source "$ALIAS_FILE"
NODE_ALIAS_V4="${NODE_ALIAS_V4:-xray-reality-v4}"
NODE_ALIAS_V6="${NODE_ALIAS_V6:-xray-reality-v6}"

echo "=========================================="
echo "  节点别名 (name)"
echo "=========================================="
echo "当前别名将显示在分享链接末尾，导入客户端后作为节点名称。"
echo ""
echo "当前 IPv4 节点别名: $NODE_ALIAS_V4"
echo "当前 IPv6 节点别名: $NODE_ALIAS_V6"
echo "------------------------------------------"
read -p "请输入 IPv4 节点别名 (直接回车保持不变): " input_v4
read -p "请输入 IPv6 节点别名 (直接回车保持不变): " input_v6

[[ -n "$input_v4" ]] && NODE_ALIAS_V4="$input_v4"
[[ -n "$input_v6" ]] && NODE_ALIAS_V6="$input_v6"

cat > "$ALIAS_FILE" <<EOF
# 节点别名，用于 xinfo 分享链接中的 # 后名称
NODE_ALIAS_V4="$NODE_ALIAS_V4"
NODE_ALIAS_V6="$NODE_ALIAS_V6"
EOF

echo ""
echo "[OK] 已保存。运行 xinfo 可查看带新别名的分享链接。"
