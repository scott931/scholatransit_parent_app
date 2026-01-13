# Build Issues Troubleshooting Guide

## Issues Encountered

### 1. Shader Compilation Error (Exit Code -9)
**Error**: `ShaderCompilerException: Shader compilation failed with exit code -9`
**Cause**: Process killed due to memory/resource constraints or corrupted shader cache
**Solution**: 
- Run `./fix_shader_compilation.sh` (macOS/Linux) or clean manually:
  ```bash
  flutter clean
  rm -rf build/app/intermediates/flutter/debug/flutter_assets/shaders
  rm -rf android/app/build android/build
  flutter pub get
  flutter build apk --debug --no-shrink
  ```
- If still failing, try: `flutter build apk --debug --no-shrink --split-per-abi`
- Increase system memory or close other applications
- Check `android/gradle.properties` has sufficient memory: `-Xmx8G`

### 2. APK Build Path Issues
**Error**: `Asset path android\app\build\outputs\apk\debug\app-debug.apk is neither a directory nor file`
**Solution**: Clean build and rebuild

### 2. AndroidManifest.xml Issues
**Error**: `No application found for TargetPlatform.android_arm64`
**Solution**: AndroidManifest.xml exists and is properly configured

### 3. Missing Method Error
**Error**: `The method '_showClearCacheDialog' isn't defined`
**Solution**: Method exists but Dart analysis server needs refresh

## Solutions Implemented

### 1. Build Fix Script (`fix_build_issues.bat`)
```batch
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
```

### 2. Updated Hot Reload Script
- Removed hardcoded device ID
- Added device detection
- Improved error handling

### 3. Method Definition Verification
The `_showClearCacheDialog` method exists in `parent_dashboard_screen.dart` at line 663:
```dart
void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Clear App Cache'),
        // ... rest of implementation
      );
    },
  );
}
```

## Step-by-Step Fix Process

### 1. Run Build Fix Script
```bash
fix_build_issues.bat
```

### 2. If Still Having Issues
```bash
# Clean everything
flutter clean
rmdir /s /q build
rmdir /s /q .dart_tool
rmdir /s /q android\build
rmdir /s /q android\app\build

# Get fresh dependencies
flutter pub get

# Check devices
flutter devices

# Build APK
flutter build apk --debug
```

### 3. For Hot Reload Issues
```bash
# Use the hot reload fix script
run_hot_reload_fix.bat
```

### 4. For Device Connection Issues
```bash
# Check ADB connection
adb devices

# If device not found, try:
adb kill-server
adb start-server
adb devices
```

## Common Solutions

### APK Path Issues
- Clean build directory: `flutter clean`
- Remove build folders manually
- Rebuild: `flutter build apk --debug`

### Device Connection Issues
- Check USB debugging is enabled
- Try different USB cable/port
- Restart ADB: `adb kill-server && adb start-server`
- Check device authorization

### Dart Analysis Issues
- Restart IDE/Editor
- Run `flutter analyze`
- Check for syntax errors
- Verify imports are correct

### Hot Reload Cache Issues
- Use `run_hot_reload_fix.bat`
- Clear app data from device
- Restart development environment

## Files Modified

1. `fix_build_issues.bat` - Comprehensive build fix script
2. `run_hot_reload_fix.bat` - Updated hot reload script
3. `BUILD_TROUBLESHOOTING.md` - This troubleshooting guide

## Next Steps

1. Run `fix_build_issues.bat` to resolve build issues
2. Use `run_hot_reload_fix.bat` for development
3. Check device connection with `flutter devices`
4. If issues persist, try manual clean and rebuild

## Device-Specific Notes

- Device ID `bfa4c29` was hardcoded in original script
- Updated to auto-detect available devices
- Added device validation before running
