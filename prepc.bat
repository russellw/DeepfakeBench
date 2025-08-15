@echo off
REM ============================================================================
REM DeepfakeBench UADFV Dataset Preprocessing Script for Windows
REM ============================================================================
REM This script automates the preprocessing of UADFV dataset for DeepfakeBench
REM Based on DeepfakeBench requirements from GitHub repository
REM ============================================================================

echo Starting UADFV dataset preprocessing for DeepfakeBench...
echo.

REM ============================================================================
REM Configuration Variables - MODIFY THESE PATHS AS NEEDED
REM ============================================================================

REM Set the path to your DeepfakeBench installation
set DEEPFAKEBENCH_PATH=C:\DeepfakeBench

REM Set the path to your UADFV dataset (within DeepfakeBench datasets directory)
set UADFV_DATA_PATH=%DEEPFAKEBENCH_PATH%\datasets\UADFV

REM Set the output path for processed data
set OUTPUT_PATH=%UADFV_DATA_PATH%_processed

REM Set the path for dlib landmarks file
set DLIB_LANDMARKS_URL=https://github.com/davisking/dlib-models/raw/master/shape_predictor_81_face_landmarks.dat.bz2
set DLIB_LANDMARKS_FILE=%DEEPFAKEBENCH_PATH%\preprocessing\dlib_tools\shape_predictor_81_face_landmarks.dat

REM Conda environment name
set CONDA_ENV_NAME=DeepfakeBench

echo Configuration:
echo - DeepfakeBench Path: %DEEPFAKEBENCH_PATH%
echo - UADFV Data Path: %UADFV_DATA_PATH%
echo - Output Path: %OUTPUT_PATH%
echo - Conda Environment: %CONDA_ENV_NAME%
echo.

REM ============================================================================
REM Prerequisites Check
REM ============================================================================

echo Checking prerequisites...

REM Check if DeepfakeBench directory exists
if not exist "%DEEPFAKEBENCH_PATH%" (
    echo ERROR: DeepfakeBench directory not found at %DEEPFAKEBENCH_PATH%
    echo Please clone DeepfakeBench first:
    echo   git clone https://github.com/SCLBD/DeepfakeBench.git
    pause
    exit /b 1
)

REM Check if UADFV data directory exists
if not exist "%UADFV_DATA_PATH%" (
    echo ERROR: UADFV data directory not found at %UADFV_DATA_PATH%
    echo Please download and extract UADFV dataset first
    echo Expected structure: %UADFV_DATA_PATH%\fake and %UADFV_DATA_PATH%\real
    pause
    exit /b 1
)

echo Prerequisites check passed!
echo.

REM ============================================================================
REM Environment Check
REM ============================================================================

echo Using current conda environment...
echo.

REM ============================================================================
REM Download Required Files
REM ============================================================================

echo Downloading required files...

REM Create dlib_tools directory if it doesn't exist
if not exist "%DEEPFAKEBENCH_PATH%\preprocessing\dlib_tools" (
    mkdir "%DEEPFAKEBENCH_PATH%\preprocessing\dlib_tools"
)

REM Download dlib landmarks file if it doesn't exist
if not exist "%DLIB_LANDMARKS_FILE%" (
    echo Downloading dlib shape predictor landmarks file...
    
    REM Check if we have curl or wget
    where curl >nul 2>nul
    if %errorlevel% equ 0 (
        echo Using curl to download landmarks file...
        curl -L -o "%DLIB_LANDMARKS_FILE%.bz2" "%DLIB_LANDMARKS_URL%"
        
        REM Extract bz2 file (requires 7-zip or similar)
        where 7z >nul 2>nul
        if %errorlevel% equ 0 (
            7z e "%DLIB_LANDMARKS_FILE%.bz2" -o"%DEEPFAKEBENCH_PATH%\preprocessing\dlib_tools\"
            del "%DLIB_LANDMARKS_FILE%.bz2"
        ) else (
            echo WARNING: 7-zip not found. Please manually extract %DLIB_LANDMARKS_FILE%.bz2
            echo You can download 7-zip from https://www.7-zip.org/
        )
    ) else (
        echo ERROR: curl not found. Please download the landmarks file manually:
        echo URL: %DLIB_LANDMARKS_URL%
        echo Save to: %DLIB_LANDMARKS_FILE%
        echo (Note: Extract the .bz2 file after downloading)
        pause
    )
) else (
    echo Dlib landmarks file already exists
)

