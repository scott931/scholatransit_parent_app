@echo off
echo Performing fresh install and debug run...

REM Stop all Java/Gradle processes
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul

REM Uninstall existing app from connected device (ignore errors if not installed)
adb uninstall com.scholatransit.driver.scholatransit_driver_app 2>nul

REM Aggressive cache clearing
echo Clearing all caches...
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q android\build 2>nul
rmdir /s /q android\app\build 2>nul

REM Full clean and dependency fetch
flutter clean
flutter pub cache clean
flutter pub get

REM Build and install debug APK freshly, then launch with hot-reload
flutter run --debug --no-fast-start --verbose

echo Done.

