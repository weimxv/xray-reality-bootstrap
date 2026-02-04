#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/color.sh"

# --- 清理输入缓冲 ---
_flush_stdin() {
    while read -r -t 0; do read -r -n 1; done
}

# --- 倒计时输入（支持动态读秒 + 单键确认无需回车）---
ui_read_timeout() {
    local prompt="$1"
    local default="$2"
    local timeout="$3"

    local input=""
    local remain="$timeout"

    while [[ $remain -gt 0 ]]; do
        # 提示输出到 stderr，\r 覆盖同一行实现动态读秒
        >&2 echo -ne "\r${YELLOW}${prompt} [默认: ${default}] [ ${RED}${remain}s${YELLOW} ] : ${PLAIN}"
        # 单键读取，无需回车；1 秒超时以便更新倒计时
        if read -t 1 -n 1 input </dev/tty 2>/dev/null; then
            break
        fi
        remain=$((remain - 1))
    done

    >&2 echo ""
    # 若未输入或输入非 y/n，用默认值
    if [[ "$input" =~ ^[yYnN]$ ]]; then
        [[ "$input" =~ ^[yY]$ ]] && input="y" || input="n"
    else
        input="$default"
    fi
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
