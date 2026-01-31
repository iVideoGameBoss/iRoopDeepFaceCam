# iRoopDeepFaceCam - Setup & Build Documentation

## Project Overview

**iRoopDeepFaceCam** is a real-time face-swapping application built with Python, supporting live webcam, video, and image processing. Features include multi-face tracking (up to 10 faces), mouth masking, head rotation compensation, and GFPGAN face enhancement.

- **Version:** 1.3.0 (Portable Edition)
- **UI Framework:** CustomTkinter
- **AI Models:** InsightFace, ONNX Runtime, GFPGAN
- **Repo:** https://github.com/Nene020911/iRoopDeepFaceCam
- **Branch:** `claude/create-windows-app-CU9xo`

---

## Repository Structure

```
iRoopDeepFaceCam/
├── run.py                          # Main entry point
├── modules/
│   ├── core.py                     # App initialization & arg parsing
│   ├── ui.py                       # CustomTkinter GUI (1,714 lines)
│   ├── ui.json                     # UI theme config
│   ├── globals.py                  # Global state & settings
│   ├── face_analyser.py            # InsightFace integration
│   ├── capturer.py                 # Video/frame capture
│   ├── predicter.py                # NSFW prediction
│   ├── server.py                   # Flask server for Firefox extension
│   ├── utilities.py                # FFmpeg, file helpers
│   └── processors/frame/
│       ├── face_swapper.py         # Core face swap engine (1,932 lines)
│       └── face_enhancer.py        # GFPGAN enhancement
├── models/                         # AI model files (not in git)
│   ├── inswapper_128_fp16.onnx     # Required - face swap model
│   └── GFPGANv1.4.pth             # Optional - face enhancement
├── FireFox_Face_Swap_Ext/          # Browser extension
├── requirements.txt                # Python dependencies
├── setup_macos.sh                  # macOS auto-setup script
├── run_macos.sh                    # macOS launcher script
├── build_exe.bat                   # Windows EXE builder (one-click)
├── build_exe.py                    # Python build script
├── iRoopDeepFaceCam.spec           # PyInstaller spec file
├── BUILDING.md                     # Windows build instructions
└── .gitattributes                  # Force LF endings for .sh files
```

---

## macOS Installation

### Prerequisites
- macOS 15.7+ (Sequoia)
- Homebrew
- Python 3.9+ (pyenv or Homebrew)

### Steps

```bash
# 1. Clone and switch to branch
git clone https://github.com/Nene020911/iRoopDeepFaceCam.git
cd iRoopDeepFaceCam
git checkout claude/create-windows-app-CU9xo

# 2. Run automated setup
bash setup_macos.sh

# 3. Download model file
# Place inswapper_128_fp16.onnx in the models/ folder
# Download from: https://huggingface.co/ivideogameboss/iroopdeepfacecam

# 4. Launch the app
./run_macos.sh
```

### What setup_macos.sh does
1. Checks/installs Homebrew
2. Installs FFmpeg via Homebrew
3. Detects Python 3.9+ (installs 3.10 if needed)
4. Checks tkinter is available
5. Creates Python virtual environment (`venv/`)
6. Installs all Python dependencies:
   - NumPy, OpenCV, Pillow, CustomTkinter
   - PyTorch 2.0.1 (macOS, no CUDA)
   - ONNX Runtime (Intel) or ONNX Runtime Silicon (Apple Silicon)
   - TensorFlow 2.13.0rc1
   - InsightFace 0.7.3
   - GFPGAN 1.3.8 (with pre-built llvmlite/numba wheels)
   - Flask, Selenium, yt-dlp
7. Pins numpy < 2.0 (onnxruntime compatibility)
8. Verifies all imports

### macOS Run Commands

```bash
# Default (CPU)
./run_macos.sh

# Apple Silicon GPU (CoreML)
python run.py --execution-provider coreml

# With arguments
python run.py --execution-provider cpu --execution-threads 4
```

### Troubleshooting - macOS

| Issue | Fix |
|-------|-----|
| `llvmlite` build fails | Script uses pre-built wheels (`llvmlite==0.43.0`, `numba==0.60.0`) |
| numpy version conflict | Script pins `numpy<2,>=1.23.5` after all installs |
| CRLF line ending errors | `.gitattributes` forces LF for `.sh` files |
| `macOS 15 (1507) required` | Update macOS to 15.7+ via System Settings |
| Model file not found | Download `inswapper_128_fp16.onnx` to `models/` |

---

## Windows EXE Build

### Prerequisites
- Python 3.9+
- pip
- CUDA Toolkit 11.8 (optional, for GPU)

