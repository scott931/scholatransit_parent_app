@echo off
echo Clearing all Flutter and Android build caches...

REM Stop all Java processes (Gradle daemons)
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul

REM Clear Flutter cache
flutter clean

REM Clear Flutter build cache
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul

REM Clear Android build cache
rmdir /s /q android\build 2>nul
rmdir /s /q android\app\build 2>nul

REM Clear Gradle cache
rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
rmdir /s /q "%USERPROFILE%\.gradle\wrapper\dists" 2>nul

REM Clear Flutter cache directory
rmdir /s /q "%USERPROFILE%\.flutter" 2>nul

REM Clear pub cache
flutter pub cache clean

REM Get fresh dependencies
flutter pub get

echo All caches cleared! Now run your app with run_fresh.bat
