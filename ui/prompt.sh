#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/color.sh"

# --- 清理输入缓冲 ---
_flush_stdin() {
    while read -r -t 0; do read -r -n 1; done
}

# --- 倒计时输入 ---
ui_read_timeout() {
    local prompt="$1"
    local default="$2"
    local timeout="$3"

    _flush_stdin
    local start=$(date +%s)
    local end=$((start + timeout))
    local input=""

    while true; do
        local now=$(date +%s)
        local remain=$((end - now))
        [[ $remain -le 0 ]] && break

        echo -ne "\r${YELLOW}${prompt} [默认: ${default}] [ ${RED}${remain}s${YELLOW} ] : ${PLAIN}"
        read -t 1 -n 1 input && break
    done

    echo ""
    echo "${input:-$default}"
}

# --- 确认（返回值优化）---
ui_confirm() {
    local msg="$1"
    local timeout="${2:-10}"
    local ans
    ans=$(ui_read_timeout "$msg (y/n)" "n" "$timeout")
    [[ "$ans" =~ ^[yY]$ ]]
}

# --- 读取输入 ---
ui_read() {
    local prompt="$1"
    local default="$2"
    local input
    read -p "$(echo -e "${YELLOW}${prompt} [${default}]: ${PLAIN}")" input
    echo "${input:-$default}"
}
