@echo off
echo Fixing hot reload cache issues...

REM Stop all Java processes (Gradle daemons)
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul

REM Clear Flutter cache
echo Clearing Flutter cache...
flutter clean

REM Clear build directories
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul

REM Clear Android build cache
rmdir /s /q android\build 2>nul
rmdir /s /q android\app\build 2>nul

REM Clear app data from device
echo Clearing app data from device...
adb shell pm clear com.scholatransit.driver.scholatransit_driver_app 2>nul

REM Get fresh dependencies
echo Getting fresh dependencies...
flutter pub get

REM Check for available devices first
echo Checking for available devices...
flutter devices

REM Run with hot reload and cache busting
echo Starting app with hot reload cache fix...
flutter run --debug --no-fast-start --hot --verbose

echo Done. Hot reload should now work properly.
