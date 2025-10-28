@echo off
echo Starting fast Flutter build...

REM Clean previous build artifacts
flutter clean

REM Get dependencies
flutter pub get

REM Build for debug with optimizations
flutter build apk --debug --target-platform android-arm64 --split-per-abi

echo Build completed!
echo APK location: build/app/outputs/flutter-apk/app-debug-arm64-v8a.apk
