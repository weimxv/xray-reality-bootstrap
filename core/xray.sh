#!/usr/bin/env bash

set -e

# 如果变量未定义，则计算（兼容独立运行）
if [[ -z "$BASE_DIR" ]]; then
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    UI_DIR="$BASE_DIR/ui"
fi

source "$UI_DIR/color.sh"
source "$UI_DIR/spinner.sh"

XRAY_BIN="/usr/local/bin/xray"

# -------------------------------
# 安装 Xray Core
# -------------------------------
install_xray() {
    if [[ -x "$XRAY_BIN" ]]; then
        local version
        version=$("$XRAY_BIN" version 2>/dev/null | head -n1 | awk '{print $2}')
        ui_ok "Xray 已安装 ($version)"
        return
    fi

    spinner_run "下载并安装 Xray Core" bash -c '
        curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh \
        | bash -s install --without-geodata
    '

    if [[ ! -x "$XRAY_BIN" ]]; then
        ui_err "Xray 安装失败"
        exit 1
    fi

    local version
    version=$("$XRAY_BIN" version 2>/dev/null | head -n1 | awk '{print $2}')
    ui_ok "Xray 安装成功 ($version)"
}

# -------------------------------
# 主流程
# -------------------------------
xray_run() {
    ui_info "安装 Xray Core（不含配置）"
    install_xray
}
