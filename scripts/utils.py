#!/usr/bin/env python3
# =============================================================================
# Cloud Advanced Downloader - Python Utilities
# Description: Helper functions for download management and UI
# Version: 2.0.0
# =============================================================================

import os
import sys
import re
import time
import json
import subprocess
import threading
from pathlib import Path
from typing import List, Dict, Optional, Callable, Tuple
from dataclasses import dataclass
from urllib.parse import urlparse

# Try to import optional dependencies
try:
    from tqdm import tqdm
    TQDM_AVAILABLE = True
except ImportError:
    TQDM_AVAILABLE = False

try:
    from IPython.display import HTML, display, clear_output
    IPYTHON_AVAILABLE = True
except ImportError:
    IPYTHON_AVAILABLE = False

# =============================================================================
# CONFIGURATION
# =============================================================================

DEFAULT_DOWNLOAD_DIR = "/content/download"
ARIA2_RPC_PORT = 6800
ARIA2_SECRET = "cloud_downloader_2024"

# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class DownloadTask:
    """Represents a single download task"""
    url: str
    engine: str
    output_name: Optional[str] = None
    status: str = "pending"  # pending, downloading, completed, failed
    progress: float = 0.0
    speed: str = "0 B/s"
    size: str = "Unknown"
    error: Optional[str] = None

@dataclass
class EngineInfo:
    """Information about download engine"""
    name: str
    description: str
    pros: List[str]
    cons: List[str]
    max_connections: int
    supports_resume: bool
    best_for: str

# =============================================================================
# ENGINE INFORMATION
# =============================================================================

