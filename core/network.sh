#!/usr/bin/env bash

set -e

# 如果变量未定义，则计算（兼容独立运行）
if [[ -z "$BASE_DIR" ]]; then
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    UI_DIR="$BASE_DIR/ui"
    RUNTIME_DIR="$BASE_DIR/runtime"
fi

mkdir -p "$RUNTIME_DIR"

source "$UI_DIR/color.sh"
source "$UI_DIR/prompt.sh"
source "$UI_DIR/spinner.sh"

RUNTIME_FILE="$RUNTIME_DIR/network.env"

# -------------------------------
# 探测 IPv4
# -------------------------------
check_ipv4() {
    curl -4 -s --connect-timeout 3 https://1.1.1.1 >/dev/null 2>&1
}

# -------------------------------
# 探测 IPv6
# -------------------------------
check_ipv6() {
    curl -6 -s --connect-timeout 3 https://2606:4700:4700::1111 >/dev/null 2>&1
}

# -------------------------------
# 网络检测主逻辑
# -------------------------------
detect_network() {
    HAS_IPV4=false
    HAS_IPV6=false

    # 使用允许失败的 spinner，网络检测失败不应该退出
    spinner_run_allow_fail "检测 IPv4 连通性" check_ipv4 && HAS_IPV4=true || true
    spinner_run_allow_fail "检测 IPv6 连通性" check_ipv6 && HAS_IPV6=true || true

    if $HAS_IPV4 && $HAS_IPV6; then
        NET_TYPE="dual_stack"
    elif $HAS_IPV4; then
        NET_TYPE="ipv4_only"
    elif $HAS_IPV6; then
        NET_TYPE="ipv6_only"
    else
        ui_err "IPv4 / IPv6 均不可用，无法继续部署"
        exit 1
    fi

    ui_ok "网络类型识别完成: $NET_TYPE"
}

# -------------------------------
# 推荐策略
# -------------------------------
recommend_strategy() {
    case "$NET_TYPE" in
        dual_stack)
            RECOMMEND="dual_stack"
            DESC="IPv4 + IPv6 双栈（默认推荐，最稳妥）"
            ;;
        ipv4_only)
            RECOMMEND="ipv4_only"
            DESC="仅 IPv4（兼容性最好）"
            ;;
        ipv6_only)
            RECOMMEND="ipv6_only"
            DESC="仅 IPv6（需客户端支持）"
            ;;
    esac
}

# -------------------------------
# 用户确认
# -------------------------------
confirm_strategy() {
    ui_info "推荐网络策略: $DESC"
    ui_info "说明：此策略不会立即修改系统，仅作为后续模块依据"

    # 默认接受推荐策略（y）
    if ui_confirm "是否接受该策略" 30 y; then
        NET_STRATEGY="$RECOMMEND"
    else
        ui_warn "请选择网络策略："
        echo "  1) dual_stack  - 双栈"
        echo "  2) ipv4_only   - 仅 IPv4"
        echo "  3) ipv6_only   - 仅 IPv6"
        echo

        # 循环直到输入有效
        while true; do
            read -t 30 -p "请输入选项 [1-3]: " choice </dev/tty || choice=""
            case "$choice" in
                1) NET_STRATEGY="dual_stack"; break ;;
                2) NET_STRATEGY="ipv4_only"; break ;;
                3) NET_STRATEGY="ipv6_only"; break ;;
                "") 
                    ui_warn "输入超时，使用推荐策略"
                    NET_STRATEGY="$RECOMMEND"
                    break
                    ;;
                *) 
                    ui_err "无效输入 [$choice]，请输入 1-3 之间的数字"
                    ;;
            esac
        done
    fi

    ui_ok "已确认网络策略: $NET_STRATEGY"
}

# -------------------------------
# 写入 runtime 文件
# -------------------------------
persist_result() {
    # 强制使用绝对路径，避免 source 环境下路径不一致
    local abs_runtime_dir abs_runtime_file
    abs_runtime_dir="$(cd "$RUNTIME_DIR" && pwd)"
    abs_runtime_file="$abs_runtime_dir/network.env"

    mkdir -p "$abs_runtime_dir"

    cat > "$abs_runtime_file" <<EOF
# 自动生成，请勿手动修改
NET_TYPE=$NET_TYPE
NET_STRATEGY=$NET_STRATEGY
HAS_IPV4=$HAS_IPV4
HAS_IPV6=$HAS_IPV6
EOF

    # 同步落盘并验证
    sync
    if [[ -f "$abs_runtime_file" ]] && [[ -s "$abs_runtime_file" ]]; then
        RUNTIME_FILE="$abs_runtime_file"
        ui_ok "网络信息已写入: $RUNTIME_FILE"
    else
        ui_err "写入失败: $abs_runtime_file"
        exit 1
    fi
}

# -------------------------------
# 执行入口
# -------------------------------
network_run() {
    detect_network
    recommend_strategy
    confirm_strategy
    persist_result
}
