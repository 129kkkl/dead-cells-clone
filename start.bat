@echo off
setlocal EnableExtensions
title Cells of Ruin - Launcher
cd /d "%~dp0"

set "GODOT_EXE="
if exist "%~dp0tools\godot\Godot*.exe" (
  for %%F in ("%~dp0tools\godot\Godot*.exe") do set "GODOT_EXE=%%~fF"
)
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe"
if not defined GODOT_EXE (
  for /f "delims=" %%P in ('dir /b /s "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*\Godot_v*.exe" 2^>nul') do (
    set "GODOT_EXE=%%P"
    goto :found
  )
)
:found

if not defined GODOT_EXE (
  echo [错误] 未找到 Godot 4.x。
  echo 请安装：winget install GodotEngine.GodotEngine
  echo 或将 Godot 可执行文件放到 tools\godot\ 目录下。
  pause
  exit /b 1
)

echo 使用引擎: %GODOT_EXE%
echo 启动游戏...
start "" "%GODOT_EXE%" --path "%~dp0."
endlocal
