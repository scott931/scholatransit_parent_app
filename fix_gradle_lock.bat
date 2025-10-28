@echo off
echo Fixing Gradle lock issues...

REM Stop all Java processes
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul

REM Wait a moment
timeout /t 2 /nobreak >nul

REM Clean everything
echo Cleaning project...
flutter clean
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q android\build 2>nul
rmdir /s /q android\app\build 2>nul

REM Clear Gradle cache
echo Clearing Gradle cache...
rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
rmdir /s /q "%USERPROFILE%\.gradle\wrapper\dists" 2>nul

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Try to run
echo Running app...
flutter run --debug

echo Done!
