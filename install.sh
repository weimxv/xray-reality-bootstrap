#!/usr/bin/env bash
set -e

# 导出全局路径变量，供所有模块使用
export BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
export CORE_DIR="$BASE_DIR/core"
export TOOLS_DIR="$BASE_DIR/tools"
export RUNTIME_DIR="$BASE_DIR/runtime"
export UI_DIR="$BASE_DIR/ui"

mkdir -p "$RUNTIME_DIR"

# ---------------- UI ----------------
source "$BASE_DIR/ui/color.sh"
source "$BASE_DIR/ui/banner.sh"

# ---------------- Preflight ----------------
source "$CORE_DIR/preflight.sh"

# ---------------- Load Modules ----------------
source "$CORE_DIR/system.sh"
source "$CORE_DIR/network.sh"
source "$CORE_DIR/kernel.sh"
source "$CORE_DIR/firewall.sh"
source "$CORE_DIR/xray.sh"
source "$CORE_DIR/reality.sh"

# ---------------- Commands ----------------
cmd_install() {
    print_banner
    ui_warning

    echo ""
    # 默认 y：直接回车或超时都会继续，输入 n 才取消
    if ! ui_confirm "是否继续部署" 30 y; then
        ui_warn "用户取消部署"
        exit 0
    fi
    echo ""

    ui_phase 1 7 "环境检查"
    preflight_run

    ui_phase 2 7 "系统初始化"
    system_run

    ui_phase 3 7 "网络检测"
    network_run

    ui_phase 4 7 "内核优化"
    kernel_run

    ui_phase 5 7 "安装 Xray Core"
    xray_run

    ui_phase 6 7 "Reality 配置"
    reality_run

    ui_phase 7 7 "防火墙配置与工具安装"
    firewall_run
    bash "$TOOLS_DIR/install_tools.sh"

    echo ""
    ui_ok "=================================="
    ui_ok " 部署完成！"
    ui_ok "=================================="
    ui_info "运行 'xinfo' 查看节点信息"
    echo ""
}

cmd_info() {
    if [[ -x /usr/local/bin/xinfo ]]; then
        /usr/local/bin/xinfo
    else
        ui_err "工具未安装，请先运行: bash install.sh"
        exit 1
    fi
}

cmd_uninstall() {
    ui_warn "即将卸载 Xray Reality（不会回滚系统配置）"
    read -rp "确认继续？(y/n): " c
    [[ "$c" =~ ^[yY]$ ]] || exit 0

    systemctl stop xray 2>/dev/null || true
    systemctl disable xray 2>/dev/null || true
    rm -f /etc/systemd/system/xray.service
    rm -rf /usr/local/etc/xray
    rm -f /usr/local/bin/xray
    rm -f /usr/local/bin/xinfo
    rm -rf "$RUNTIME_DIR"

    systemctl daemon-reload
    ui_ok "Xray Reality 已卸载"
}

usage() {
    cat <<EOF
用法:
  bash install.sh          - 全自动部署
  bash install.sh info     - 查看节点信息
  bash install.sh remove   - 卸载 Xray

EOF
    exit 1
}

# ---------------- Main ----------------
case "${1:-install}" in
    install)   cmd_install ;;
    info)      cmd_info ;;
    remove|uninstall) cmd_uninstall ;;
    *)         usage ;;
esac
