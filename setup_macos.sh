#!/bin/bash
# ==============================================
#  iRoopDeepFaceCam - macOS Setup Script
#  Supports both Intel and Apple Silicon (M1/M2)
# ==============================================
set -e

echo "============================================"
echo "  iRoopDeepFaceCam - macOS Setup"
echo "  Version 1.3.0"
echo "============================================"
echo ""

# --- Check macOS ---
if [[ "$(uname)" != "Darwin" ]]; then
    echo "[WARNING] This script is designed for macOS."
    echo "  Detected: $(uname -s)"
    echo "  Continuing anyway..."
    echo ""
fi

# --- Detect Architecture ---
ARCH=$(uname -m)
echo "[INFO] Architecture: $ARCH"
if [[ "$ARCH" == "arm64" ]]; then
    echo "  Detected Apple Silicon (M1/M2/M3)"
else
    echo "  Detected Intel Mac"
fi
echo ""

# --- Check Homebrew ---
echo "[STEP 1] Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "  Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "  Homebrew: OK"
fi
echo ""

# --- Install system dependencies ---
echo "[STEP 2] Installing system dependencies..."

# FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "  Installing FFmpeg..."
    brew install ffmpeg
else
    echo "  FFmpeg: OK ($(ffmpeg -version 2>&1 | head -1))"
fi

# Python (if not present or too old)
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    PY_MAJ=$(echo "$PY_VER" | cut -d. -f1)
    PY_MIN=$(echo "$PY_VER" | cut -d. -f2)
    if [[ "$PY_MAJ" -ge 3 && "$PY_MIN" -ge 9 ]]; then
        echo "  Python: OK ($PY_VER)"
        PYTHON_CMD="python3"
    fi
fi

if [[ -z "$PYTHON_CMD" ]]; then
    echo "  Installing Python 3.10..."
    brew install python@3.10
    PYTHON_CMD="python3.10"
fi

# tkinter (required for CustomTkinter GUI)
echo "  Checking tkinter..."
if ! $PYTHON_CMD -c "import tkinter" 2>/dev/null; then
    echo "  Installing python-tk..."
    brew install python-tk@3.10
else
    echo "  tkinter: OK"
fi
echo ""

# --- Create virtual environment ---
echo "[STEP 3] Creating virtual environment..."
VENV_DIR="venv"
if [[ -d "$VENV_DIR" ]]; then
    echo "  Virtual environment already exists at ./$VENV_DIR"
    echo "  To recreate, delete it first: rm -rf $VENV_DIR"
else
    $PYTHON_CMD -m venv "$VENV_DIR"
    echo "  Created virtual environment at ./$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"
echo "  Activated virtual environment"
echo "  Python: $(python --version)"
echo "  pip: $(pip --version)"
echo ""

# --- Upgrade pip ---
echo "[STEP 4] Upgrading pip..."
pip install --upgrade pip setuptools wheel
echo ""

# --- Install dependencies ---
echo "[STEP 5] Installing Python dependencies..."
echo "  This may take several minutes..."
echo ""

# Install numpy first (dependency for many packages)
pip install numpy==1.23.5

# Install core packages
pip install opencv-python==4.8.1.78
pip install Pillow==9.5.0
pip install customtkinter==5.2.2
pip install tk==0.1.0
pip install psutil==5.9.8
pip install tqdm==4.66.4
pip install protobuf==4.23.2
pip install "sympy>=1.7"

# Install PyTorch (macOS version - no CUDA)
echo ""
echo "  Installing PyTorch (macOS)..."
pip install torch==2.0.1 torchvision==0.15.2

# Install ONNX and runtime
echo ""
echo "  Installing ONNX Runtime..."
pip install onnx==1.16.0
if [[ "$ARCH" == "arm64" ]]; then
    echo "  Installing onnxruntime-silicon for Apple Silicon..."
    pip install onnxruntime-silicon==1.16.3
else
    echo "  Installing onnxruntime for Intel..."
    pip install onnxruntime==1.18.0
fi

# Install TensorFlow (macOS version)
echo ""
echo "  Installing TensorFlow..."
pip install tensorflow==2.13.0rc1

# Install InsightFace
echo ""
echo "  Installing InsightFace..."
pip install insightface==0.7.3

# Install GFPGAN
# Pin llvmlite/numba to versions with pre-built macOS wheels
# (avoids needing LLVM installed to compile from source)
echo ""
echo "  Installing GFPGAN..."
pip install --only-binary=:all: llvmlite==0.43.0 numba==0.60.0
pip install gfpgan==1.3.8

# Install NSFW filter
pip install opennsfw2==0.10.2

# Install camera enumeration
pip install cv2_enumerate_cameras==1.1.15

# Install web/server dependencies
echo ""
echo "  Installing web server dependencies..."
pip install flask==3.0.0 flask-cors==4.0.0 waitress==2.1.2
pip install selenium==4.15.2 webdriver-manager==4.0.1
pip install requests==2.31.0
pip install yt-dlp==2023.11.16

# --- Pin numpy to 1.x (onnxruntime 1.18 is compiled against numpy 1.x) ---
echo ""
echo "  Pinning numpy < 2.0 (required for onnxruntime compatibility)..."
pip install "numpy<2,>=1.23.5"

echo ""
echo ""

# --- Download models ---
echo "[STEP 6] Checking model files..."
MODELS_DIR="models"
mkdir -p "$MODELS_DIR"

if [[ ! -f "$MODELS_DIR/inswapper_128_fp16.onnx" ]]; then
    echo ""
    echo "  [ACTION REQUIRED] Model file not found!"
    echo "  Please download 'inswapper_128_fp16.onnx' and place it in the models/ folder."
    echo "  Download from: https://huggingface.co/ivideogameboss/iroopdeepfacecam"
    echo ""
else
    echo "  inswapper_128_fp16.onnx: OK"
fi

if [[ ! -f "$MODELS_DIR/GFPGANv1.4.pth" ]]; then
    echo "  GFPGANv1.4.pth: Not found (optional - for face enhancement)"
else
    echo "  GFPGANv1.4.pth: OK"
fi
echo ""

# --- Verify installation ---
echo "[STEP 7] Verifying installation..."
echo ""
python -c "
import sys
print(f'Python: {sys.version}')
print()

modules = {
    'numpy': 'numpy',
    'cv2': 'OpenCV',
    'PIL': 'Pillow',
    'customtkinter': 'CustomTkinter',
    'torch': 'PyTorch',
    'onnxruntime': 'ONNX Runtime',
    'insightface': 'InsightFace',
    'flask': 'Flask',
    'psutil': 'psutil',
    'tqdm': 'tqdm',
}

all_ok = True
for mod, name in modules.items():
    try:
        __import__(mod)
        print(f'  {name}: OK')
    except ImportError as e:
        print(f'  {name}: FAILED ({e})')
        all_ok = False

print()
if all_ok:
    print('All core dependencies installed successfully!')
else:
    print('Some dependencies failed. Check errors above.')
"

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "To run iRoopDeepFaceCam:"
echo ""
echo "  1. Activate the virtual environment:"
echo "     source venv/bin/activate"
echo ""
echo "  2. Run the application:"
echo "     python run.py"
echo ""
echo "  Or use the run script:"
echo "     ./run_macos.sh"
echo ""
echo "  For Apple Silicon GPU (CoreML):"
echo "     python run.py --execution-provider coreml"
echo ""
