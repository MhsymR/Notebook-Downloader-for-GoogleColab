# Cloud Advanced Downloader

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/yourusername/Cloud-Advanced-Downloader/blob/main/notebook/Advanced_Downloader.ipynb)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/yourusername/Cloud-Advanced-Downloader)

> **Professional Multi-Engine Download Manager for Google Colab**

Cloud Advanced Downloader adalah sistem download manager berbasis cloud yang dirancang khusus untuk Google Colab. Dengan antarmuka modern dan dukungan multi-engine, sistem ini memungkinkan pengguna untuk mengunduh file dengan cepat, terstruktur, dan efisien.

---

## Fitur Utama

### Multi-Engine Support
- **Aria2** - Ultra-fast downloader dengan multi-threading (hingga 32 koneksi)
- **Wget** - Downloader sederhana dan handal untuk HTTP/HTTPS/FTP
- **cURL** - Tool transfer data yang powerful dengan dukungan multiple protocol
- **Mega Auto** - Downloader khusus Mega.nz dengan bypass quota

### Batch Processing
- Input hingga **5 link sekaligus**
- Mode download **serentak (parallel)** atau **bergilir (sequential)**
- Manajemen antrian otomatis

### Konfigurasi Aria2 Lanjutan
- Slider kontrol jumlah koneksi (1-32)
- Slider kontrol split download (1-32)
- RPC enable untuk kontrol remote
- Auto-resume untuk download terputus

### Mega.nz Integration
- Download Mega.nz **tanpa limit quota**
- Support resume download
- Handling file besar dengan stabil

### Real-time Progress Tracking
- Progress bar animasi realtime
- Persentase download live
- Kecepatan download (speed meter)
- Status sukses/gagal per file

### Google Drive Integration
- Mount Drive dengan toggle switch
- Transfer file otomatis ke Drive
- Pilihan mode Move atau Copy
- Progress tracking saat transfer

---

## Struktur Repository

```
Cloud-Advanced-Downloader/
│
├── notebook/
│   └── Advanced_Downloader.ipynb    # Notebook utama (4 cells)
│
├── scripts/
│   ├── installer.sh                 # Master installer
│   ├── aria2_setup.sh              # Konfigurasi Aria2
│   ├── mega_auto.sh                # Mega.nz downloader
│   ├── transfer.sh                 # Transfer ke Drive
│   └── utils.py                    # Python utilities
│
├── assets/
│   └── loading_animation.html      # Animasi loading
│
├── README.md                        # Dokumentasi ini
└── requirements.txt                 # Python dependencies
```

---

## Cara Penggunaan

### 1. Buka di Google Colab

Klik badge "Open In Colab" di atas atau upload notebook secara manual.

### 2. Jalankan Cell 1 - Mount Google Drive (Optional)

```
Toggle: Mount Drive ON/OFF
```

- **ON**: Mount Google Drive ke `/content/drive`
- **OFF**: Skip mounting (file tetap tersimpan di `/content/download`)

### 3. Jalankan Cell 2 - Instalasi & Setup

Cell ini akan menginstall:
- System dependencies (aria2, wget, curl, megatools)
- Python packages (requests, tqdm, beautifulsoup4)
- Konfigurasi Aria2 dengan RPC
- Setup direktori download

**Status**: Tunggu hingga muncul pesan "Installation Complete!"

### 4. Jalankan Cell 3 - Download Manager

**Pilih Engine:**
| Engine | Kelebihan | Kekurangan | Best For |
|--------|-----------|------------|----------|
| Aria2 | Multi-threaded, Resume, RPC | Butuh konfigurasi | File besar, server lambat |
| Wget | Simpel, Stabil | Single connection | File kecil, link langsung |
| cURL | Versatile, Protocol rich | Single connection | API downloads, protocol khusus |
| Mega Auto | No quota, Resume | Mega only, Slower | File Mega.nz |

**Input URL:**
- Masukkan 1-5 URL download
- Pilih mode: Serentak atau Bergilir
- Atur Aria2: Koneksi (1-32) dan Split (1-32)

**Klik**: "Start Download"

### 5. Jalankan Cell 4 - Transfer ke Drive

```
Source: /content/download
Destination: /content/drive/MyDrive/YourFolder
Mode: Move atau Copy
```

**Klik**: "Start Transfer"

---

## Penjelasan Engine

### Aria2 (Recommended)

Aria2 adalah download utility yang mendukung multi-protocol dan multi-source download.

**Konfigurasi Optimal:**
```
max-connection-per-server: 16 (default)
split: 16 (default)
min-split-size: 10M
continue: true (auto-resume)
```

**Kapan Menggunakan:**
- File besar (>100MB)
- Server dengan bandwidth terbatas
- Butuh resume capability
- Download multiple files simultaneously

### Wget

GNU Wget adalah utility non-interactive untuk download file dari web.

**Fitur:**
- Recursive download
- Resume support
- Mirror websites
- FTP/HTTP/HTTPS support

**Kapan Menggunakan:**
- Download sederhana
- File kecil sampai medium
- Link langsung (direct link)

### cURL

cURL adalah tool command line untuk transfer data dengan URL syntax.

**Fitur:**
- Support 20+ protocols
- Cookie handling
- SSL certificates
- Proxy support

**Kapan Menggunakan:**
- API endpoints
- Authentication required
- Custom headers needed

### Mega Auto

