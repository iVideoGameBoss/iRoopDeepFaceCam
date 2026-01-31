@echo off
title iRoopDeepFaceCam - Windows EXE Builder
echo ============================================
echo   iRoopDeepFaceCam Windows EXE Builder
echo   Version 1.3.0
echo ============================================
echo.

:: Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python 3.9+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

:: Check pip
pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] pip is not available.
    pause
    exit /b 1
)

:: Install PyInstaller if not present
echo [STEP 1] Checking PyInstaller...
pip show pyinstaller >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing PyInstaller...
    pip install pyinstaller
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install PyInstaller.
        pause
        exit /b 1
    )
)
echo   PyInstaller: OK
echo.

:: Install project dependencies
echo [STEP 2] Installing project dependencies...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [WARNING] Some dependencies may have failed to install.
    echo The build may still succeed if core packages are available.
    echo.
)
echo.

:: Clean previous builds
echo [STEP 3] Cleaning previous builds...
if exist "build" rmdir /s /q "build"
if exist "dist" rmdir /s /q "dist"
echo   Cleaned.
echo.

:: Run PyInstaller with spec file
echo [STEP 4] Building executable with PyInstaller...
echo This may take several minutes...
echo.
pyinstaller iRoopDeepFaceCam.spec --noconfirm
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed! Check the output above for errors.
    echo.
    echo Common fixes:
    echo   - Make sure all dependencies are installed: pip install -r requirements.txt
    echo   - Try running: python build_exe.py --clean --no-spec
    pause
    exit /b 1
)
echo.

:: Prepare distribution
echo [STEP 5] Preparing distribution folder...

:: Create models directory
if not exist "dist\iRoopDeepFaceCam\models" mkdir "dist\iRoopDeepFaceCam\models"

:: Copy models if they exist
if exist "models\inswapper_128_fp16.onnx" (
    echo   Copying inswapper_128_fp16.onnx...
    copy "models\inswapper_128_fp16.onnx" "dist\iRoopDeepFaceCam\models\" >nul
)
if exist "models\GFPGANv1.4.pth" (
    echo   Copying GFPGANv1.4.pth...
    copy "models\GFPGANv1.4.pth" "dist\iRoopDeepFaceCam\models\" >nul
)

:: Create launcher scripts in dist
echo @echo off > "dist\iRoopDeepFaceCam\Launch_iRoopDeepFaceCam.bat"
echo echo Starting iRoopDeepFaceCam... >> "dist\iRoopDeepFaceCam\Launch_iRoopDeepFaceCam.bat"
echo start "" "%%~dp0iRoopDeepFaceCam.exe" >> "dist\iRoopDeepFaceCam\Launch_iRoopDeepFaceCam.bat"

echo @echo off > "dist\iRoopDeepFaceCam\Launch_GPU_CUDA.bat"
echo echo Starting iRoopDeepFaceCam with CUDA... >> "dist\iRoopDeepFaceCam\Launch_GPU_CUDA.bat"
echo "%%~dp0iRoopDeepFaceCam.exe" --execution-provider cuda --execution-threads 5 >> "dist\iRoopDeepFaceCam\Launch_GPU_CUDA.bat"
echo pause >> "dist\iRoopDeepFaceCam\Launch_GPU_CUDA.bat"

echo.
echo ============================================
echo   BUILD COMPLETE!
echo ============================================
echo.
echo Output directory: dist\iRoopDeepFaceCam\
echo Executable:       dist\iRoopDeepFaceCam\iRoopDeepFaceCam.exe
echo.
echo IMPORTANT - Before running:
echo   1. Place model files in dist\iRoopDeepFaceCam\models\
echo      - inswapper_128_fp16.onnx (required)
echo      - GFPGANv1.4.pth (optional, for face enhancement)
echo   2. Install FFmpeg and add to system PATH
echo      https://ffmpeg.org/download.html
echo.
pause
