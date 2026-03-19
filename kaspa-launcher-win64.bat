@echo off
setlocal enabledelayedexpansion

set "config=%~dp0kaspa-config.txt"

:start
cls
echo ================================
echo    KASPA LAUNCHER
echo ================================
echo.

if not exist "%config%" (
    echo Creating default config file...
    (
        echo kaspad.exe=--retention-period-days=2
        echo kaspa-wallet.exe=
        echo rothschild.exe=
        echo stratum-bridge.exe=
    ) > "%config%"
    echo Config file created at: %config%
    echo.
)

echo Select Kaspa executable to run:
echo.
echo 1. kaspad.exe         (Node) [DEFAULT - Press Enter]
echo 2. kaspa-wallet.exe   (Wallet)
echo 3. rothschild.exe     (Stress Test)
echo 4. stratum-bridge.exe (Mine to Node)
echo 5. Manage arguments
echo 6. Exit
echo.

set /p choice="Enter your choice (1-6, or press Enter for 1): "
if not defined choice set "choice=1"

if "%choice%"=="1" set "exe=kaspad.exe"        & goto load_and_run
if "%choice%"=="2" set "exe=kaspa-wallet.exe"  & goto load_and_run
if "%choice%"=="3" set "exe=rothschild.exe"    & goto load_and_run
if "%choice%"=="4" set "exe=stratum-bridge.exe" & goto load_and_run
if "%choice%"=="5" goto manage_args
if "%choice%"=="6" goto end

echo Invalid choice.
pause
goto start

:: ============================================================
:load_and_run
:: Read raw == delimited args, convert == to spaces for execution
set "raw_args="
for /f "tokens=1,* delims==" %%a in ('findstr /l /b "!exe!=" "%config%"') do set "raw_args=%%b"

set "KASP_RAW=!raw_args!"
for /f "delims=" %%r in ('powershell -NoProfile -Command "if($env:KASP_RAW){$env:KASP_RAW -replace '==', ' '}else{''}"') do set "run_args=%%r"

echo.
echo Running: !exe! !run_args!
echo.
echo Press Ctrl+C to stop the process
echo ================================
echo.
"%~dp0!exe!" !run_args!
echo.
echo Process ended.
pause
goto start

:: ============================================================
:manage_args
cls
echo ================================
echo    MANAGE SAVED ARGUMENTS
echo ================================
echo.
echo Current config:
echo.
type "%config%"
echo.
echo Which executable?
echo.
echo 1. kaspad.exe
echo 2. kaspa-wallet.exe
echo 3. rothschild.exe
echo 4. stratum-bridge.exe
echo 5. Back to main menu
echo.
set /p manage_choice="Choice (1-5): "

if "%manage_choice%"=="1" set "manage_exe=kaspad.exe"        & goto do_manage
if "%manage_choice%"=="2" set "manage_exe=kaspa-wallet.exe"  & goto do_manage
if "%manage_choice%"=="3" set "manage_exe=rothschild.exe"    & goto do_manage
if "%manage_choice%"=="4" set "manage_exe=stratum-bridge.exe" & goto do_manage
if "%manage_choice%"=="5" goto start

echo Invalid choice.
pause
goto manage_args

:: ============================================================
:do_manage
cls
echo ================================
echo    %manage_exe%
echo ================================
echo.

set "current_args="
for /f "tokens=1,* delims==" %%a in ('findstr /l /b "%manage_exe%=" "%config%"') do set "current_args=%%b"

:: Normalize: convert space-separated -- args to == delimiter, then save back clean
if not "!current_args!"=="" (
    set "KASP_RAW=!current_args!"
    for /f "delims=" %%r in ('powershell -NoProfile -Command "$raw=$env:KASP_RAW; $normalized=($raw -replace ' --','==--'); $normalized"') do set "current_args=%%r"
    :: Save normalized version back to config if it changed
    if not "!current_args!"=="!KASP_RAW!" (
        set "KASP_EXE=!manage_exe!"
        set "KASP_ARGS=!current_args!"
        powershell -NoProfile -Command "$f=$env:config; $exe=$env:KASP_EXE; $a=if($env:KASP_ARGS){$env:KASP_ARGS}else{''}; (Get-Content $f) | ForEach-Object { if($_ -match ('^'+[regex]::Escape($exe)+'=')){ $exe+'='+$a } else { $_ } } | Set-Content $f"
    )
)

if "!current_args!"=="" (
    echo Current args: ^(none^)
    echo.
) else (
    echo Current args:
    echo.
    set "KASP_CHECK=!current_args!"
    for /f "delims=" %%r in ('powershell -NoProfile -Command "$i=1; $env:KASP_CHECK -split '==' | Where-Object { $_ -ne '' } | ForEach-Object { Write-Output \"  $i. $_\"; $i++ }"') do echo %%r
    echo.
)

echo 1. Add argument
echo 2. Remove argument
echo 3. Clear all arguments
echo 4. View available arguments (-h)
echo 5. Back
echo.
set /p arg_action="Choice (1-5): "

if "%arg_action%"=="1" goto add_arg
if "%arg_action%"=="2" goto remove_arg
if "%arg_action%"=="3" goto clear_args
if "%arg_action%"=="4" goto show_help
if "%arg_action%"=="5" goto manage_args

echo Invalid choice.
pause
goto do_manage

:: ============================================================
:add_arg
echo.
echo Enter argument to add, or pick a number:
echo.
echo   1. --retention-period-days=2
echo   2. --ram-scale=0.5
echo   3. --disable-upnp
echo   4. --utxoindex
echo   5. --appdir C:\path\to\SSD\storage
echo.
echo (Or type any argument directly)
echo.
set /p "new_arg="
if not defined new_arg (
    echo Nothing entered.
    pause
    goto do_manage
)

