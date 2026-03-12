@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "EXIT_CODE=0"

REM Run in the script directory (repo root expected)
cd /d "%~dp0"

where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git not found in PATH.
    set "EXIT_CODE=1"
    goto :End
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Current directory is not a Git repository.
    set "EXIT_CODE=1"
    goto :End
)

echo [1/3] Pulling main repository...
git pull --ff-only
if errorlevel 1 (
    echo [ERROR] Failed to pull main repository.
    set "EXIT_CODE=1"
    goto :End
)

echo [2/3] Syncing and initializing submodules...
git submodule sync --recursive
git submodule update --init --recursive
if errorlevel 1 (
    echo [ERROR] Failed to update submodules.
    set "EXIT_CODE=1"
    goto :End
)

echo [3/3] Pulling each submodule...
set "HAS_SUBMODULES=0"
for /f "tokens=2" %%S in ('git config -f .gitmodules --get-regexp "^submodule\..*\.path$" 2^>nul') do (
    set "HAS_SUBMODULES=1"
    call :PullSubmodule "%%S"
    if errorlevel 1 (
        set "EXIT_CODE=1"
        goto :End
    )
)

if "!HAS_SUBMODULES!"=="0" (
    echo [INFO] No submodules configured.
)

echo.
echo [DONE] Main repository and submodules are up to date.
goto :End

:End
echo.
echo Press any key to exit...
pause >nul
exit /b %EXIT_CODE%

:PullSubmodule
set "SM_PATH=%~1"
set "SM_BRANCH="

for /f %%B in ('git -C "%SM_PATH%" symbolic-ref --short -q HEAD 2^>nul') do set "SM_BRANCH=%%B"

echo --- %SM_PATH% ---
if "%SM_BRANCH%"=="" (
    echo [INFO] Detached HEAD in %SM_PATH%. Skip pull.
    exit /b 0
)

git -C "%SM_PATH%" pull --ff-only
if errorlevel 1 (
    echo [ERROR] Failed to pull submodule: %SM_PATH%
    exit /b 1
)

exit /b 0
