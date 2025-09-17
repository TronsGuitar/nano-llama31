@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_NAME=%~n0%~x0"
set "DEFAULT_DRIVE=%CD:~0,2%\"
set "TARGET_PATH="
set "OUTPUT_FILE="
set "LLM_EXTENSIONS=.safetensors .pth .bin .gguf"

if "%~1"=="/?" goto :usage
if "%~1"=="-h" goto :usage
if "%~1"=="--help" goto :usage

:parse_args
if "%~1"=="" goto :after_args
set "ARG=%~1"
if /I "!ARG!"=="--output" (
    if "%~2"=="" (
        echo [ERROR] Missing value for --output.
        goto :usage
    )
    set "OUTPUT_FILE=%~2"
    shift
    shift
    goto :parse_args
)
if /I "!ARG:~0,9!"=="--output=" (
    set "OUTPUT_FILE=!ARG:~9!"
    if "!OUTPUT_FILE!"=="" (
        echo [ERROR] Missing value for --output.
        goto :usage
    )
    shift
    goto :parse_args
)
if defined TARGET_PATH (
    echo [ERROR] Multiple target paths provided: "!TARGET_PATH!" and "%~1".
    goto :usage
)
set "TARGET_PATH=%~1"
shift
goto :parse_args

:after_args
if not defined TARGET_PATH set "TARGET_PATH=%DEFAULT_DRIVE%"

if "!TARGET_PATH:~-1!"==":" set "TARGET_PATH=!TARGET_PATH!\"

if not exist "!TARGET_PATH!" if not exist "!TARGET_PATH!\NUL" (
    echo [ERROR] Target path "!TARGET_PATH!" does not exist.
    goto :usage
)

if defined OUTPUT_FILE (
    >"%OUTPUT_FILE%" call :search
    if errorlevel 1 exit /b 1
    echo Results written to "%OUTPUT_FILE%".
) else (
    call :search
)
exit /b 0

:search
pushd "!TARGET_PATH!" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Unable to access "!TARGET_PATH!".
    exit /b 1
)
for %%E in (!LLM_EXTENSIONS!) do (
    for /r %%F in (*%%E) do (
        if exist "%%F" (
            echo %%F
        )
    )
)
popd >nul 2>&1
exit /b 0

:usage
echo.
echo Usage: %SCRIPT_NAME% [drive^|directory] [--output path^|--output=path]
echo.
echo    drive^|directory   Optional drive (e.g. C:) or directory root to search.
echo                       Defaults to the current drive "%DEFAULT_DRIVE%".
echo    --output path      Optional file to capture results. Can also be provided as
echo                       --output=path.
echo.
echo Examples:
echo    %SCRIPT_NAME%
echo    %SCRIPT_NAME% D:\Models
echo    %SCRIPT_NAME% "C:\Downloads" --output models.log
echo.
echo Customize the extensions searched by editing the LLM_EXTENSIONS variable near
echo the top of this script.
exit /b 1
