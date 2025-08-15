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
set PREDICTOR_URL=https://raw.githubusercontent.com/codeniko/shape_predictor_81_face_landmarks/master/shape_predictor_81_face_landmarks.dat

echo:
echo === DeepfakeBench: arrange + prepare %DATASET% ===
echo Repo:        %REPO_ROOT%
echo Data root:   %DATA_ROOT%
echo Frames:      %NUM_FRAMES%
echo Workers:     %WORKERS%
echo:

REM ---- Basic checks ----
where python >nul 2>&1 || ( echo [ERROR] Python not found in PATH. Activate your conda env first. & exit /b 1 )
where powershell >nul 2>&1 || ( echo [ERROR] PowerShell not found in PATH. & exit /b 1 )

if not exist "%PREPROC_DIR%\preprocess.py" ( echo [ERROR] preprocessing\preprocess.py not found. Run from repo root. & exit /b 1 )
if not exist "%PREPROC_DIR%\rearrange.py"  ( echo [ERROR] preprocessing\rearrange.py not found.  Run from repo root. & exit /b 1 )

REM ---- Ensure base folders ----
if not exist "%DATA_ROOT%" mkdir "%DATA_ROOT%"
if not exist "%DATA_ROOT%\Real"    mkdir "%DATA_ROOT%\Real"
if not exist "%DATA_ROOT%\Fake"    mkdir "%DATA_ROOT%\Fake"
if not exist "%DATA_ROOT%\Unknown" mkdir "%DATA_ROOT%\Unknown"
if not exist "%JSON_DIR%"          mkdir "%JSON_DIR%"
if not exist "%PREPROC_DIR%\dlib_tools" mkdir "%PREPROC_DIR%\dlib_tools"

REM ---- Ensure landmarks predictor (auto-download if missing) ----
if not exist "%LANDMARKS%" (
  echo [INFO] Downloading dlib landmarks model (shape_predictor_81_face_landmarks.dat) ...
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Try { Invoke-WebRequest -UseBasicParsing -Uri '%PREDICTOR_URL%' -OutFile '%LANDMARKS%' } Catch { exit 2 }"
  if errorlevel 2 (
    echo [ERROR] Could not download landmarks model automatically.
    echo         Download it manually and place at:
    echo         %LANDMARKS%
    exit /b 1
  )
)

REM ---- Unzip any archives safely (subroutine) ----
echo [INFO] Unzipping any archives in %DATA_ROOT% ...
if exist "%DATA_ROOT%\*.zip" (
  for %%Z in ("%DATA_ROOT%\*.zip") do echo   - %%~nxZ
  for %%Z in ("%DATA_ROOT%\*.zip") do call :Unzip "%%~fZ"
) else (
  echo   - (none found)
)

REM ---- Move known subfolders into Real/ and Fake/ ----
echo [INFO] Sorting known subfolders into Real/ and Fake/ ...
for %%S in (Real real RealVideo Real_Videos real_videos Authentic Authentic_Videos Genuine Originals Original) do (
  if exist "%DATA_ROOT%\%%S" robocopy "%DATA_ROOT%\%%S" "%DATA_ROOT%\Real" /E /MOVE >nul
)
for %%S in (Fake fake Deepfake Deepfakes FakeVideo Fake_Videos fake_videos Forgery Forged Manipulated Altered Edited) do (
  if exist "%DATA_ROOT%\%%S" robocopy "%DATA_ROOT%\%%S" "%DATA_ROOT%\Fake" /E /MOVE >nul
)

REM ---- Classify loose video files by filename heuristics ----
echo [INFO] Classifying loose video files ...
for /r "%DATA_ROOT%" %%F in (*.mp4 *.avi *.mov *.mkv *.mpg *.m4v *.wmv) do call :ProcessFile "%%~fF"

REM ---- Quick stats ----
echo:
echo [INFO] After arranging:
powershell -NoProfile -Command ^
  "$r=(Get-ChildItem -Path '%DATA_ROOT%\Real' -File -Recurse | Measure-Object).Count; " ^
  "$f=(Get-ChildItem -Path '%DATA_ROOT%\Fake' -File -Recurse | Measure-Object).Count; " ^
  "$u=(Get-ChildItem -Path '%DATA_ROOT%\Unknown' -File -Recurse | Measure-Object).Count; " ^
  "Write-Host ('  Real   : ' + $r); Write-Host ('  Fake   : ' + $f); Write-Host ('  Unknown: ' + $u)"

powershell -NoProfile -Command ^
  "$u=(Get-ChildItem -Path '%DATA_ROOT%\Unknown' -File -Recurse | Measure-Object).Count; if($u -gt 0){ Write-Host '[WARN] There are files in Unknown\. Move them to Real\ or Fake\ and re-run prep.' }"

REM ---- Preprocess (detect -> align -> crop) ----
echo:
echo === [1/2] Preprocessing faces (mode=raw) ===
python "%PREPROC_DIR%\preprocess.py" ^
  --dataset %DATASET% ^
  --root "%DATA_ROOT%" ^
  --mode raw ^
  --num_frames %NUM_FRAMES% ^
  --workers %WORKERS%
if errorlevel 1 (
  echo [WARN] preprocess.py returned non-zero.
  echo       If your fork is config-only:
  echo         1) Edit preprocessing\config.yaml (dataset_name: UADFV, dataset_root_path: %DATA_ROOT%)
  echo         2) Re-run: python preprocessing\preprocess.py
)

REM ---- Build dataset JSON ----
echo:
echo === [2/2] Building dataset JSON ===
python "%PREPROC_DIR%\rearrange.py" ^
  --dataset %DATASET% ^
  --data_root "%DATA_ROOT%" ^
  --out "%JSON_DIR%\%DATASET%.json"
if errorlevel 1 (
  echo [ERROR] rearrange.py failed. Check folder names and that preprocessed outputs exist.
  exit /b 1
)

echo:
echo Done!
echo JSON written to: "%JSON_DIR%\%DATASET%.json"
echo Point your configs to: preprocessing\dataset_json
echo:
exit /b 0


:ProcessFile
REM --- Called as: call :ProcessFile "full\path\to\file.ext"
set "F=%~1"
set "FN=%~nx1"

REM Skip files already in Real\ or Fake\
set "TMP=!F:\Real\=!"
if /I not "!TMP!"=="!F!" goto :eof
set "TMP=!F:\Fake\=!"
if /I not "!TMP!"=="!F!" goto :eof

REM Heuristics on filename
echo %FN% | findstr /I "fake forg manipul deepfake altered counterfeit" >nul
if not errorlevel 1 ( move /Y "%F%" "%DATA_ROOT%\Fake\" >nul & goto :eof )

echo %FN% | findstr /I "real auth genu original bona fide" >nul
if not errorlevel 1 ( move /Y "%F%" "%DATA_ROOT%\Real\" >nul & goto :eof )

REM Unknowns parked for manual review
move /Y "%F%" "%DATA_ROOT%\Unknown\" >nul
goto :eof


:Unzip
REM Usage: call :Unzip "C:\full\path\file.zip"
set "ZIP=%~1"
echo [INFO] Extracting: %ZIP%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Try { Expand-Archive -Force -LiteralPath '%ZIP%' -DestinationPath '%DATA_ROOT%' } Catch { exit 2 }"
if errorlevel 2 (
  echo [WARN] PowerShell Expand-Archive failed, trying tar...
  tar -xf "%ZIP%" -C "%DATA_ROOT%"
)
goto :eof
