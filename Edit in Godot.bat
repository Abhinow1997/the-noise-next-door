@echo off
rem Double-click this file to open the project in the Godot editor. Press F5 there to play.
rem Finds Godot the same way as "Play The Noise Next Door.bat".
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
start "" "%GODOT_EXE%" --path "%~dp0." --editor %*
