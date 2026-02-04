#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UI_DIR="$BASE_DIR/ui"
RUNTIME_DIR="$BASE_DIR/runtime"

source "$UI_DIR/color.sh"
source "$UI_DIR/prompt.sh"
source "$UI_DIR/spinner.sh"
source "$BASE_DIR/lib/validator.sh"

XRAY_BIN="/usr/local/bin/xray"
XRAY_CONF_DIR="/usr/local/etc/xray"
XRAY_CONF_FILE="$XRAY_CONF_DIR/config.json"
XRAY_ENV="$RUNTIME_DIR/xray.env"
NETWORK_ENV="$RUNTIME_DIR/network.env"

# 加载网络信息
[[ -f "$NETWORK_ENV" ]] && source "$NETWORK_ENV"

# -------------------------------
# 生成参数
# -------------------------------
gen_uuid() {
    "$XRAY_BIN" uuid
}

gen_keypair() {
    "$XRAY_BIN" x25519
}

gen_short_id() {
    openssl rand -hex 8
}

# -------------------------------
# SNI 优选（精简版）
# -------------------------------
select_sni() {
    local domains=(
        "www.microsoft.com"
        "www.apple.com"
        "www.cloudflare.com"
    )

    ui_info "正在测速 SNI 域名..."
    local best_domain=""
    local best_time=9999

    for domain in "${domains[@]}"; do
        local time_ms
        time_ms=$(curl -o /dev/null -s -w '%{time_connect}' --connect-timeout 2 "https://${domain}" 2>/dev/null | awk '{printf "%.0f", $1*1000}')
        
        if [[ -n "$time_ms" && "$time_ms" -lt "$best_time" ]]; then
            best_time="$time_ms"
            best_domain="$domain"
        fi
    done

    if [[ -z "$best_domain" ]]; then
        best_domain="www.microsoft.com"
    fi

    ui_ok "推荐 SNI: $best_domain (${best_time}ms)"
    echo "$best_domain"
}

# -------------------------------
# 下载 GeoData
# -------------------------------
install_geodata() {
    local share_dir="/usr/local/share/xray"
    mkdir -p "$share_dir"

    local files=(
        "geoip.dat|https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
        "geosite.dat|https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
    )

    for entry in "${files[@]}"; do
        local name="${entry%%|*}"
        local url="${entry#*|}"
        local target="$share_dir/$name"

        if [[ -f "$target" ]]; then
            local size
            size=$(stat -c%s "$target" 2>/dev/null || echo 0)
            if [[ "$size" -gt 500000 ]]; then
                ui_ok "$name 已存在且有效"
                continue
            fi
        fi

        spinner_run "下载 $name" curl -fsSL -o "$target" "$url"
    done
}

# -------------------------------
# 生成配置
# -------------------------------
generate_config() {
    local port="$1"
    local sni="$2"
    local uuid="$3"
    local private_key="$4"
    local short_id="$5"
    local strategy="${NET_STRATEGY:-dual_stack}"

    # 策略映射
    local domain_strategy="AsIs"
    case "$strategy" in
        ipv4_only) domain_strategy="UseIPv4" ;;
        ipv6_only) domain_strategy="UseIPv6" ;;
        dual_stack) domain_strategy="IPIfNonMatch" ;;
    esac

    cat > "$XRAY_CONF_FILE" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $port,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$sni:443",
          "serverNames": ["$sni"],
          "privateKey": "$private_key",
          "shortIds": ["$short_id"],
          "fingerprint": "chrome"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" }
  ],
  "routing": {
    "domainStrategy": "$domain_strategy",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "direct"
      }
    ]
  }
}
EOF
}

# -------------------------------
# 主流程
# -------------------------------
reality_run() {
    ui_step "配置 Xray Reality 参数"

    # 端口
    local port=443
    if ui_confirm "使用默认端口 443" 30 y; then
        :
    else
        while true; do
            port=$(ui_read "请输入监听端口" "8443")
            if validate_port "$port"; then
                break
            else
                ui_err "端口无效 [$port]，请输入 1-65535 之间的数字"
            fi
        done
    fi

    # SNI
    local sni
    sni=$(select_sni)
    if ui_confirm "使用推荐域名 $sni" 30 y; then
        :
    else
        while true; do
            sni=$(ui_read "请输入自定义 SNI 域名" "$sni")
            if validate_domain "$sni"; then
                break
            else
                ui_err "域名格式无效 [$sni]，请输入有效的域名"
            fi
        done
    fi

    # 生成密钥
    local uuid
    local keypair
    local private_key
    local public_key
    local short_id

    uuid=$(gen_uuid)
    keypair=$(gen_keypair)
    private_key=$(echo "$keypair" | grep -oP 'Private key: \K.*')
    public_key=$(echo "$keypair" | grep -oP 'Public key: \K.*')
    short_id=$(gen_short_id)

    # GeoData
    install_geodata

    # 生成配置
    mkdir -p "$XRAY_CONF_DIR"
    generate_config "$port" "$sni" "$uuid" "$private_key" "$short_id"

    # 启动服务
    systemctl daemon-reload
    systemctl enable xray
    spinner_run "启动 Xray 服务" systemctl restart xray

    sleep 2
    if ! systemctl is-active --quiet xray; then
        ui_err "Xray 启动失败"
        journalctl -u xray -n 20 --no-pager
        exit 1
    fi

    # 保存环境变量
    cat > "$XRAY_ENV" <<EOF
# 自动生成，请勿手动修改
XRAY_PORT=$port
XRAY_UUID=$uuid
XRAY_PUBLIC_KEY=$public_key
XRAY_SHORT_ID=$short_id
XRAY_SNI=$sni
EOF

    ui_ok "Reality 配置完成"
}