ENGINES = {
    "aria2": EngineInfo(
        name="Aria2",
        description="Ultra-fast download accelerator with multi-connection support",
        pros=["Multi-threaded (up to 32x)", "Resume support", "RPC control", "Best for large files"],
        cons=["Requires setup", "More complex"],
        max_connections=32,
        supports_resume=True,
        best_for="Large files, slow servers"
    ),
    "wget": EngineInfo(
        name="Wget",
        description="Simple and reliable HTTP/HTTPS/FTP downloader",
        pros=["Simple to use", "Widely supported", "Stable"],
        cons=["Single connection", "Limited features"],
        max_connections=1,
        supports_resume=True,
        best_for="Small files, direct links"
    ),
    "curl": EngineInfo(
        name="cURL",
        description="Powerful data transfer tool with many protocols",
        pros=["Protocol versatile", "Good for APIs", "Flexible"],
        cons=["Single connection", "Complex syntax"],
        max_connections=1,
        supports_resume=True,
        best_for="API downloads, special protocols"
    ),
    "mega": EngineInfo(
        name="Mega Auto",
        description="Specialized Mega.nz downloader with bypass support",
        pros=["No quota limit", "Resume support", "Auto-extract"],
        cons=["Mega only", "Slower than direct"],
        max_connections=4,
        supports_resume=True,
        best_for="Mega.nz files"
    )
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

def format_bytes(size_bytes: int) -> str:
    """Convert bytes to human readable format"""
    if size_bytes == 0:
        return "0 B"
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024
        i += 1
    return f"{size_bytes:.2f} {size_names[i]}"

def format_speed(speed_bytes: float) -> str:
    """Format download speed"""
    return f"{format_bytes(int(speed_bytes))}/s"

def validate_url(url: str) -> Tuple[bool, str]:
    """Validate download URL"""
    if not url or not url.strip():
        return False, "URL is empty"
    
    url = url.strip()
    
    # Check for valid schemes
    parsed = urlparse(url)
    if parsed.scheme not in ['http', 'https', 'ftp', 'ftps']:
        # Allow Mega URLs
        if 'mega.nz' in url:
            return True, "Valid Mega.nz URL"
        return False, f"Invalid URL scheme: {parsed.scheme}"
    
    if not parsed.netloc:
        return False, "Invalid URL: no domain"
    
    return True, "Valid URL"

def detect_url_type(url: str) -> str:
    """Detect the type of URL"""
    url = url.lower()
    if 'mega.nz' in url or 'mega.co.nz' in url:
        return "mega"
    elif any(x in url for x in ['drive.google.com', 'docs.google.com']):
        return "gdrive"
    elif 'mediafire.com' in url:
        return "mediafire"
    elif 'github.com' in url:
        return "github"
    else:
        return "direct"

def get_filename_from_url(url: str) -> Optional[str]:
    """Extract filename from URL"""
    parsed = urlparse(url)
    path = parsed.path
    if path:
        filename = os.path.basename(path)
        if filename:
            return filename
    return None

def ensure_dir(directory: str) -> str:
    """Ensure directory exists and return path"""
    Path(directory).mkdir(parents=True, exist_ok=True)
    return directory

def get_download_dir() -> str:
    """Get default download directory"""
    ensure_dir(DEFAULT_DOWNLOAD_DIR)
    return DEFAULT_DOWNLOAD_DIR

def clean_filename(filename: str) -> str:
    """Clean filename for safe filesystem use"""
    # Remove invalid characters
    filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
    # Remove control characters
    filename = re.sub(r'[\x00-\x1f\x7f]', '', filename)
    # Limit length
    if len(filename) > 255:
        name, ext = os.path.splitext(filename)
        filename = name[:250] + ext
    return filename.strip()

# =============================================================================
# PROGRESS TRACKING
# =============================================================================

class DownloadProgress:
    """Track download progress with callbacks"""
    
    def __init__(self, total: int = 0, desc: str = "Downloading"):
        self.total = total
        self.desc = desc
        self.current = 0
        self.start_time = time.time()
        self.callbacks: List[Callable] = []
        self._lock = threading.Lock()
        
    def add_callback(self, callback: Callable):
        """Add progress callback"""
        self.callbacks.append(callback)
        
    def update(self, n: int = 1):
        """Update progress"""
        with self._lock:
            self.current += n
            elapsed = time.time() - self.start_time
            speed = self.current / elapsed if elapsed > 0 else 0
            
            progress = {
                'current': self.current,
                'total': self.total,
                'percentage': (self.current / self.total * 100) if self.total > 0 else 0,
                'speed': speed,
                'elapsed': elapsed
            }
            
            for callback in self.callbacks:
                try:
                    callback(progress)
                except Exception:
                    pass
                    
    def get_progress(self) -> Dict:
        """Get current progress info"""
        elapsed = time.time() - self.start_time
        speed = self.current / elapsed if elapsed > 0 else 0
        return {
            'current': self.current,
            'total': self.total,
            'percentage': (self.current / self.total * 100) if self.total > 0 else 0,
            'speed': speed,
            'elapsed': elapsed
        }

# =============================================================================
# ARIA2 RPC FUNCTIONS
# =============================================================================

def aria2_rpc_call(method: str, params: List = None) -> Optional[Dict]:
    """Make Aria2 RPC call"""
    try:
        import requests
        
        rpc_url = f"http://localhost:{ARIA2_RPC_PORT}/jsonrpc"
        payload = {
            "jsonrpc": "2.0",
            "id": "cloud_downloader",
            "method": f"aria2.{method}",
            "params": [f"token:{ARIA2_SECRET}"] + (params or [])
        }
        
        response = requests.post(rpc_url, json=payload, timeout=5)
        if response.status_code == 200:
            return response.json()
    except Exception as e:
        pass
    return None

def get_aria2_version() -> Optional[str]:
    """Get Aria2 version"""
    result = aria2_rpc_call("getVersion")
    if result and 'result' in result:
        return result['result'].get('version')
    return None

def add_aria2_download(url: str, options: Dict = None) -> Optional[str]:
    """Add download to Aria2"""
    params = [[url]]
    if options:
        params.append(options)
    
    result = aria2_rpc_call("addUri", params)
    if result and 'result' in result:
        return result['result']  # Returns GID
    return None

def get_aria2_status(gid: str) -> Optional[Dict]:
    """Get download status from Aria2"""
    result = aria2_rpc_call("tellStatus", [gid])
    if result and 'result' in result:
        return result['result']
    return None

# =============================================================================
# UI HELPERS
# =============================================================================

def create_progress_bar(percentage: float, width: int = 30) -> str:
    """Create ASCII progress bar"""
    filled = int(width * percentage / 100)
    bar = "█" * filled + "░" * (width - filled)
    return f"[{bar}] {percentage:.1f}%"

def display_engine_info(engine_name: str) -> str:
    """Display formatted engine information"""
    engine = ENGINES.get(engine_name.lower())
    if not engine:
        return f"Unknown engine: {engine_name}"
    
    html = f"""
    <div style="
        background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
        color: white;
        padding: 15px;
        border-radius: 10px;
        margin: 10px 0;
        font-family: 'Segoe UI', sans-serif;
    ">
        <h3 style="margin: 0 0 10px 0;">⚡ {engine.name}</h3>
        <p style="margin: 5px 0; opacity: 0.9;">{engine.description}</p>
        
        <div style="display: flex; gap: 20px; margin-top: 15px;">
            <div style="flex: 1;">
                <strong style="color: #4CAF50;">✓ Pros:</strong>
                <ul style="margin: 5px 0; padding-left: 20px; font-size: 0.9em;">
                    {''.join(f'<li>{pro}</li>' for pro in engine.pros)}
                </ul>
            </div>
            <div style="flex: 1;">
                <strong style="color: #ff6b6b;">✗ Cons:</strong>
                <ul style="margin: 5px 0; padding-left: 20px; font-size: 0.9em;">
                    {''.join(f'<li>{con}</li>' for con in engine.cons)}
                </ul>
            </div>
        </div>
        
        <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.2);">
            <span style="font-size: 0.85em;">
                <strong>Best for:</strong> {engine.best_for} | 
                <strong>Max connections:</strong> {engine.max_connections} |
                <strong>Resume:</strong> {'Yes' if engine.supports_resume else 'No'}
            </span>
        </div>
    </div>
    """
    return html

def loading_spinner_html(message: str = "Processing") -> str:
    """Generate loading spinner HTML"""
    return f"""
    <div style="
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 20px;
        font-family: 'Segoe UI', sans-serif;
    ">
        <div style="
            border: 4px solid #f3f3f3;
            border-top: 4px solid #3498db;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin-right: 15px;
        "></div>
        <span style="font-size: 1.1em; color: #333;">{message}...</span>
    </div>
    <style>
        @keyframes spin {{
            0% {{ transform: rotate(0deg); }}
            100% {{ transform: rotate(360deg); }}
        }}
    </style>
    """

# =============================================================================
# DOWNLOAD EXECUTORS
# =============================================================================

class DownloadExecutor:
    """Execute downloads with various engines"""
    
    def __init__(self, download_dir: str = None):
        self.download_dir = download_dir or get_download_dir()
        self.tasks: List[DownloadTask] = []
        
    def add_task(self, url: str, engine: str, output_name: str = None) -> DownloadTask:
        """Add download task"""
        task = DownloadTask(
            url=url,
            engine=engine.lower(),
            output_name=output_name
        )
        self.tasks.append(task)
        return task
        
    def execute_aria2(self, task: DownloadTask, connections: int = 16, split: int = 16) -> bool:
        """Execute download using Aria2"""
        try:
            task.status = "downloading"
            
            cmd = [
                "aria2c",
                "-x", str(connections),
                "-s", str(split),
                "-j", "5",
                "-k", "10M",
                "--continue=true",
                "--max-tries=10",
                "--retry-wait=5",
                f"--dir={self.download_dir}",
                "--summary-interval=1",
                "--console-log-level=warn"
            ]
            
            if task.output_name:
                cmd.extend(["--out", task.output_name])
                
            cmd.append(task.url)
            
            # Execute and capture output
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True
            )
            
            # Parse output for progress
            for line in process.stdout:
                # Update progress based on output
                if "Download complete" in line:
                    task.progress = 100.0
                    
            process.wait()
            
            if process.returncode == 0:
                task.status = "completed"
                task.progress = 100.0
                return True
            else:
                task.status = "failed"
                task.error = f"Exit code: {process.returncode}"
                return False
                
        except Exception as e:
            task.status = "failed"
            task.error = str(e)
            return False
            
    def execute_wget(self, task: DownloadTask) -> bool:
        """Execute download using wget"""
        try:
            task.status = "downloading"
            
            cmd = [
                "wget",
                "--continue",
                "--progress=bar:force",
                "--tries=10",
                "--timeout=60",
                "-P", self.download_dir
            ]
            
            if task.output_name:
                cmd.extend(["-O", os.path.join(self.download_dir, task.output_name)])
                
            cmd.append(task.url)
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                task.status = "completed"
                task.progress = 100.0
                return True
            else:
                task.status = "failed"
                task.error = result.stderr
                return False
                
        except Exception as e:
            task.status = "failed"
            task.error = str(e)
            return False
            
    def execute_curl(self, task: DownloadTask) -> bool:
        """Execute download using curl"""
        try:
            task.status = "downloading"
            
            output_path = os.path.join(
                self.download_dir,
                task.output_name or get_filename_from_url(task.url) or "download"
            )
            
            cmd = [
                "curl",
                "-L",  # Follow redirects
                "-C", "-",  # Continue
                "--retry", "10",
                "--retry-delay", "5",
                "--max-time", "0",
                "--progress-bar",
                "-o", output_path,
                task.url
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                task.status = "completed"
                task.progress = 100.0
                return True
            else:
                task.status = "failed"
                task.error = result.stderr
                return False
                
        except Exception as e:
            task.status = "failed"
            task.error = str(e)
            return False
            
    def execute_mega(self, task: DownloadTask) -> bool:
        """Execute Mega.nz download"""
        try:
            task.status = "downloading"
            
            # Use megatools if available
            if subprocess.run(["which", "megadl"], capture_output=True).returncode == 0:
                cmd = ["megadl", f"--output={self.download_dir}/"]
                if task.output_name:
                    cmd[1] = f"--output={self.download_dir}/{task.output_name}"
                cmd.append(task.url)
                
                result = subprocess.run(cmd, capture_output=True, text=True)
                
                if result.returncode == 0:
                    task.status = "completed"
                    task.progress = 100.0
                    return True
                else:
                    task.status = "failed"
                    task.error = result.stderr
                    return False
            else:
                # Fallback to Python mega
                task.error = "megatools not installed"
                task.status = "failed"
                return False
                
        except Exception as e:
            task.status = "failed"
            task.error = str(e)
            return False

# =============================================================================
# INITIALIZATION
# =============================================================================

def init_environment():
    """Initialize download environment"""
    ensure_dir(DEFAULT_DOWNLOAD_DIR)
    
    # Check installed tools
    tools = {
        'aria2c': 'Aria2',
        'wget': 'Wget',
        'curl': 'cURL',
        'megadl': 'Mega Tools'
    }
    
    available = []
    for cmd, name in tools.items():
        if subprocess.run(['which', cmd], capture_output=True).returncode == 0:
            available.append(name)
    
    return available

# Run initialization on import
AVAILABLE_ENGINES = init_environment()

if __name__ == "__main__":
    print("Cloud Advanced Downloader - Utilities Module")
    print(f"Available engines: {', '.join(AVAILABLE_ENGINES)}")
