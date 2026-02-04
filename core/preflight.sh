#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UI_DIR="$BASE_DIR/ui"

source "$UI_DIR/color.sh"
source "$UI_DIR/prompt.sh"

LOCK_DIR="/tmp/xray-reality-bootstrap.lock"
PID_FILE="$LOCK_DIR/pid"

# -------------------------------
# 锁机制：防止重复执行
# -------------------------------
acquire_lock() {
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        echo "$$" > "$PID_FILE"
        return 0
    fi

    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null || true)
        if [[ -n "$old_pid" ]] && ! kill -0 "$old_pid" 2>/dev/null; then
            rm -rf "$LOCK_DIR"
            mkdir "$LOCK_DIR"
            echo "$$" > "$PID_FILE"
            return 0
        fi
    fi

    ui_err "检测到脚本正在运行中，请勿重复执行"
    exit 1
}

cleanup_lock() {
    rm -rf "$LOCK_DIR" 2>/dev/null || true
}

trap cleanup_lock EXIT INT TERM

# -------------------------------
# Root 校验
# -------------------------------
check_root() {
    [[ "$EUID" -eq 0 ]] || {
        ui_err "请使用 root 用户运行此脚本"
        exit 1
    }
}

# -------------------------------
# 系统校验
# -------------------------------
check_os() {
    [[ -f /etc/os-release ]] || {
        ui_err "无法识别系统类型"
        exit 1
    }

    . /etc/os-release
    case "$ID" in
        debian|ubuntu)
            ui_ok "系统检测通过: $PRETTY_NAME"
            ;;
        *)
            ui_err "仅支持 Debian / Ubuntu"
            exit 1
            ;;
    esac
}

# -------------------------------
# systemd 校验
# -------------------------------
check_systemd() {
    command -v systemctl >/dev/null 2>&1 || {
        ui_err "系统不支持 systemd"
        exit 1
    }
}

# -------------------------------
# apt 锁检测
# -------------------------------
check_apt_lock() {
    if pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; then
        ui_warn "检测到 apt / dpkg 正在运行"
        ui_confirm "是否等待并继续" 30 y
    fi
}

# -------------------------------
# 网络检测
# -------------------------------
check_network() {
    if curl -s --connect-timeout 3 https://1.1.1.1 >/dev/null 2>&1; then
        ui_ok "网络连通性检测通过 (IPv4)"
        return
    fi

    if curl -s --connect-timeout 3 -6 https://2606:4700:4700::1111 >/dev/null 2>&1; then
        ui_ok "网络连通性检测通过 (IPv6)"
        return
    fi

    ui_err "无法访问互联网"
    exit 1
}

# -------------------------------
# 执行入口
# -------------------------------
preflight_run() {
    acquire_lock
    check_root
    check_os
    check_systemd
    check_apt_lock
    check_network
}