echo.

REM ============================================================================
REM Configure Preprocessing Settings
REM ============================================================================

echo Configuring preprocessing settings...

REM Backup original config.yaml
if exist "%DEEPFAKEBENCH_PATH%\preprocessing\config.yaml.backup" (
    echo Backup config already exists
) else (
    echo Creating backup of original config.yaml...
    copy "%DEEPFAKEBENCH_PATH%\preprocessing\config.yaml" "%DEEPFAKEBENCH_PATH%\preprocessing\config.yaml.backup"
)

REM Create temporary config for UADFV
echo Creating UADFV-specific configuration...
(
echo preprocess:
echo   dataset_name: 'UADFV'
echo   dataset_root_path: '%UADFV_DATA_PATH%'
echo   comp: 'raw'
echo   mode: 'fixed_num_frames'
echo   stride: 10
echo   num_frames: 32
echo.
echo rearrange:
echo   dataset_name: 'UADFV'
echo   dataset_root_path: '%UADFV_DATA_PATH%'
echo   output_file_path: '%DEEPFAKEBENCH_PATH%\preprocessing\dataset_json'
echo   comp: 'raw'
) > "%DEEPFAKEBENCH_PATH%\preprocessing\config_uadfv.yaml"

echo Configuration completed!
echo.

REM ============================================================================
REM Data Preprocessing
REM ============================================================================

echo Starting data preprocessing...
echo This may take a while depending on your dataset size and hardware...
echo.

REM Navigate to preprocessing directory
cd /d "%DEEPFAKEBENCH_PATH%\preprocessing"

REM Run preprocessing script
echo Running face detection, alignment, and cropping...
python preprocess.py --config config_uadfv.yaml

if %errorlevel% neq 0 (
    echo ERROR: Preprocessing failed
    echo Please check the error messages above
    pause
    exit /b 1
)

echo Preprocessing completed successfully!
echo.

REM ============================================================================
REM Data Rearrangement (Generate JSON files)
REM ============================================================================

echo Generating dataset JSON files for unified data loading...

REM Run rearrangement script
python rearrange.py --config config_uadfv.yaml

if %errorlevel% neq 0 (
    echo ERROR: Data rearrangement failed
    echo Please check the error messages above
    pause
    exit /b 1
)

echo Data rearrangement completed successfully!
echo.

REM ============================================================================
REM Verify Output Structure
REM ============================================================================

echo Verifying output structure...

set EXPECTED_DIRS=frames landmarks masks
for %%d in (%EXPECTED_DIRS%) do (
    if exist "%OUTPUT_PATH%\%%d" (
        echo [OK] Found %%d directory
    ) else (
        echo [WARNING] Missing %%d directory
    )
)

if exist "%DEEPFAKEBENCH_PATH%\preprocessing\dataset_json\UADFV.json" (
    echo [OK] Found UADFV.json file
) else (
    echo [WARNING] UADFV.json file not found
)

echo.

REM ============================================================================
REM Summary and Next Steps
REM ============================================================================

echo ============================================================================
echo PREPROCESSING COMPLETED SUCCESSFULLY!
echo ============================================================================
echo.
echo Output Structure:
echo - Processed data: %OUTPUT_PATH%
echo   - frames/     : Extracted and cropped face images
echo   - landmarks/  : Facial landmark annotations
echo   - masks/      : Face masks for training
echo - JSON file: %DEEPFAKEBENCH_PATH%\preprocessing\dataset_json\UADFV.json
echo.
echo Next Steps:
echo 1. Verify the processed data looks correct
echo 2. Update your training configuration to use the processed dataset
echo 3. Start training your deepfake detection model
echo.
echo Example training command:
echo   cd %DEEPFAKEBENCH_PATH%
echo   conda activate %CONDA_ENV_NAME%
echo   python training/train.py --dataset UADFV
echo.
echo For more information, visit: https://github.com/SCLBD/DeepfakeBench
echo ============================================================================

pause
echo Script completed. Press any key to exit...