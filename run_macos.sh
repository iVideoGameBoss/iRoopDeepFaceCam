#!/bin/bash
# ==============================================
#  iRoopDeepFaceCam - macOS Run Script
# ==============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
if [[ -d "venv" ]]; then
    source venv/bin/activate
else
    echo "[ERROR] Virtual environment not found."
    echo "Run setup_macos.sh first: bash setup_macos.sh"
    exit 1
fi

# Check for required model
if [[ ! -f "models/inswapper_128_fp16.onnx" ]]; then
    echo "[WARNING] Model file not found: models/inswapper_128_fp16.onnx"
    echo "Download it from: https://huggingface.co/ivideogameboss/iroopdeepfacecam"
    echo ""
fi

# Check FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "[WARNING] FFmpeg is not installed. Video processing will not work."
    echo "Install with: brew install ffmpeg"
    echo ""
fi

# Detect Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "Detected Apple Silicon - CoreML acceleration available"
    echo "  Tip: Use --execution-provider coreml for GPU acceleration"
    echo ""
fi

# Run the application with any passed arguments
echo "Starting iRoopDeepFaceCam..."
python run.py "$@"
