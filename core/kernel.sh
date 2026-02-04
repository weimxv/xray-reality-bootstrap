#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UI_DIR="$BASE_DIR/ui"
RUNTIME_DIR="$BASE_DIR/runtime"

source "$UI_DIR/color.sh"
source "$UI_DIR/prompt.sh"
source "$UI_DIR/spinner.sh"

RUNTIME_FILE="$RUNTIME_DIR/kernel.env"
NETWORK_ENV="$RUNTIME_DIR/network.env"

# -------------------------------
# BBR 检测
# -------------------------------
kernel_supports_bbr() {
    sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null \
        | grep -q bbr
}

current_cc() {
    sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown"
}

enable_bbr() {
    cat >/etc/sysctl.d/99-xray-reality-bbr.conf <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sysctl --system >/dev/null
}

# -------------------------------
# Swap 逻辑
# -------------------------------
memory_mb() {
    free -m | awk '/Mem:/ {print $2}'
}

swap_enabled() {
    swapon --show | grep -q '^/'
}

create_swap() {
    local size_mb="$1"

    ui_warn "正在创建 ${size_mb}MB Swap（仅用于缓冲，非性能优化）"

    swapoff /swapfile 2>/dev/null || true
    rm -f /swapfile

    if fallocate -l "${size_mb}M" /swapfile 2>/dev/null; then
        :
    else
        dd if=/dev/zero of=/swapfile bs=1M count="$size_mb"
    fi

    chmod 600 /swapfile
    mkswap /swapfile >/dev/null
    swapon /swapfile

    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
}

# -------------------------------
# 主流程
# -------------------------------
kernel_run() {

    # 读取网络信息（仅用于展示）
    if [[ -f "$NETWORK_ENV" ]]; then
        source "$NETWORK_ENV"
    else
        ui_err "未检测到 network.env，请先运行 network.sh"
        exit 1
    fi

    ui_info "当前网络策略: $NET_STRATEGY"
    ui_info "开始内核优化检查（安全模式）"

    # -------- BBR --------
    if kernel_supports_bbr; then
        CURRENT_CC="$(current_cc)"
        ui_info "当前拥塞控制算法: $CURRENT_CC"

        if [[ "$CURRENT_CC" != "bbr" ]]; then
            if ui_confirm "是否启用 BBR 拥塞控制？" 10; then
                spinner_run "启用 BBR" enable_bbr
                BBR_ENABLED=true
            else
                BBR_ENABLED=false
            fi
        else
            ui_ok "BBR 已启用"
            BBR_ENABLED=true
        fi
    else
        ui_warn "内核不支持 BBR，已跳过"
        BBR_ENABLED=false
    fi

    # -------- Swap --------
    RAM_MB="$(memory_mb)"
    ui_info "物理内存: ${RAM_MB}MB"

    if [[ "$RAM_MB" -lt 2048 ]]; then
        if swap_enabled; then
            ui_ok "检测到 Swap 已存在"
            SWAP_ENABLED=true
        else
            if ui_confirm "内存 < 2GB，是否创建 1GB Swap？" 12; then
                spinner_run "创建 Swap" create_swap 1024
                SWAP_ENABLED=true
            else
                SWAP_ENABLED=false
            fi
        fi
    else
        ui_ok "内存充足，跳过 Swap"
        SWAP_ENABLED=false
    fi

    # -------- 记录运行态 --------
    cat > "$RUNTIME_FILE" <<EOF
# 自动生成，请勿手动修改
BBR_ENABLED=$BBR_ENABLED
SWAP_ENABLED=$SWAP_ENABLED
RAM_MB=$RAM_MB
EOF

    ui_ok "内核优化完成（结果已写入 runtime/kernel.env）"
}
