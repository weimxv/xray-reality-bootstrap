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
    "$XRAY_BIN" x25519 2>/dev/null || true
}

# 去除行首的 "Private key:" / "PrivateKey:" / "Public key:" / "PublicKey:" 等前缀，只保留 base64
_strip_key_prefix() {
    echo "$1" | sed 's/^.*[Pp]rivate[Kk]ey:\s*//; s/^.*[Pp]ublic[Kk]ey:\s*//; s/^.*私钥:\s*//; s/^.*公钥:\s*//' | tr -d '\n\r '
}

# 从 x25519 输出解析私钥/公钥（兼容中英文、PrivateKey:/PublicKey: 无空格格式及多行格式）
parse_keypair() {
    local keypair="$1"
    local priv=""
    local pub=""
    # 英文: Private key: xxx / Public key: xxx（有空格）
    priv=$(echo "$keypair" | sed -n 's/.*[Pp]rivate key:\s*//p' | tr -d '\n\r ')
    pub=$(echo "$keypair" | sed -n 's/.*[Pp]ublic key:\s*//p' | tr -d '\n\r ')
    # 英文: PrivateKey: xxx / PublicKey: xxx（无空格，Xray 新版本）
    if [[ -z "$priv" ]]; then
        priv=$(echo "$keypair" | sed -n 's/.*[Pp]rivate[Kk]ey:\s*//p' | tr -d '\n\r ')
    fi
    if [[ -z "$pub" ]]; then
        pub=$(echo "$keypair" | sed -n 's/.*[Pp]ublic[Kk]ey:\s*//p' | tr -d '\n\r ')
    fi
    # 中文输出（私钥 / 公钥）
    if [[ -z "$priv" ]]; then
        priv=$(echo "$keypair" | sed -n 's/.*私钥:\s*//p' | tr -d '\n\r ')
    fi
    if [[ -z "$pub" ]]; then
        pub=$(echo "$keypair" | sed -n 's/.*公钥:\s*//p' | tr -d '\n\r ')
    fi
    # 退路：按行取，并去掉可能的前缀（避免整行 "PrivateKey:xxx" 写入 config 导致 invalid privateKey）
    if [[ -z "$priv" || -z "$pub" ]]; then
        local line1 line2
        line1=$(_strip_key_prefix "$(echo "$keypair" | sed -n '1p')")
        line2=$(_strip_key_prefix "$(echo "$keypair" | sed -n '2p')")
        if [[ -n "$line1" && -n "$line2" && ${#line1} -gt 20 && ${#line2} -gt 20 ]]; then
            priv="${priv:-$line1}"
            pub="${pub:-$line2}"
        fi
    fi
    echo "$priv"
    echo "$pub"
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

    # 提示输出到 stderr，避免被 sni=$(select_sni) 捕获（否则会混入 ANSI 码写入 config 导致 Xray 解析失败）
    ui_info "正在测速 SNI 域名..." >&2
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

    ui_ok "推荐 SNI: $best_domain (${best_time}ms)" >&2
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

# 写入 JSON 前去除控制字符（避免 ANSI/终端码导致 invalid character '\x1b'）
json_safe() {
    echo -n "$1" | tr -d '\000-\037\177'
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

    sni=$(json_safe "$sni")
    uuid=$(json_safe "$uuid")
    private_key=$(json_safe "$private_key")
    short_id=$(json_safe "$short_id")

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

    # SNI：默认使用测速推荐的最优域名，安装后可用 'sni' 命令修改
    local sni
    sni=$(select_sni)
    ui_ok "将使用推荐 SNI: $sni（安装后可用 'sni' 命令修改）"

    # 生成密钥（失败时自动重试一次，并兼容多种 Xray 输出格式）
    local uuid
    local keypair
    local private_key
    local public_key
    local short_id
    local parsed

    uuid=$(gen_uuid)
    for attempt in 1 2; do
        keypair=$(gen_keypair)
        parsed=$(parse_keypair "$keypair")
        private_key=$(echo "$parsed" | sed -n '1p')
        public_key=$(echo "$parsed" | sed -n '2p')
        if [[ -n "$private_key" && -n "$public_key" ]]; then
            break
        fi
        [[ $attempt -eq 1 ]] && ui_warn "密钥解析未命中，重试一次..."
    done
    if [[ -z "$private_key" || -z "$public_key" ]]; then
        ui_err "Xray 密钥生成或解析失败，请检查 Xray 版本与输出格式"
        echo ""
        echo "原始输出:"
        echo "$keypair" | head -5
        echo ""
        ui_info "重试方法: 重新执行安装（仅会重跑 Reality 与防火墙步骤）"
        echo "  cd /opt/xray-reality-bootstrap && bash install.sh reality"
        echo ""
        exit 1
    fi
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
