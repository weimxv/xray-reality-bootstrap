#!/usr/bin/env bash

# ========== 基础颜色 ==========
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PURPLE="\033[35m"
GRAY="\033[90m"
PLAIN="\033[0m"
BOLD="\033[1m"

# ========== 语义标签 ==========
TAG_OK="${GREEN}[OK]${PLAIN}"
TAG_ERR="${RED}[ERR]${PLAIN}"
TAG_WARN="${YELLOW}[WARN]${PLAIN}"
TAG_INFO="${BLUE}[INFO]${PLAIN}"
TAG_STEP="${PURPLE}==>${PLAIN}"

# ========== 输出封装 ==========
ui_ok()    { echo -e "${TAG_OK} $*"; }
ui_err()   { echo -e "${TAG_ERR} $*" >&2; }
ui_warn()  { echo -e "${TAG_WARN} $*"; }
ui_info()  { echo -e "${TAG_INFO} $*"; }
ui_step()  { echo -e "${TAG_STEP} $*"; }