### Quick Build

```batch
:: Clone and switch to branch
git clone https://github.com/Nene020911/iRoopDeepFaceCam.git
cd iRoopDeepFaceCam
git checkout claude/create-windows-app-CU9xo

:: One-click build
build_exe.bat
```

### Manual Build

```batch
pip install -r requirements.txt
pip install pyinstaller
pyinstaller iRoopDeepFaceCam.spec --noconfirm
```

### Build Script Options (build_exe.py)

```bash
python build_exe.py              # Standard build using spec file
python build_exe.py --clean      # Clean previous builds first
python build_exe.py --onefile    # Single .exe (slower startup)
python build_exe.py --noconsole  # Hide console window (release)
python build_exe.py --no-spec   # Build without spec file
```

### Output Structure

```
dist/iRoopDeepFaceCam/
├── iRoopDeepFaceCam.exe          # Main executable
├── Launch_iRoopDeepFaceCam.bat   # Quick launcher
├── Launch_GPU_CUDA.bat           # GPU mode launcher
├── models/                       # Place model files here
├── FireFox_Face_Swap_Ext/        # Browser extension
└── _internal/                    # Bundled dependencies
```

### Post-Build Steps
1. Copy `inswapper_128_fp16.onnx` to `dist/iRoopDeepFaceCam/models/`
2. (Optional) Copy `GFPGANv1.4.pth` for face enhancement
3. Install FFmpeg and add to system PATH

### Windows Run Commands

```batch
:: Default (CPU)
iRoopDeepFaceCam.exe

:: GPU with CUDA
iRoopDeepFaceCam.exe --execution-provider cuda --execution-threads 5
```

---

## Key Technical Changes Made

### PyInstaller Frozen App Support

**modules/globals.py** - Detects if running as compiled .exe:
```python
if getattr(sys, 'frozen', False):
    ROOT_DIR = os.path.dirname(sys.executable)    # exe directory
    BUNDLE_DIR = sys._MEIPASS                      # temp extraction
else:
    ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
    BUNDLE_DIR = ROOT_DIR
```

**modules/utilities.py** - `resolve_relative_path()` checks bundle first:
```python
if getattr(sys, 'frozen', False):
    bundled = os.path.join(sys._MEIPASS, 'modules', path)
    if os.path.exists(bundled):
        return bundled
    return os.path.join(os.path.dirname(sys.executable), 'modules', path)
return os.path.join(os.path.dirname(__file__), path)
```

### requirements.txt Change
- `numpy==1.23.5` → `numpy>=1.23.5,<2`
- Prevents onnxruntime ABI crash from numpy 2.x

---

## Model Files Required

| Model | Required | Size | Source |
|-------|----------|------|--------|
| `inswapper_128_fp16.onnx` | Yes | ~300 MB | https://huggingface.co/ivideogameboss/iroopdeepfacecam |
| `GFPGANv1.4.pth` | No (enhancement) | ~350 MB | https://github.com/TencentARC/GFPGAN/releases/download/v1.3.4/GFPGANv1.4.pth |
| `buffalo_l` (InsightFace) | Auto-downloaded | ~300 MB | Downloads to `~/.insightface/models/` on first run |

---

## Hotkeys (App & Preview Window)

| Key | Action |
|-----|--------|
| `a` | Toggle Auto Face Tracking |
| `t` | Reset Face Tracking Data |
| `m` | Toggle Mouth Mask (Global) |
| `1`-`9`, `0` | Toggle Mouth Mask for Faces 1-10 |

---

## Execution Providers

| Provider | Platform | Command |
|----------|----------|---------|
| CPU | All | `--execution-provider cpu` |
| CUDA | Windows/Linux (NVIDIA) | `--execution-provider cuda` |
| CoreML | macOS (Apple Silicon) | `--execution-provider coreml` |
| DirectML | Windows (AMD/Intel) | `--execution-provider directml` |
| OpenVINO | Intel | `--execution-provider openvino` |

---

## Git Branch & Commits

**Branch:** `claude/create-windows-app-CU9xo`

| Commit | Description |
|--------|-------------|
| `585d310` | Add Windows executable build system using PyInstaller |
| `3f112c4` | Add macOS setup/run scripts and fix numpy version constraint |
| `da4e9ba` | Fix CRLF line endings in shell scripts for macOS compatibility |
| `3ba3a81` | Fix llvmlite build failure on macOS by installing LLVM via Homebrew |
| `213ba46` | Fix llvmlite build by using pre-built wheels instead of LLVM |
