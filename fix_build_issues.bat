@echo off
echo Fixing build issues...

REM Stop any running processes
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul

REM Clean everything
echo Cleaning project...
flutter clean
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q android\build 2>nul
rmdir /s /q android\app\build 2>nul

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Check for devices
echo Checking for connected devices...
flutter devices

REM Try to build
echo Building APK...
flutter build apk --debug

echo Build process completed!
