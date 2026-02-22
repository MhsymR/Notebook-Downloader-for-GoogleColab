#!/bin/bash
# =============================================================================
# Cloud Advanced Downloader - Aria2 Setup & Configuration
# Description: Configure Aria2 with optimal settings for cloud downloads
# Version: 2.0.0
# =============================================================================

set -e

# Default configuration values
ARIA2_DIR="${HOME}/.aria2"
ARIA2_CONF="${ARIA2_DIR}/aria2.conf"
ARIA2_SESSION="${ARIA2_DIR}/aria2.session"
DOWNLOAD_DIR="/content/download"

# Parameters (can be overridden)
MAX_CONNECTIONS_PER_SERVER="${1:-16}"
SPLIT="${2:-16}"
MAX_CONCURRENT_DOWNLOADS="${3:-5}"
MIN_SPLIT_SIZE="${4:-10M}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[ARIA2]${NC} $1"; }
log_success() { echo -e "${GREEN}[ARIA2]${NC} $1"; }

# Create directories
mkdir -p "$ARIA2_DIR"
mkdir -p "$DOWNLOAD_DIR"
touch "$ARIA2_SESSION"

# Generate optimized configuration
cat > "$ARIA2_CONF" << EOF
# Aria2 Configuration for Cloud Advanced Downloader
# Auto-generated on $(date)

# Basic Settings
dir=${DOWNLOAD_DIR}
max-concurrent-downloads=${MAX_CONCURRENT_DOWNLOADS}
max-connection-per-server=${MAX_CONNECTIONS_PER_SERVER}
split=${SPLIT}
min-split-size=${MIN_SPLIT_SIZE}

# Performance Tuning
continue=true
max-tries=10
retry-wait=5
timeout=60
connect-timeout=60
lowest-speed-limit=0
disable-ipv6=true

# RPC Configuration (for web UI integration)
enable-rpc=true
rpc-listen-port=6800
rpc-max-request-size=1024M
rpc-listen-all=false
rpc-allow-origin-all=true
rpc-listen-all=false
rpc-secret=cloud_downloader_2024

# Logging
log=/tmp/aria2.log
log-level=warn
console-log-level=warn

# Session Management
input-file=${ARIA2_SESSION}
save-session=${ARIA2_SESSION}
save-session-interval=30
force-save=false

# Disk Cache
disk-cache=64M
file-allocation=falloc

# User Agent
user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.0

# BT Settings (for torrent support)
bt-enable-lpd=true
bt-max-peers=128
bt-request-peer-speed-limit=256K
seed-ratio=0.0
bt-stop-timeout=600
enable-dht=true
dht-listen-port=6881-6999
enable-peer-exchange=true

# FTP/HTTP Settings
ftp-pasv=true
http-accept-gzip=true
http-no-cache=true
EOF

# Create aria2 startup script
cat > "${ARIA2_DIR}/start_rpc.sh" << 'EOF'
#!/bin/bash
ARIA2_PID=$(pgrep -f "aria2c.*enable-rpc" || true)
if [ -n "$ARIA2_PID" ]; then
    kill "$ARIA2_PID" 2>/dev/null || true
    sleep 1
fi
aria2c --conf-path="${HOME}/.aria2/aria2.conf" --daemon
sleep 2
if pgrep -f "aria2c.*enable-rpc" > /dev/null; then
    echo "Aria2 RPC started on port 6800"
else
    echo "Failed to start Aria2 RPC"
    exit 1
fi
EOF

chmod +x "${ARIA2_DIR}/start_rpc.sh"

# Start Aria2 RPC daemon
"${ARIA2_DIR}/start_rpc.sh" > /dev/null 2>&1

log_success "Aria2 configured successfully"
echo ""
echo "Configuration Summary:"
echo "  Max Connections/Server: $MAX_CONNECTIONS_PER_SERVER"
echo "  Split Count:            $SPLIT"
echo "  Concurrent Downloads:   $MAX_CONCURRENT_DOWNLOADS"
echo "  Min Split Size:         $MIN_SPLIT_SIZE"
echo "  RPC Port:               6800"
echo "  Download Directory:     $DOWNLOAD_DIR"
echo ""
