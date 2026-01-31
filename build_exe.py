#!/usr/bin/env python3
"""
Build script for creating iRoopDeepFaceCam Windows executable.

This script automates the PyInstaller build process and prepares
the distribution folder with all required files.

Usage:
    python build_exe.py
    python build_exe.py --clean        # Clean previous builds first
    python build_exe.py --onefile       # Build single-file exe (larger startup time)
    python build_exe.py --noconsole     # Hide console window (release mode)
"""

import os
import sys
import shutil
import argparse
import subprocess


def get_project_root():
    """Get the project root directory."""
    return os.path.dirname(os.path.abspath(__file__))


def check_prerequisites():
    """Check that required tools are installed."""
    print("[BUILD] Checking prerequisites...")

    # Check Python version
    if sys.version_info < (3, 9):
        print("[ERROR] Python 3.9 or higher is required.")
        return False

    # Check PyInstaller
    try:
        import PyInstaller
        print(f"  PyInstaller version: {PyInstaller.__version__}")
    except ImportError:
        print("[ERROR] PyInstaller is not installed. Install it with:")
        print("  pip install pyinstaller")
        return False

    # Check key dependencies
    required = ['customtkinter', 'cv2', 'insightface', 'onnxruntime', 'torch', 'gfpgan']
    for pkg in required:
        try:
            __import__(pkg)
            print(f"  {pkg}: OK")
        except ImportError:
            print(f"  [WARNING] {pkg} not found - install from requirements.txt")

    return True


def clean_build(project_root):
    """Remove previous build artifacts."""
    print("[BUILD] Cleaning previous build artifacts...")
    dirs_to_clean = ['build', 'dist']
    for d in dirs_to_clean:
        path = os.path.join(project_root, d)
        if os.path.exists(path):
            print(f"  Removing {path}")
            shutil.rmtree(path)


