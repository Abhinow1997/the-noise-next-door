@echo off
rem Double-click this file to play the game.
rem Looks for Godot 4.7.2 in the GODOT variable, then the Godot folder next to
rem this repo (Gamedev\Godot), then %LOCALAPPDATA%\Programs\Godot,
rem then the original Downloads folder. Extra arguments are passed to the game.
set "GODOT_EXE=%GODOT%"
if not defined GODOT_EXE if exist "%~dp0..\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%~dp0..\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_EXE if exist "%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_EXE (
	echo Could not find Godot 4.7.2.
	echo Install it to %LOCALAPPDATA%\Programs\Godot, or set GODOT to the path of its .exe.
	pause
	exit /b 1
)
rem Import the raccoon model on the first run, as the editor would.
if not exist "%~dp0.godot\imported\raccoon.glb-*.scn" "%GODOT_EXE%" --headless --path "%~dp0." --import
start "" "%GODOT_EXE%" --path "%~dp0." %*
