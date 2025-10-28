@echo off
echo Fixing Gradle download issues...

REM Stop any running Gradle daemons
taskkill /f /im java.exe 2>nul

REM Clean Flutter
flutter clean

REM Remove Gradle cache and wrapper
rmdir /s /q "%USERPROFILE%\.gradle\wrapper\dists" 2>nul
rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul

REM Wait a moment
timeout /t 3 /nobreak >nul

echo Gradle cache cleaned. Now try building again...
echo Run: flutter run
