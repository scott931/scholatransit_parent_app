@echo off
echo Clearing app-specific cache and storage...

REM Clear app storage data
echo Clearing SharedPreferences and Hive storage...
adb shell pm clear com.scholatransit.driver.scholatransit_driver_app 2>nul

REM Clear Flutter build cache
echo Clearing Flutter build cache...
flutter clean
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul

REM Clear Android build cache
echo Clearing Android build cache...
rmdir /s /q android\build 2>nul
rmdir /s /q android\app\build 2>nul

REM Get fresh dependencies
echo Getting fresh dependencies...
flutter pub get

echo App cache cleared! You can now run your app.
