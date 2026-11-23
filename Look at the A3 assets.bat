@echo off
rem Double-click this file to look at the Assignment 3 assets in Godot 4.7.2, at game size, with their sizes.
rem It opens asset_room/asset_room.tscn: the s'more, the pizza slice and the cooler beside the raccoon, plus the
rem round pizza, the practice donut, the camper and his dropped beanie. Each has a label with its size as Godot
rem measures it (W x D x H, in metres).
rem Keys: 1 raccoon, 2 cooler, 3 s'more, 4 pizza slice, 5 donut, 6 round pizza, 7 camper, 8 beanie, 0 all of them.
rem Drag to orbit, wheel to zoom, G the game's own camera, B from below, L labels on and off, Esc to quit.
rem Godot is found the same way as "Play The Noise Next Door.bat": the GODOT variable, then a Godot folder beside
rem this repo, then %LOCALAPPDATA%\Programs\Godot, then the Downloads folder.
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
rem Import the models every time. On a fresh clone there's no .godot folder yet, so this makes Godot's copies (8 s
rem on a fresh copy here); after a model changes it updates them; otherwise it takes about 4 s. A scene started from
rem the command line doesn't import anything itself, so without this it would show old models or none.
echo Importing the models...
"%GODOT_EXE%" --headless --path "%~dp0." --import
if errorlevel 1 (
	echo The import failed. See the messages above.
	pause
	exit /b 1
)
start "" "%GODOT_EXE%" --path "%~dp0." res://asset_room/asset_room.tscn %*
