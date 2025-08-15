@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ========= CONFIG (edit if needed) =========
set DATASET=UADFV
set NUM_FRAMES=32
set WORKERS=8
set DATA_ROOT=%CD%\datasets\%DATASET%
REM ==========================================

set REPO_ROOT=%CD%
set PREPROC_DIR=%REPO_ROOT%\preprocessing
set JSON_DIR=%PREPROC_DIR%\dataset_json
set LANDMARKS=%PREPROC_DIR%\dlib_tools\shape_predictor_81_face_landmarks.dat

echo:
echo === DeepfakeBench: arrange + prepare %DATASET% ===
echo Repo:        %REPO_ROOT%
echo Data root:   %DATA_ROOT%
echo Frames:      %NUM_FRAMES%
echo Workers:     %WORKERS%
echo:

where python >nul 2>&1 || ( echo [ERROR] Python not found in PATH. Activate your conda env first. & exit /b 1 )
where powershell >nul 2>&1 || ( echo [ERROR] PowerShell not found in PATH. & exit /b 1 )

if not exist "%PREPROC_DIR%\preprocess.py" ( echo [ERROR] preprocessing\preprocess.py not found. Run from repo root. & exit /b 1 )
if not exist "%PREPROC_DIR%\rearrange.py"  ( echo [ERROR] preprocessing\rearrange.py not found.  Run from repo root. & exit /b 1 )

if not exist "%LANDMARKS%" (
  echo [ERROR] Missing %LANDMARKS%
  echo         Download "shape_predictor_81_face_landmarks.dat" to that folder, then re-run.
  exit /b 1
)

if not exist "%DATA_ROOT%" mkdir "%DATA_ROOT%"
if not exist "%DATA_ROOT%\Real"    mkdir "%DATA_ROOT%\Real"
if not exist "%DATA_ROOT%\Fake"    mkdir "%DATA_ROOT%\Fake"
if not exist "%DATA_ROOT%\Unknown" mkdir "%DATA_ROOT%\Unknown"

echo [INFO] Unzipping any archives in %DATA_ROOT% ...
for %%Z in ("%DATA_ROOT%\*.zip") do*_