Specialized downloader untuk Mega.nz dengan teknik bypass quota.

**Fitur:**
- Bypass download quota
- Resume support
- Auto-extract (jika diimplementasikan)

**Kapan Menggunakan:**
- Hanya untuk file Mega.nz
- File besar di Mega
- Terkena limit quota Mega

---

## Screenshot UI

### Cell 1 - Mount Drive
```
[Toggle: Mount Drive: ON/OFF]

Default Download Location:
/content/download (temporary, cleared on session end)

Google Drive Location:
/content/drive/MyDrive (persistent storage)
```

### Cell 2 - Installation
```
Step 2: Engine Installation
Installing and configuring download engines

[Step 1/6] System Dependencies ✅
[Step 2/6] Download Tools ✅
[Step 3/6] Python Packages ✅
[Step 4/6] Mega Tools ✅
[Step 5/6] Aria2 Configuration ✅
[Step 6/6] Directory Setup ✅

Installation Complete!
```

### Cell 3 - Download Manager
```
Download Manager
Multi-engine download with real-time progress tracking

[Engine Dropdown] ⚡ Aria2 (Recommended)

[Engine Info Card]
Aria2
Ultra-fast multi-threaded downloader
Pros: Multi-threaded, Resume support, RPC control
Cons: Requires configuration

[URL Inputs x5]
[Mode: Serentak / Bergilir]
[Aria2 Sliders: Koneksi 16, Split 16]

[Start Download Button]

[Progress Bar] ████████████ 100%
[Stats] Total: 5 | Success: 5 | Failed: 0
```

### Cell 4 - Transfer
```
Transfer to Google Drive
Move or copy downloaded files to persistent storage

Source Files (5 items)
Files: 5 | Total Size: 1.25 GB
/content/download

[File List]
📄 file1.zip (250 MB)
📄 file2.mp4 (500 MB)
...

Destination: /content/drive/MyDrive/Downloads
Mode: [Move (delete from source)]

[Start Transfer Button]

Transfer Complete!
Transferred: 5 | Failed: 0
```

---

## Requirements

### System Requirements
- Google Colab environment
- Python 3.8+
- Linux-based system (Colab default)

### Python Dependencies
```
requests>=2.28.0
tqdm>=4.64.0
beautifulsoup4>=4.11.0
lxml>=4.9.0
mega.py>=1.0.8
urllib3>=1.26.0
ipywidgets>=7.7.0
```

### System Packages
```
aria2
wget
curl
pv
rsync
p7zip-full
megatools
```

---

## Troubleshooting

### Aria2 RPC tidak berjalan
```bash
# Restart Aria2 daemon
!aria2c --conf-path=~/.aria2/aria2.conf --daemon
```

### Mega download gagal
```bash
# Cek megatools installation
!which megadl

# Jika tidak ada, install manual
!apt-get install -y megatools
```

### Drive tidak ter-mount
```python
# Remount Drive
from google.colab import drive
drive.mount('/content/drive', force_remount=True)
```

### Download stuck/pending
- Cek koneksi internet
- Coba ganti engine (Wget lebih stabil untuk server lambat)
- Kurangi jumlah koneksi Aria2

---

## Advanced Configuration

### Custom Aria2 Config

Edit `~/.aria2/aria2.conf`:
```ini
# Performance
max-concurrent-downloads=10
max-connection-per-server=32
split=32
min-split-size=5M

# Network
timeout=120
retry-wait=10
max-tries=20

# Disk
disk-cache=128M
file-allocation=trunc
```

### Custom Download Directory

```python
import os
os.makedirs('/content/my_custom_folder', exist_ok=True)
# Update config untuk menggunakan folder ini
```

---

## Warning Penggunaan

1. **Bandwidth Usage**: Download besar dapat menghabiskan bandwidth Colab. Monitor penggunaan.

2. **Session Timeout**: Colab session dapat timeout setelah periode idle. Pastikan download selesai sebelum timeout.

3. **Storage Limit**: Storage Colab gratis terbatas (~70GB). Transfer ke Drive secara berkala.

4. **Terms of Service**: Gunakan tool ini sesuai Terms of Service Google Colab dan sumber download.

5. **Copyright**: Jangan download konten ber-copyright tanpa izin. Tool ini untuk keperluan legal.

6. **Mega Quota**: Bypass quota Mega mungkin melanggar Terms of Service Mega.nz. Gunakan dengan risiko sendiri.

---

## Contributing

Kontribusi selalu diterima! Untuk berkontribusi:

1. Fork repository ini
2. Buat branch feature (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buka Pull Request

---

## License

Distributed under the MIT License. See `LICENSE` untuk informasi lebih lanjut.

---

## Acknowledgments

- [Aria2](https://aria2.github.io/) - Ultra-fast download utility
- [MegaTools](https://megatools.megous.com/) - Mega.nz command line tools
- [Google Colab](https://colab.research.google.com/) - Free cloud Jupyter environment

---

## Changelog

### v2.0.0 (2024)
- Complete UI overhaul with modern design
- Added real-time progress tracking
- Enhanced Mega.nz integration
- Added transfer to Drive functionality
- Improved error handling

### v1.0.0 (2023)
- Initial release
- Basic multi-engine support
- Simple progress display

---

**Dibuat dengan ❤️ untuk komunitas downloader Indonesia**

*Jika tool ini bermanfaat, berikan ⭐ di repository ini!*
