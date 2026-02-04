#!/usr/bin/env bash

set -e

# 如果变量未定义，则计算（兼容独立运行）
if [[ -z "$BASE_DIR" ]]; then
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    UI_DIR="$BASE_DIR/ui"
fi

source "$UI_DIR/color.sh"
source "$UI_DIR/spinner.sh"
source "$UI_DIR/prompt.sh"

# -------------------------------
# APT 初始化
# -------------------------------
apt_prepare() {
    export DEBIAN_FRONTEND=noninteractive

    mkdir -p /etc/needrestart/conf.d
    echo "\$nrconf{restart} = 'a';" > /etc/needrestart/conf.d/99-xray-bootstrap.conf

    rm -f /var/lib/apt/lists/lock \
          /var/cache/apt/archives/lock \
          /var/lib/dpkg/lock*
}

# -------------------------------
# 系统更新
# -------------------------------
system_update() {
    spinner_run "刷新软件源" apt-get update -qq
    spinner_run "系统升级" apt-get -y -o Dpkg::Options::="--force-confold" upgrade
}

# -------------------------------
# 依赖安装（合并安装提升速度）
# -------------------------------
install_deps() {
    local deps=(
        curl
        wget
        jq
        unzip
        tar
        cron
        ca-certificates
        iptables
        iptables-persistent
        chrony
        qrencode
    )

    local to_install=()
    for pkg in "${deps[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        ui_info "需安装 ${#to_install[@]} 个依赖包"
        spinner_run "批量安装依赖" apt-get install -y "${to_install[@]}"
    else
        ui_ok "所有依赖已就绪"
    fi
}

# -------------------------------
# 时区 & 时间同步
# -------------------------------
setup_time() {
    local tz
    tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "Unknown")

    ui_info "当前时区: $tz"
    if ui_confirm "是否设置为上海 (Asia/Shanghai)" 30 y; then
        spinner_run "设置时区" timedatectl set-timezone Asia/Shanghai
    fi

    spinner_run "启用时间同步" timedatectl set-ntp true
}

# -------------------------------
# 执行入口
# -------------------------------
system_run() {
    apt_prepare
    system_update
    install_deps
    setup_time
}
