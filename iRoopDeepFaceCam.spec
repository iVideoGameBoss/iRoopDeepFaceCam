# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec file for iRoopDeepFaceCam Windows executable.

Usage:
    pyinstaller iRoopDeepFaceCam.spec

This builds a one-folder distribution with all dependencies bundled.
Models and ffmpeg must be placed alongside the executable manually.
"""

import os
import sys
import site
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# --- Locate package data directories ---
site_packages = site.getsitepackages()[0]

# CustomTkinter theme/assets
customtkinter_data = collect_data_files('customtkinter')

# ONNX Runtime shared libraries
onnxruntime_data = collect_data_files('onnxruntime')

# --- Hidden imports that PyInstaller may miss ---
hidden_imports = [
    # Core modules
    'modules',
    'modules.core',
    'modules.globals',
    'modules.metadata',
    'modules.ui',
    'modules.typing',
    'modules.capturer',
    'modules.face_analyser',
    'modules.predicter',
    'modules.server',
    'modules.utilities',
    'modules.processors',
    'modules.processors.frame',
    'modules.processors.frame.core',
    'modules.processors.frame.face_swapper',
    'modules.processors.frame.face_enhancer',
    # Deep learning frameworks
    'torch',
    'torchvision',
    'tensorflow',
    'onnx',
    'onnxruntime',
    'insightface',
    'gfpgan',
    # Image/video processing
    'cv2',
    'cv2_enumerate_cameras',
    'PIL',
    'PIL.Image',
    'PIL.ImageOps',
    'PIL.ImageTk',
    'numpy',
    # UI
    'customtkinter',
    'tkinter',
    'tkinter.filedialog',
    'tkinter.messagebox',
    # Web/server
    'flask',
    'flask_cors',
    'waitress',
    'selenium',
    'webdriver_manager',
    'requests',
    'yt_dlp',
    # Utilities
    'psutil',
    'tqdm',
    'protobuf',
    'google.protobuf',
    'sympy',
    'opennsfw2',
    # Standard library modules sometimes missed
    'ctypes',
    'json',
    'threading',
    'concurrent.futures',
    'collections',
    'argparse',
    'signal',
    'platform',
    'mimetypes',
    'ssl',
    'urllib',
    'urllib.request',
    'glob',
    'shutil',
    'subprocess',
    'pathlib',
]

# Collect all insightface submodules (model zoo, etc.)
hidden_imports += collect_submodules('insightface')
hidden_imports += collect_submodules('onnxruntime')
hidden_imports += collect_submodules('gfpgan')
hidden_imports += collect_submodules('opennsfw2')

# --- Data files to bundle ---
datas = [
    # CustomTkinter UI theme
    (os.path.join('modules', 'ui.json'), 'modules'),
    # Module __init__ files
    (os.path.join('modules', '__init__.py'), 'modules'),
    (os.path.join('modules', 'processors', '__init__.py'), os.path.join('modules', 'processors')),
    (os.path.join('modules', 'processors', 'frame', '__init__.py'), os.path.join('modules', 'processors', 'frame')),
    # Firefox extension (optional)
    ('FireFox_Face_Swap_Ext', 'FireFox_Face_Swap_Ext'),
]

# Add customtkinter and onnxruntime data
datas += customtkinter_data
datas += onnxruntime_data

# --- Analysis ---
a = Analysis(
    ['run.py'],
    pathex=['.'],
    binaries=[],
    datas=datas,
    hiddenimports=hidden_imports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'matplotlib',
        'scipy.spatial.cKDTree',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='iRoopDeepFaceCam',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,  # Keep console for debug output; set False for release
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,  # Set to .ico file path if you have one
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='iRoopDeepFaceCam',
)
