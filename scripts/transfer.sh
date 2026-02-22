#!/bin/bash
# =============================================================================
# Cloud Advanced Downloader - Transfer to Google Drive
# Description: Move downloaded files to Google Drive with progress tracking
# Version: 2.0.0
# =============================================================================

set -e

# Configuration
SOURCE_DIR="${1:-/content/download}"
DEST_DIR="${2:-/content/drive/MyDrive/Downloads}"
MODE="${3:-move}"  # move or copy

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[TRANSFER]${NC} $1"; }
log_success() { echo -e "${GREEN}[TRANSFER]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[TRANSFER]${NC} $1"; }
log_error() { echo -e "${RED}[TRANSFER]${NC} $1"; }
log_detail() { echo -e "${CYAN}  →${NC} $1"; }

# Help function
show_help() {
    cat << EOF
Transfer to Google Drive - Usage:
  $0 [source_dir] [dest_dir] [mode]

Parameters:
  source_dir  - Source directory (default: /content/download)
  dest_dir    - Destination in Drive (default: /content/drive/MyDrive/Downloads)
  mode        - 'move' or 'copy' (default: move)

Examples:
  $0                                    # Use defaults
  $0 /content/download /content/drive/MyDrive/Movies
  $0 /content/download /content/drive/MyDrive/Files copy

EOF
}

# Check if Drive is mounted
check_drive_mounted() {
    if [ ! -d "/content/drive" ]; then
        log_error "Google Drive not mounted!"
        log_detail "Please mount Google Drive first using Cell 1"
        return 1
    fi
    
    if [ ! -d "/content/drive/MyDrive" ]; then
        log_error "MyDrive folder not accessible"
        log_detail "Ensure Drive is properly mounted"
        return 1
    fi
    
    return 0
}

# Get directory size
get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sb "$dir" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# Format bytes to human readable
format_size() {
    local bytes="$1"
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1024" | bc)KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc)MB"
    else
        echo "$(echo "scale=2; $bytes/1073741824" | bc)GB"
    fi
}

# Count files
count_files() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Transfer with progress
transfer_with_progress() {
    local src="$1"
    local dst="$2"
    local mode="$3"
    
    # Create destination directory
    mkdir -p "$dst"
    
    # Get source info
    local src_size
    local src_files
    src_size=$(get_dir_size "$src")
    src_files=$(count_files "$src")
    
    log_info "Source: $src"
    log_detail "Size: $(format_size $src_size)"
    log_detail "Files: $src_files"
    log_info "Destination: $dst"
    log_info "Mode: $mode"
    echo ""
    
    # Check if source is empty
    if [ "$src_files" -eq 0 ]; then
        log_warning "No files to transfer"
        return 0
    fi
    
    # Perform transfer with rsync or cp/mv
    if command -v rsync &> /dev/null; then
        local rsync_opts="-ah --progress --stats"
        [ "$mode" = "move" ] && rsync_opts="$rsync_opts --remove-source-files"
        
        log_info "Using rsync for transfer..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        rsync $rsync_opts "$src/" "$dst/" 2>&1 | grep -E '(^sending|^sent|^total|^[0-9]+)' || true
        
        # Clean up empty directories if move mode
        if [ "$mode" = "move" ]; then
            find "$src" -type d -empty -delete 2>/dev/null || true
        fi
    else
        # Fallback to cp/mv with pv
        log_info "Using standard transfer method..."
        
        for file in "$src"/*; do
            if [ -f "$file" ]; then
                local filename
                filename=$(basename "$file")
                local filesize
                filesize=$(stat -c%s "$file" 2>/dev/null || echo "0")
                
                echo "Transferring: $filename ($(format_size $filesize))"
                
                if command -v pv &> /dev/null && [ "$filesize" -gt 0 ]; then
                    pv -s "$filesize" "$file" > "$dst/$filename"
                else
                    cp -v "$file" "$dst/" 2>&1 | head -1
                fi
                
                if [ "$mode" = "move" ]; then
                    rm -f "$file"
                fi
            fi
        done
    fi
    
    echo ""
    log_success "Transfer completed!"
    
    # Show destination info
    local dst_size
    local dst_files
    dst_size=$(get_dir_size "$dst")
    dst_files=$(count_files "$dst")
    
    log_info "Destination Summary:"
    log_detail "Path: $dst"
    log_detail "Total Size: $(format_size $dst_size)"
    log_detail "Total Files: $dst_files"
}

# Verify transfer
verify_transfer() {
    local src="$1"
    local dst="$2"
    local mode="$3"
    
    if [ "$mode" = "move" ]; then
        local remaining
        remaining=$(count_files "$src")
        if [ "$remaining" -eq 0 ]; then
            log_success "Source directory is now empty"
        else
            log_warning "$remaining files remain in source"
        fi
    fi
    
    # List destination contents
    echo ""
    log_info "Files in destination:"
    ls -lh "$dst" 2>/dev/null | tail -n +2 | while read line; do
        log_detail "$line"
    done
}

# Main transfer function
transfer_main() {
    local src="${SOURCE_DIR%/}"
    local dst="${DEST_DIR%/}"
    local mode="$MODE"
    
    # Validate mode
    if [ "$mode" != "move" ] && [ "$mode" != "copy" ]; then
        log_error "Invalid mode: $mode (use 'move' or 'copy')"
        return 1
    fi
    
    # Check Drive
    check_drive_mounted || return 1
    
    # Check source exists
    if [ ! -d "$src" ]; then
        log_error "Source directory does not exist: $src"
        return 1
    fi
    
    # Execute transfer
    transfer_with_progress "$src" "$dst" "$mode"
    verify_transfer "$src" "$dst" "$mode"
    
    return 0
}

# Run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    transfer_main "$@"
fi