:: Map number shortcuts to actual arguments
if "!new_arg!"=="1" set "new_arg=--retention-period-days=2"
if "!new_arg!"=="2" set "new_arg=--ram-scale=0.5"
if "!new_arg!"=="3" set "new_arg=--disable-upnp"
if "!new_arg!"=="4" set "new_arg=--utxoindex"
if "!new_arg!"=="5" set "new_arg=--appdir C:\path\to\SSD\storage"

:: Check duplicate split by ==
set "KASP_CHECK=!current_args!"
set "KASP_NEW=!new_arg!"
for /f %%r in ('powershell -NoProfile -Command "if($env:KASP_CHECK -split '==' | Where-Object { $_ -eq $env:KASP_NEW }){ 'FOUND' }else{ 'NOT_FOUND' }"') do set "dup_check=%%r"

if "!dup_check!"=="FOUND" (
    echo.
    echo Argument already exists: !new_arg!
    pause
    goto do_manage
)

if "!current_args!"=="" (
    set "updated_args=!new_arg!"
) else (
    set "updated_args=!current_args!==!new_arg!"
)

set "KASP_EXE=!manage_exe!"
set "KASP_ARGS=!updated_args!"
powershell -NoProfile -Command "$f=$env:config; $exe=$env:KASP_EXE; $a=if($env:KASP_ARGS){$env:KASP_ARGS}else{''}; (Get-Content $f) | ForEach-Object { if($_ -match ('^'+[regex]::Escape($exe)+'=')){ $exe+'='+$a } else { $_ } } | Set-Content $f"

echo.
echo Added successfully.
pause
goto do_manage

:: ============================================================
:remove_arg
echo.
if "!current_args!"=="" (
    echo No arguments to remove.
    pause
    goto do_manage
)

set "KASP_CHECK=!current_args!"
echo Current arguments:
echo.
for /f "delims=" %%r in ('powershell -NoProfile -Command "$i=1; $env:KASP_CHECK -split '==' | Where-Object { $_ -ne '' } | ForEach-Object { Write-Output \"  $i. $_\"; $i++ }"') do echo %%r
echo.

for /f %%r in ('powershell -NoProfile -Command "($env:KASP_CHECK -split '==' | Where-Object { $_ -ne '' }).Count"') do set "arg_count=%%r"

set /p "remove_num=Enter number to remove (1-!arg_count!): "

if not defined remove_num (
    echo Nothing entered.
    pause
    goto do_manage
)

for /f %%r in ('powershell -NoProfile -Command "if($env:remove_num -match '^\d+$' -and [int]$env:remove_num -ge 1 -and [int]$env:remove_num -le [int]$env:arg_count){ 'VALID' }else{ 'INVALID' }"') do set "num_check=%%r"

if "!num_check!"=="INVALID" (
    echo.
    echo Invalid — enter a number between 1 and !arg_count!.
    pause
    goto do_manage
)

for /f "delims=" %%r in ('powershell -NoProfile -Command "($env:KASP_CHECK -split '==' | Where-Object { $_ -ne '' })[[int]$env:remove_num - 1]"') do set "remove_arg=%%r"

echo.
echo Remove: !remove_arg!
set /p "confirm=Press Enter to confirm, or type n to cancel: "
if /i "!confirm!"=="n" (
    echo Cancelled.
    pause
    goto do_manage
)

for /f "delims=" %%r in ('powershell -NoProfile -Command "$arr=@($env:KASP_CHECK -split '==' | Where-Object { $_ -ne '' }); $idx=[int]$env:remove_num-1; $arr=@($arr | Where-Object { [array]::IndexOf($arr,$_) -ne $idx }); if($arr){ $arr -join '==' }else{ 'EMPTY' }"') do set "updated_args=%%r"

if "!updated_args!"=="EMPTY" set "updated_args="

set "KASP_EXE=!manage_exe!"
set "KASP_ARGS=!updated_args!"
powershell -NoProfile -Command "$f=$env:config; $exe=$env:KASP_EXE; $a=if($env:KASP_ARGS){$env:KASP_ARGS}else{''}; (Get-Content $f) | ForEach-Object { if($_ -match ('^'+[regex]::Escape($exe)+'=')){ $exe+'='+$a } else { $_ } } | Set-Content $f"

echo.
echo Removed successfully.
if "!updated_args!"=="" (
    echo !manage_exe! now has no arguments.
) else (
    echo !manage_exe! will now run with the remaining arguments.
)
pause
goto do_manage

:: ============================================================
:clear_args
echo.
echo Clear ALL arguments for %manage_exe%?
set /p "confirm_clear=Press Enter to confirm, or type n to cancel: "
if /i "!confirm_clear!"=="n" (
    echo Cancelled.
    pause
    goto do_manage
)

set "KASP_EXE=!manage_exe!"
powershell -NoProfile -Command "$f=$env:config; $exe=$env:KASP_EXE; (Get-Content $f) | ForEach-Object { if($_ -match ('^'+[regex]::Escape($exe)+'=')){ $exe+'=' } else { $_ } } | Set-Content $f"

echo.
echo All arguments cleared for %manage_exe%.
pause
goto do_manage

:: ============================================================
:show_help
cls
echo ================================
echo    HELP: %manage_exe%
echo ================================
echo.
if not exist "%~dp0%manage_exe%" (
    echo Error: %manage_exe% not found in script directory.
    pause
    goto do_manage
)
"%~dp0%manage_exe%" -h
echo.
pause
goto do_manage

:: ============================================================
:end
endlocal
