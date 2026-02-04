#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/color.sh"

SPINNER_FRAMES=( "|" "/" "-" "\\" )

# 普通 spinner，失败会退出
spinner_run() {
    local title="$1"
    shift
    _spinner_internal "$title" "false" "$@"
}

# 允许失败的 spinner，失败不退出
spinner_run_allow_fail() {
    local title="$1"
    shift
    _spinner_internal "$title" "true" "$@"
}

# 内部实现
_spinner_internal() {
    local title="$1"
    local allow_fail="$2"
    shift 2
    local cmd=("$@")
    local max_retries=3
    local attempt=1

    while [[ $attempt -le $max_retries ]]; do
        local log="/tmp/xray-bootstrap-${attempt}.log"
        : > "$log"

        "${cmd[@]}" >"$log" 2>&1 &
        local pid=$!

        tput civis
        local i=0
        while kill -0 "$pid" 2>/dev/null; do
            printf "\r ${BLUE}[ %s ]${PLAIN} %s" "${SPINNER_FRAMES[i]}" "$title"
            i=$(( (i+1) % 4 ))
            sleep 0.1
        done
        tput cnorm
        wait "$pid"
        local rc=$?

        echo -ne "\r\033[K"
        if [[ $rc -eq 0 ]]; then
            ui_ok "$title"
            return 0
        else
            if [[ $attempt -ge $max_retries ]]; then
                if [[ "$allow_fail" == "true" ]]; then
                    ui_warn "$title (失败)"
                    return 1
                else
                    ui_err "$title (失败)"
                    tail -n 10 "$log" | sed 's/^/  /'
                    exit 1
                fi
            else
                ui_warn "$title (重试 $attempt/$max_retries)"
                ((attempt++))
                sleep 2
            fi
        fi
    done
}
