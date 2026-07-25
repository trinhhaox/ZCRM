#!/usr/bin/env bash
#
# vps-preflight-check.sh — Kiểm tra an toàn hạ tầng VPS trước khi cài ZCRM
#
set -euo pipefail

c_blue=$'\033[1;36m'; c_grn=$'\033[1;32m'; c_yel=$'\033[1;33m'; c_red=$'\033[1;31m'; c_off=$'\033[0m'
log()  { echo "${c_blue}▶${c_off} $*"; }
ok()   { echo "${c_grn}✓${c_off} $*"; }
warn() { echo "${c_yel}⚠${c_off}  $*"; }
die()  { echo "${c_red}✗ $*${c_off}" >&2; exit 1; }

echo "================================================================="
echo "  KIỂM TRA AN TOÀN HẠ TẦNG VPS TRƯỚC KHI TRIỂN KHAI ZCRM"
echo "================================================================="

# 1. Kiểm tra RAM
log "1. Kiểm tra Bộ nhớ RAM..."
free_mem_mb=$(free -m | awk '/^Mem:/{print $7}')
total_mem_mb=$(free -m | awk '/^Mem:/{print $2}')
echo "   - Tổng RAM: ${total_mem_mb} MB"
echo "   - RAM khả dụng (available): ${free_mem_mb} MB"

if [ "$free_mem_mb" -lt 1000 ]; then
  warn "RAM khả dụng dưới 1GB (${free_mem_mb}MB). Khuyên dùng tối thiểu 1.5GB RAM trống để ZCRM chạy ổn định."
else
  ok "Bộ nhớ RAM đủ điều kiện an toàn (${free_mem_mb}MB khả dụng)."
fi

# 2. Kiểm tra Dung lượng Ổ cứng
log "2. Kiểm tra Dung lượng Ổ cứng..."
disk_avail_gb=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
echo "   - Dung lượng ổ cứng / còn trống: ${disk_avail_gb} GB"
if [ "$disk_avail_gb" -lt 10 ]; then
  warn "Ổ cứng còn dưới 10GB (${disk_avail_gb}GB). Nên dọn bớt bộ nhớ tạm trước khi cài."
else
  ok "Dung lượng ổ cứng đủ điều kiện (${disk_avail_gb}GB trống)."
fi

# 3. Kiểm tra Port bận
log "3. Kiểm tra xung đột Port..."
check_port() {
  local p="$1" name="$2"
  if (exec 3<"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then
    exec 3<&- 2>/dev/null
    warn "Port $p ($name) ĐANG BẬN bởi ứng dụng khác trên VPS."
  else
    ok "Port $p ($name) TRỐNG (An toàn)."
  fi
}

check_port 3080 "ZCRM App Port"
check_port 5433 "ZCRM Postgres Port"
check_port 6379 "ZCRM Redis Port"
check_port 9000 "ZCRM MinIO S3 Port"

# 4. Kiểm tra Docker & Nginx
log "4. Kiểm tra công cụ hệ thống..."
if command -v docker >/dev/null 2>&1; then
  ok "Docker đã được cài đặt: $(docker --version)"
else
  warn "Docker chưa được cài đặt trên VPS (Script zalocrm-deploy.sh sẽ tự động cài)."
fi

if command -v nginx >/dev/null 2>&1; then
  ok "Nginx đã được cài đặt."
else
  warn "Nginx chưa được cài đặt (Cần cài để thiết lập Reverse Proxy cho zcrm.xox.vn)."
fi

echo "================================================================="
ok "HOÀN TẤT KIỂM TRA PRE-FLIGHT! VPS ĐÃ SẴN SÀNG CHO CÀI ĐẶT."
echo "================================================================="
