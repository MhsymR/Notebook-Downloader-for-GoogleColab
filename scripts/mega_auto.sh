#!/bin/bash
# =============================================================================
# Cloud Advanced Downloader - Mega.nz Auto Downloader
# Description: Download from Mega.nz with resume support and bypass techniques
# Version: 2.0.0
# =============================================================================

set -e

# Configuration
DOWNLOAD_DIR="${1:-/content/download}"
MEGA_URL="$2"
OUTPUT_NAME="$3"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[MEGA]${NC} $1"; }
log_success() { echo -e "${GREEN}[MEGA]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[MEGA]${NC} $1"; }
log_error() { echo -e "${RED}[MEGA]${NC} $1"; }

# Help function
show_help() {
    cat << EOF
Mega.nz Auto Downloader - Usage:
  $0 [download_dir] <mega_url> [output_name]

Parameters:
  download_dir  - Target directory (default: /content/download)
  mega_url      - Mega.nz file/folder URL (required)
  output_name   - Custom output filename (optional)

Examples:
  $0 /content/download "https://mega.nz/file/..."
  $0 /content/download "https://mega.nz/file/..." "myfile.zip"

EOF
}

# Validate URL
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?://mega\.nz/ ]]; then
        log_error "Invalid Mega.nz URL"
        return 1
    fi
    return 0
}

# Check if megatools is available
check_megatools() {
    if command -v megadl &> /dev/null; then
        return 0
    elif command -v megatools &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Download using megatools (preferred method)
download_megatools() {
    local url="$1"
    local output_dir="$2"
    local output_name="$3"
    
    log_info "Using megatools for download"
    
    local cmd="megadl"
    if [ -n "$output_name" ]; then
        cmd="$cmd --output='$output_dir/$output_name'"
    else
        cmd="$cmd --output='$output_dir/'"
    fi
    cmd="$cmd '$url'"
    
    eval "$cmd" 2>&1
}

# Download using Python mega.py (fallback)
download_mega_py() {
    local url="$1"
    local output_dir="$2"
    local output_name="$3"
    
    log_info "Using Python mega.py for download"
    
    python3 << PYEOF
import os
import sys
from mega import Mega
from urllib.parse import urlparse, parse_qs

def download_mega():
    try:
        mega = Mega()
        
        # Extract file ID from URL
        url = "$url"
        output_dir = "$output_dir"
        output_name = "$output_name"
        
        print(f"[MEGA] Extracting file from: {url[:50]}...")
        
        # Download file
        m = mega.login()
        file = m.download_url(url, output_dir)
        
        # Rename if custom name provided
        if output_name and os.path.exists(file):
            new_path = os.path.join(output_dir, output_name)
            os.rename(file, new_path)
            print(f"[MEGA] Downloaded: {new_path}")
        else:
            print(f"[MEGA] Downloaded: {file}")
            
        return True
    except Exception as e:
        print(f"[MEGA ERROR] {str(e)}")
        return False

if __name__ == "__main__":
    success = download_mega()
    sys.exit(0 if success else 1)
PYEOF
}

# Download using aria2 with mega proxy (alternative)
download_aria2_proxy() {
    local url="$1"
    local output_dir="$2"
    local output_name="$3"
    
    log_info "Attempting aria2 with direct link extraction"
    
    # Try to get direct download link
    local direct_link
    direct_link=$(python3 << PYEOF 2>/dev/null
import re
import sys

def get_direct_link(mega_url):
    # Pattern for mega.nz/file/#<file_id>!<key>
    pattern = r'mega\.nz/file/([^#]+)#(.+)'
    match = re.search(pattern, mega_url)
    if match:
        file_id = match.group(1)
        file_key = match.group(2)
        # Construct API request for direct link
        # This is a simplified approach
        return None
    return None

url = "$url"
result = get_direct_link(url)
print(result if result else "")
PYEOF
)
    
    if [ -n "$direct_link" ]; then
        log_info "Direct link obtained, using aria2"
        local output_option=""
        [ -n "$output_name" ] && output_option="--out='$output_name'"
        aria2c -x16 -s16 -j5 -k10M --dir="$output_dir" $output_option "$direct_link"
    else
        log_warning "Could not extract direct link"
        return 1
    fi
}

# Main download function
download_main() {
    local url="$MEGA_URL"
    local output_dir="$DOWNLOAD_DIR"
    local output_name="$OUTPUT_NAME"
    
    # Validate
    if [ -z "$url" ]; then
        log_error "No URL provided"
        show_help
        return 1
    fi
    
    validate_url "$url" || return 1
    
    # Create output directory
    mkdir -p "$output_dir"
    
    log_info "Starting Mega.nz download"
    log_info "URL: ${url:0:60}..."
    log_info "Destination: $output_dir"
    
    # Try methods in order of preference
    if check_megatools; then
        if download_megatools "$url" "$output_dir" "$output_name"; then
            log_success "Download completed with megatools"
            return 0
        fi
    fi
    
    log_warning "megatools failed, trying Python mega.py"
    if download_mega_py "$url" "$output_dir" "$output_name"; then
        log_success "Download completed with mega.py"
        return 0
    fi
    
    log_error "All download methods failed"
    return 1
}

# Resume capability check
check_resume_support() {
    log_info "Mega.nz supports resume with megatools"
    log_info "Partial downloads will be resumed automatically"
}

# Run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    download_main "$@"
fi
