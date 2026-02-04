#!/usr/bin/env bash

set -e

# 如果变量未定义，则计算（兼容独立运行）
if [[ -z "$BASE_DIR" ]]; then
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    UI_DIR="$BASE_DIR/ui"
    RUNTIME_DIR="$BASE_DIR/runtime"
fi

source "$UI_DIR/color.sh"
source "$UI_DIR/prompt.sh"
source "$UI_DIR/spinner.sh"

NETWORK_ENV="$RUNTIME_DIR/network.env"
FIREWALL_ENV="$RUNTIME_DIR/firewall.env"

# -------------------------------
# SSH 端口检测
# -------------------------------
detect_ssh_port() {
    local port
    port=$(ss -lntp | awk '/sshd/ && /LISTEN/ {print $4}' | head -n1 | awk -F: '{print $NF}')
    [[ -z "$port" ]] && port=22
    echo "$port"
}

SSH_PORT="$(detect_ssh_port)"

# -------------------------------
# 放行端口函数
# -------------------------------
allow_port() {
    local port="$1"
    local proto="$2"

    iptables -C INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null \
        || iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT

    if [[ "$HAS_IPV6" == "true" && -f /proc/net/if_inet6 ]]; then
        ip6tables -C INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null \
            || ip6tables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
    fi
}

# -------------------------------
# 主流程
# -------------------------------
firewall_run() {

    # 基础依赖检测（在运行时而不是加载时）
    require_cmd() {
        command -v "$1" >/dev/null 2>&1 || {
            ui_err "缺少依赖命令: $1"
            exit 1
        }
    }

    require_cmd iptables
    require_cmd systemctl

    if [[ ! -f "$NETWORK_ENV" ]]; then
        ui_err "未检测到 network.env，请先运行 network.sh"
        exit 1
    fi
    source "$NETWORK_ENV"

    ui_info "配置基础防火墙规则（安全模式）"
    ui_info "当前 SSH 端口: $SSH_PORT"

    # 1. 允许已建立连接
    iptables -C INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
        || iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # 2. 放行 SSH
    allow_port "$SSH_PORT" tcp

    # 3. 放行 Xray 端口（如果已存在）
    XRAY_ENV="$RUNTIME_DIR/xray.env"
    XRAY_PORTS=()

    if [[ -f "$XRAY_ENV" ]]; then
        source "$XRAY_ENV"
        [[ -n "$XRAY_PORT_VISION" ]] && XRAY_PORTS+=("$XRAY_PORT_VISION")
        [[ -n "$XRAY_PORT_XHTTP" ]] && XRAY_PORTS+=("$XRAY_PORT_XHTTP")
    fi

    if [[ "${#XRAY_PORTS[@]}" -gt 0 ]]; then
        ui_info "检测到 Xray 端口: ${XRAY_PORTS[*]}"
        for p in "${XRAY_PORTS[@]}"; do
            allow_port "$p" tcp
            allow_port "$p" udp
        done
    else
        ui_warn "尚未检测到 Xray 端口，后续模块可再次执行 firewall.sh"
    fi

    # 4. 默认策略（仅 INPUT）
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    if [[ "$HAS_IPV6" == "true" && -f /proc/net/if_inet6 ]]; then
        ip6tables -P INPUT DROP
        ip6tables -P FORWARD DROP
        ip6tables -P OUTPUT ACCEPT
    fi

    # 5. 持久化
    spinner_run "保存防火墙规则" bash -c "
        if command -v netfilter-persistent >/dev/null 2>&1; then
            netfilter-persistent save
        elif command -v iptables-save >/dev/null 2>&1; then
            iptables-save > /etc/iptables.rules
        fi
    "

    # 6. Fail2ban（增强版）
    if ui_confirm "是否启用 Fail2ban (SSH 防暴力破解)" 30 y; then
        spinner_run "配置 Fail2ban" bash -c "
            apt-get -y install fail2ban >/dev/null 2>&1 || true
            cat >/etc/fail2ban/jail.local <<'EOFAIL'
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime = 1d
bantime.increment = true
bantime.factor = 1
bantime.maxtime = 30d
findtime = 7d
maxretry = 3
backend = auto

[sshd]
enabled = true
port = $SSH_PORT
mode = aggressive
EOFAIL
            systemctl enable --now fail2ban
        "
        F2B_ENABLED=true
    else
        F2B_ENABLED=false
    fi

    # 7. 记录运行态
    cat > "$FIREWALL_ENV" <<EOF
# 自动生成，请勿手动修改
SSH_PORT=$SSH_PORT
XRAY_PORTS="${XRAY_PORTS[*]}"
FAIL2BAN_ENABLED=$F2B_ENABLED
EOF

    ui_ok "防火墙配置完成（firewall.env 已生成）"
}