def run_pyinstaller(project_root, use_spec=True, onefile=False, noconsole=False):
    """Run PyInstaller to create the executable."""
    print("[BUILD] Running PyInstaller...")

    if use_spec:
        spec_file = os.path.join(project_root, 'iRoopDeepFaceCam.spec')
        if not os.path.exists(spec_file):
            print(f"[ERROR] Spec file not found: {spec_file}")
            return False
        cmd = [sys.executable, '-m', 'PyInstaller', spec_file, '--noconfirm']
    else:
        # Build from command line arguments (alternative to spec file)
        cmd = [
            sys.executable, '-m', 'PyInstaller',
            '--name', 'iRoopDeepFaceCam',
            '--noconfirm',
            '--clean',
        ]

        if onefile:
            cmd.append('--onefile')
        else:
            cmd.append('--onedir')

        if noconsole:
            cmd.append('--noconsole')
        else:
            cmd.append('--console')

        # Add data files
        cmd.extend(['--add-data', f'modules{os.sep}ui.json{os.pathsep}modules'])
        cmd.extend(['--add-data', f'modules{os.sep}__init__.py{os.pathsep}modules'])
        cmd.extend(['--add-data', f'FireFox_Face_Swap_Ext{os.pathsep}FireFox_Face_Swap_Ext'])

        # Add hidden imports
        hidden = [
            'modules.core', 'modules.globals', 'modules.metadata',
            'modules.ui', 'modules.face_analyser', 'modules.capturer',
            'modules.predicter', 'modules.server', 'modules.utilities',
            'modules.processors.frame.core',
            'modules.processors.frame.face_swapper',
            'modules.processors.frame.face_enhancer',
            'customtkinter', 'cv2', 'cv2_enumerate_cameras',
            'insightface', 'onnxruntime', 'gfpgan', 'opennsfw2',
            'flask', 'flask_cors', 'waitress',
            'PIL', 'PIL.Image', 'PIL.ImageOps', 'PIL.ImageTk',
            'google.protobuf', 'tqdm', 'psutil', 'numpy',
        ]
        for h in hidden:
            cmd.extend(['--hidden-import', h])

        # Collect all submodules for complex packages
        cmd.extend(['--collect-submodules', 'insightface'])
        cmd.extend(['--collect-submodules', 'onnxruntime'])
        cmd.extend(['--collect-submodules', 'gfpgan'])
        cmd.extend(['--collect-submodules', 'opennsfw2'])
        cmd.extend(['--collect-data', 'customtkinter'])
        cmd.extend(['--collect-data', 'onnxruntime'])

        cmd.append('run.py')

    print(f"  Command: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=project_root)

    if result.returncode != 0:
        print("[ERROR] PyInstaller build failed.")
        return False

    print("[BUILD] PyInstaller build completed successfully.")
    return True


def prepare_distribution(project_root):
    """Copy additional files needed alongside the executable."""
    dist_dir = os.path.join(project_root, 'dist', 'iRoopDeepFaceCam')

    if not os.path.exists(dist_dir):
        print("[ERROR] Distribution directory not found. Build may have failed.")
        return False

    print("[BUILD] Preparing distribution folder...")

    # Create models directory
    models_dir = os.path.join(dist_dir, 'models')
    os.makedirs(models_dir, exist_ok=True)

    # Copy models if they exist locally
    src_models_dir = os.path.join(project_root, 'models')
    if os.path.exists(src_models_dir):
        for f in os.listdir(src_models_dir):
            src = os.path.join(src_models_dir, f)
            dst = os.path.join(models_dir, f)
            if os.path.isfile(src) and not f.startswith('.'):
                if not os.path.exists(dst):
                    print(f"  Copying model: {f}")
                    shutil.copy2(src, dst)

    # Create instructions file in models dir
    instructions_path = os.path.join(models_dir, 'instructions.txt')
    with open(instructions_path, 'w') as f:
        f.write("Place the following model files in this directory:\n\n")
        f.write("1. inswapper_128_fp16.onnx\n")
        f.write("   Download from: https://huggingface.co/ivideogameboss/iroopdeepfacecam\n\n")
        f.write("2. GFPGANv1.4.pth (optional, for face enhancement)\n")
        f.write("   Download from: https://github.com/TencentARC/GFPGAN/releases/download/v1.3.4/GFPGANv1.4.pth\n")

    # Copy Firefox extension
    ext_src = os.path.join(project_root, 'FireFox_Face_Swap_Ext')
    ext_dst = os.path.join(dist_dir, 'FireFox_Face_Swap_Ext')
    if os.path.exists(ext_src) and not os.path.exists(ext_dst):
        print("  Copying Firefox extension...")
        shutil.copytree(ext_src, ext_dst)

    # Create a launcher batch file
    launcher_path = os.path.join(dist_dir, 'Launch_iRoopDeepFaceCam.bat')
    with open(launcher_path, 'w') as f:
        f.write('@echo off\n')
        f.write('echo Starting iRoopDeepFaceCam...\n')
        f.write('echo.\n')
        f.write('echo Make sure you have:\n')
        f.write('echo   - FFmpeg installed and in your PATH\n')
        f.write('echo   - Model files in the models\\ folder\n')
        f.write('echo.\n')
        f.write('start "" "%~dp0iRoopDeepFaceCam.exe"\n')

    # Create GPU launcher batch file
    gpu_launcher_path = os.path.join(dist_dir, 'Launch_GPU_CUDA.bat')
    with open(gpu_launcher_path, 'w') as f:
        f.write('@echo off\n')
        f.write('echo Starting iRoopDeepFaceCam with CUDA GPU...\n')
        f.write('"%~dp0iRoopDeepFaceCam.exe" --execution-provider cuda --execution-threads 5\n')
        f.write('pause\n')

    print(f"[BUILD] Distribution ready at: {dist_dir}")
    print()
    print("=== NEXT STEPS ===")
    print(f"1. Copy your model files to: {models_dir}")
    print("   - inswapper_128_fp16.onnx (required)")
    print("   - GFPGANv1.4.pth (optional)")
    print("2. Ensure FFmpeg is installed and available in PATH")
    print("3. Run iRoopDeepFaceCam.exe or use the launcher .bat files")
    print()

    return True


def main():
    parser = argparse.ArgumentParser(description='Build iRoopDeepFaceCam Windows executable')
    parser.add_argument('--clean', action='store_true', help='Clean previous builds first')
    parser.add_argument('--onefile', action='store_true', help='Build single-file exe')
    parser.add_argument('--noconsole', action='store_true', help='Hide console window')
    parser.add_argument('--no-spec', action='store_true', help='Build without spec file (use CLI args)')
    args = parser.parse_args()

    project_root = get_project_root()
    print(f"[BUILD] Project root: {project_root}")
    print(f"[BUILD] Python: {sys.executable} ({sys.version})")
    print()

    if not check_prerequisites():
        sys.exit(1)

    if args.clean:
        clean_build(project_root)

    use_spec = not args.no_spec
    if not run_pyinstaller(project_root, use_spec=use_spec,
                           onefile=args.onefile, noconsole=args.noconsole):
        sys.exit(1)

    if not args.onefile:
        if not prepare_distribution(project_root):
            sys.exit(1)

    print("[BUILD] Build completed successfully!")


if __name__ == '__main__':
    main()
