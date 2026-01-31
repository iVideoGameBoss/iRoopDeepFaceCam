# Building iRoopDeepFaceCam as a Windows Executable

This guide explains how to build iRoopDeepFaceCam into a standalone `.exe` application for Windows.

## Prerequisites

1. **Python 3.9+** installed and added to PATH
2. **pip** package manager
3. **Git** (to clone the repository)
4. **FFmpeg** installed and added to system PATH
5. **CUDA Toolkit 11.8** (optional, for GPU support)

## Quick Build (Windows)

The easiest way to build is using the batch script:

```batch
build_exe.bat
```

This will:
- Check prerequisites
- Install PyInstaller
- Install project dependencies
- Build the executable
- Prepare the distribution folder

## Manual Build

### Step 1: Install Dependencies

```bash
pip install -r requirements.txt
pip install pyinstaller
```

### Step 2: Build with PyInstaller

**Using the spec file (recommended):**

```bash
pyinstaller iRoopDeepFaceCam.spec --noconfirm
```

**Using the build script:**

```bash
python build_exe.py
```

Build script options:
- `--clean` - Remove previous builds first
- `--onefile` - Build a single .exe file (slower startup)
- `--noconsole` - Hide the console window (release mode)
- `--no-spec` - Build without spec file, use CLI arguments

### Step 3: Add Model Files

After building, copy your model files to the `dist/iRoopDeepFaceCam/models/` folder:

1. **inswapper_128_fp16.onnx** (required)
   - Download from: https://huggingface.co/ivideogameboss/iroopdeepfacecam

2. **GFPGANv1.4.pth** (optional, for face enhancement)
   - Download from: https://github.com/TencentARC/GFPGAN/releases/download/v1.3.4/GFPGANv1.4.pth

### Step 4: Install FFmpeg

FFmpeg must be installed separately and available in your system PATH:
- Download from: https://ffmpeg.org/download.html
- Or install via Chocolatey: `choco install ffmpeg`

## Output Structure

After a successful build, you'll find:

```
dist/
  iRoopDeepFaceCam/
    iRoopDeepFaceCam.exe          # Main executable
    Launch_iRoopDeepFaceCam.bat   # Quick launcher
    Launch_GPU_CUDA.bat           # GPU mode launcher
    models/                       # Place model files here
      instructions.txt
    FireFox_Face_Swap_Ext/        # Browser extension
    _internal/                    # PyInstaller bundled dependencies
    ... (DLL files, etc.)
```

## Running the Executable

**Default (CPU mode):**
```
iRoopDeepFaceCam.exe
```

**GPU mode (NVIDIA CUDA):**
```
iRoopDeepFaceCam.exe --execution-provider cuda --execution-threads 5
```

Or use the provided launcher batch files.

## Troubleshooting

### Build fails with missing module errors
Make sure all dependencies are installed:
```bash
pip install -r requirements.txt
```

### "ffmpeg is not installed" error at runtime
Install FFmpeg and add it to your system PATH.

### Models not found at runtime
Place model files in the `models/` folder next to the executable.

### CUDA/GPU not detected
- Ensure NVIDIA drivers are up to date
- Install CUDA Toolkit 11.8
- Verify with: `python -c "import torch; print(torch.cuda.is_available())"`

### Application window doesn't appear
Try running from command prompt to see error messages:
```batch
cd dist\iRoopDeepFaceCam
iRoopDeepFaceCam.exe
```

### Large executable size
The executable is large (~2-4 GB) because it bundles PyTorch, TensorFlow, ONNX Runtime, and other ML libraries. This is expected for a deep learning application.
