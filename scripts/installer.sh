#!/bin/bash
# =============================================================================
# Cloud Advanced Downloader - Master Installer
# Description: Install all required packages and dependencies
# Version: 2.0.0
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Progress tracker
TOTAL_STEPS=6
CURRENT_STEP=0

show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    log_info "Step $CURRENT_STEP/$TOTAL_STEPS: $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# =============================================================================
# MAIN INSTALLATION
# =============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          CLOUD ADVANCED DOWNLOADER - INSTALLER               ║"
echo "║                    Version 2.0.0                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Update package list
show_progress "Updating package repository"
apt-get update -qq > /dev/null 2>&1
log_success "Package list updated"

# Step 2: Install system dependencies
show_progress "Installing system dependencies"
apt-get install -y -qq \
    aria2 \
    wget \
    curl \
    p7zip-full \
    p7zip-rar \
    unzip \
    zip \
    pv \
    rsync \
    jq \
    > /dev/null 2>&1
log_success "System dependencies installed"

# Step 3: Install Python dependencies
show_progress "Installing Python packages"
pip install -q --upgrade pip
pip install -q \
    requests \
    urllib3 \
    tqdm \
    beautifulsoup4 \
    lxml \
    mega.py \
    google-colab \
    ipywidgets \
    psutil
log_success "Python packages installed"

# Step 4: Setup download directory
show_progress "Setting up download directory"
DOWNLOAD_DIR="/content/download"
mkdir -p "$DOWNLOAD_DIR"
chmod 777 "$DOWNLOAD_DIR"
log_success "Download directory ready: $DOWNLOAD_DIR"

# Step 5: Install Mega tools
show_progress "Installing Mega.nz tools"
if ! command -v megadl &> /dev/null; then
    apt-get install -y -qq megatools > /dev/null 2>&1 || {
        log_warning "megatools not in repo, building from source..."
        apt-get install -y -qq build-essential libglib2.0-dev libssl-dev \
            libcurl4-openssl-dev libgirepository1.0-dev > /dev/null 2>&1
        cd /tmp
        wget -q https://megatools.megous.com/builds/megatools-1.11.1.20230212.tar.gz
        tar -xzf megatools-1.11.1.20230212.tar.gz
        cd megatools-1.11.1.20230212
        ./configure --prefix=/usr/local > /dev/null 2>&1
        make -j$(nproc) > /dev/null 2>&1
        make install > /dev/null 2>&1
        ldconfig
        rm -rf /tmp/megatools-*
    }
fi
log_success "Mega tools installed"

# Step 6: Verify installations
show_progress "Verifying installations"

check_command() {
    if command -v "$1" &> /dev/null; then
        version=$($1 --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
        printf "  %-12s ${GREEN}✓${NC} %s\n" "$1" "${version:-installed}"
        return 0
    else
        printf "  %-12s ${RED}✗${NC} not found\n" "$1"
        return 1
    fi
}

echo ""
echo "Installation Status:"
echo "────────────────────────────────────────"
check_command aria2c
check_command wget
check_command curl
check_command megadl
check_command 7z
check_command pv
check_command rsync
echo "────────────────────────────────────────"

# Final summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              INSTALLATION COMPLETED                          ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Download Folder: /content/download                          ║"
echo "║  Aria2 Config:    ~/.aria2/aria2.conf                        ║"
echo "║  Log Files:       /tmp/downloader_*.log                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log_success "All components ready. You can now use the downloader!"
echo ""
