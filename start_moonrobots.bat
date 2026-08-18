@echo off
setlocal

set "CONDA_ROOT=D:\conda\environments\moonbit"
set "PROJECT_ROOT=D:\conda\environments\moonbit\projects\moonrobots"
set "PORT=8877"
set "URL=http://127.0.0.1:%PORT%/web/index.html"
set "PATH=%CONDA_ROOT%;%CONDA_ROOT%\moonbit-toolchain\bin;%CONDA_ROOT%\Library\bin;%PATH%"

rem ================================
rem MoonRobots 一键启动器
rem 双击即可启动 Studio 并自动打开页面
rem ================================

rem 1) 释放之前残留的监听进程，避免端口被占用
for /f "tokens=5" %%P in ('netstat -ano -p tcp ^| findstr /R /C:":%PORT% " 2^>nul') do (
    if not "%%P"=="" (
        echo 检测到端口 %PORT% 已被 PID %%P 占用，正在释放...
        taskkill /PID %%P /F >nul 2>&1
    )
)

rem 2) 进入项目目录并启动 Studio
cd /d "%PROJECT_ROOT%"
set "MOONROBOTS_PORT=%PORT%"
start "MoonRobots Studio" cmd /k "cd /d ^"%PROJECT_ROOT%^" && set "MOONROBOTS_PORT=%PORT%" && powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\serve.ps1"

rem 3) 等待启动完成后自动打开浏览器
powershell -NoProfile -ExecutionPolicy Bypass -Command "$url = 'http://127.0.0.1:%PORT%/web/index.html'; $ok = $false; for ($i = 0; $i -lt 30; $i++) { try { $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 1; if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) { $ok = $true; break } } catch {} ; Start-Sleep -Milliseconds 500 }; if (-not $ok) { exit 1 }"
if errorlevel 1 (
    echo.
    echo 启动超时，网页可能还未就绪，请稍后手动访问：%URL%
    echo.
    pause
    exit /b 1
)

start "" "%URL%"

echo.
echo MoonRobots Studio 已就绪。
echo 打开页面: %URL%

endlocal
