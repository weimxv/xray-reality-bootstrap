#!/usr/bin/env bash
# 子命令退出时展示的「常用命令」列表，供各 tool 在末尾 source 并调用 show_common_commands
# 安装时会被复制到 /usr/local/etc/xray-reality/common_commands.sh

show_common_commands() {
    local G="\033[32m" Y="\033[33m" N="\033[0m"
    echo ""
    echo -e "${Y}------------------------------------------------${N}"
    echo -e "  ${G}常用工具:${N}  xinfo (信息) | net (网络) | swap (内存) | f2b (防火墙) | log (日志)"
    echo -e "  ${G}运维命令:${N}  ports (端口) | bbr (内核) | bt (封禁) | sni (域名) | name (别名)"
    echo -e "${Y}------------------------------------------------${N}"
}
