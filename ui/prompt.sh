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

    local input=""
    
    # 显示提示并等待输入（支持回车确认）
    # 直接输出到 stderr 以避免被捕获
    >&2 echo -e "${YELLOW}${prompt} [默认: ${default}] [ ${RED}${timeout}s${YELLOW} ] : ${PLAIN}"
    
    # 使用 read -t 等待整行输入
    if read -t "$timeout" input </dev/tty; then
        # 用户输入了内容（可能是 y/n 或直接回车）
        input="${input:-$default}"
    else
        # 超时，使用默认值
        input="$default"
    fi
    
    # 返回结果到 stdout
    echo "$input"
}

# --- 确认（返回值优化）---
ui_confirm() {
    local msg="$1"
    local timeout="${2:-30}"  # 默认 30 秒超时
    local default="${3:-n}"   # 第三个参数可指定默认值，默认 n
    local ans
    ans=$(ui_read_timeout "$msg (y/n)" "$default" "$timeout")
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
