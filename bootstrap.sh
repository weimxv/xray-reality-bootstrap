#!/usr/bin/env bash
#
# 一键安装入口脚本（无需预先安装 git）
# 用法: bash <(curl -fsSL https://raw.githubusercontent.com/weimxv/xray-reality-bootstrap/main/bootstrap.sh)
#
set -e

REPO_URL="https://github.com/weimxv/xray-reality-bootstrap"
ARCHIVE_URL="${REPO_URL}/archive/refs/heads/main.zip"
INSTALL_DIR="/opt/xray-reality-bootstrap"

echo "=============================================="
echo "  Xray Reality Bootstrap - 一键安装"
echo "=============================================="
echo ""

# 1. 检查 root
if [[ $EUID -ne 0 ]]; then
    echo "[ERR] 请使用 root 用户运行此脚本"
    echo "      例如: sudo bash bootstrap.sh"
    exit 1
fi

# 2. 检查/安装 curl 或 wget
need_curl_or_wget() {
    if command -v curl &>/dev/null; then
        echo "curl"
        return
    fi
    if command -v wget &>/dev/null; then
        echo "wget"
        return
    fi
    echo ""
}

DOWNLOADER=$(need_curl_or_wget)
if [[ -z "$DOWNLOADER" ]]; then
    echo "[INFO] 未检测到 curl/wget，正在安装..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y curl
    DOWNLOADER="curl"
fi

# 3. 创建安装目录并下载
echo "[INFO] 正在下载脚本..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [[ "$DOWNLOADER" == "curl" ]]; then
    curl -fsSL -o main.zip "$ARCHIVE_URL"
else
    wget -q -O main.zip "$ARCHIVE_URL"
fi

if [[ ! -s main.zip ]]; then
    echo "[ERR] 下载失败，请检查网络或 GitHub 可访问性"
    exit 1
fi

# 4. 解压（需要 unzip）
if ! command -v unzip &>/dev/null; then
    echo "[INFO] 正在安装 unzip..."
    apt-get update -qq
    apt-get install -y unzip
fi

unzip -o -q main.zip
rm -f main.zip

# 解压后目录名为 xray-reality-bootstrap-main
EXTRACTED="xray-reality-bootstrap-main"
if [[ -d "$EXTRACTED" ]]; then
    # 将文件移动到当前目录，避免多层嵌套
    shopt -s dotglob
    mv "$EXTRACTED"/* .
    rmdir "$EXTRACTED" 2>/dev/null || true
fi

# 5. 执行安装
echo ""
echo "[INFO] 开始执行部署脚本..."
echo ""

exec bash "$INSTALL_DIR/install.sh" "$@"
