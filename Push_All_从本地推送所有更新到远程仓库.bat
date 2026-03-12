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

call :Divider
echo [1/4] Checking submodules ^(non-destructive^)...
git submodule sync --recursive
if errorlevel 1 (
    echo [ERROR] Failed to sync submodule config.
    set "EXIT_CODE=1"
    goto :End
)

git submodule status --recursive
if errorlevel 1 (
    echo [ERROR] Failed to read submodule status.
    set "EXIT_CODE=1"
    goto :End
)

call :Divider
echo [2/4] Processing submodules...
set "HAS_SUBMODULES=0"
for /f "tokens=2" %%S in ('git config -f .gitmodules --get-regexp "^submodule\..*\.path$" 2^>nul') do (
    set "HAS_SUBMODULES=1"
    call :ProcessRepo "%%S" "Submodule"
    if errorlevel 1 (
        set "EXIT_CODE=1"
        goto :End
    )
)

if "!HAS_SUBMODULES!"=="0" (
    echo [INFO] No submodules configured.
)

call :Divider
echo [3/4] Processing main repository...
call :ProcessRepo "." "Main repository"
if errorlevel 1 (
    echo [ERROR] Main repository processing failed.
    set "EXIT_CODE=1"
    goto :End
)

echo.
call :Divider
echo [4/4] Done.
call :Divider
goto :End

:ProcessRepo
set "REPO_PATH=%~1"
set "REPO_KIND=%~2"

echo.
echo ============================================================
echo [%REPO_KIND%] %REPO_PATH%
echo ============================================================
echo.

git -C "%REPO_PATH%" rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Invalid Git repository: %REPO_PATH%
    exit /b 1
)

call :ShowCategorizedChanges "%REPO_PATH%"

set "HAS_CHANGES=0"
for /f %%C in ('git -C "%REPO_PATH%" status --porcelain -uall ^| find /c /v ""') do set "HAS_CHANGES=%%C"

if "%HAS_CHANGES%"=="0" (
    echo [INFO] No local changes. Branch is up to date. Skip push.
    call :Divider
    exit /b 0
)

call :Divider
set "COMMIT_MSG="
set /p COMMIT_MSG=Enter commit message for %REPO_PATH%: 
if "%COMMIT_MSG%"=="" (
    echo [WARN] Empty commit message. Skip this repository.
    call :Divider
    exit /b 0
)

git -C "%REPO_PATH%" add -A
if errorlevel 1 (
    echo [ERROR] Failed to stage files for %REPO_PATH%.
    exit /b 1
)

echo.
call :Divider
echo [Preview] Files to be committed for %REPO_PATH%:
call :ShowCategorizedChanges "%REPO_PATH%"
call :Divider

set "CONFIRM="
set /p CONFIRM=Confirm commit? [Y/N]: 
if /I not "%CONFIRM%"=="Y" (
    echo [INFO] Commit canceled by user for %REPO_PATH%.
    git -C "%REPO_PATH%" reset >nul 2>&1
    call :Divider
    exit /b 0
)

git -C "%REPO_PATH%" commit -m "%COMMIT_MSG%"
if errorlevel 1 (
    echo [ERROR] Commit failed for %REPO_PATH%.
    exit /b 1
)

echo.
call :Divider
echo [Committed] Latest commit content for %REPO_PATH%:
git -C "%REPO_PATH%" show --name-status --pretty=oneline -1
call :Divider

call :CanPush "%REPO_PATH%"
if "%CAN_PUSH%"=="0" (
    echo [INFO] Branch is already up to date. Skip push.
) else (
    git -C "%REPO_PATH%" push
    if errorlevel 1 (
        echo [ERROR] Push failed for %REPO_PATH%.
        exit /b 1
    )
)

echo [OK] Commit/push step finished: %REPO_PATH%
call :Divider
exit /b 0

:CanPush
set "REPO_PATH=%~1"
set "CAN_PUSH=0"
set "HAS_UPSTREAM=0"
set "AHEAD_COUNT=0"

for /f %%U in ('git -C "%REPO_PATH%" rev-parse --abbrev-ref --symbolic-full-name @{u} 2^>nul') do set "HAS_UPSTREAM=1"

if "%HAS_UPSTREAM%"=="0" (
    set "CAN_PUSH=1"
    exit /b 0
)

for /f "tokens=1,2" %%A in ('git -C "%REPO_PATH%" rev-list --left-right --count @{u}...HEAD 2^>nul') do (
    set "AHEAD_COUNT=%%B"
)

if not "%AHEAD_COUNT%"=="0" set "CAN_PUSH=1"
exit /b 0

:Divider
echo ------------------------------------------------------------
exit /b 0

:ShowCategorizedChanges
set "REPO_PATH=%~1"
set "TMP_BASE=%TEMP%\git_changes_%RANDOM%_%RANDOM%"
set "TMP_ADD=%TMP_BASE%_add.txt"
set "TMP_MOD=%TMP_BASE%_mod.txt"
set "TMP_DEL=%TMP_BASE%_del.txt"

type nul > "%TMP_ADD%"
type nul > "%TMP_MOD%"
type nul > "%TMP_DEL%"

for /f "usebackq delims=" %%L in (`git -C "%REPO_PATH%" status --porcelain -uall`) do (
    set "LINE=%%L"
    set "CODE=!LINE:~0,2!"
    set "FILE=!LINE:~3!"

    if "!CODE!"=="??" (
        >> "%TMP_ADD%" echo !FILE!
    ) else (
        echo.!CODE!| find "D" >nul && (
            >> "%TMP_DEL%" echo !FILE!
        ) || (
            echo.!CODE!| find "A" >nul && (
                >> "%TMP_ADD%" echo !FILE!
            ) || (
                >> "%TMP_MOD%" echo !FILE!
            )
        )
    )
)

call :PrintCategory "Added" "%TMP_ADD%"
call :PrintCategory "Modified" "%TMP_MOD%"
call :PrintCategory "Deleted" "%TMP_DEL%"

del /q "%TMP_ADD%" "%TMP_MOD%" "%TMP_DEL%" >nul 2>&1
exit /b 0

:PrintCategory
set "TITLE=%~1"
set "FILE_PATH=%~2"
set "SIZE=0"

echo.
echo %TITLE%:
for %%Z in ("%FILE_PATH%") do set "SIZE=%%~zZ"

if "%SIZE%"=="0" (
    echo   ^(none^)
) else (
    for /f "usebackq delims=" %%R in (`sort "%FILE_PATH%" ^| findstr /v /r "^$"`) do echo   - %%R
)

exit /b 0

:End
echo.
echo Press any key to exit...
pause >nul
exit /b %EXIT_CODE%
