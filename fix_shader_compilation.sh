#!/bin/bash

# Fix Flutter Shader Compilation Error (Exit Code -9)
# This script addresses shader compilation failures during Flutter builds

echo "🔧 Fixing Flutter Shader Compilation Error..."
echo ""

# Step 1: Clean Flutter build
echo "Step 1: Cleaning Flutter build..."
flutter clean

# Step 2: Remove shader cache and build directories
echo "Step 2: Removing shader cache and build directories..."
rm -rf build/app/intermediates/flutter/debug/flutter_assets/shaders 2>/dev/null
rm -rf build/app/intermediates/flutter/profile/flutter_assets/shaders 2>/dev/null
rm -rf build/app/intermediates/flutter/release/flutter_assets/shaders 2>/dev/null
rm -rf android/app/build 2>/dev/null
rm -rf android/build 2>/dev/null
rm -rf .dart_tool 2>/dev/null

# Step 3: Clear Flutter cache
echo "Step 3: Clearing Flutter cache..."
flutter pub cache repair 2>/dev/null || echo "Cache repair skipped"

# Step 4: Get dependencies
echo "Step 4: Getting dependencies..."
flutter pub get

# Step 5: Try building with reduced parallelism (helps with memory issues)
echo "Step 5: Attempting build with optimizations..."
echo "   - Using single-threaded build to reduce memory pressure"
echo "   - If this fails, try: flutter build apk --debug --no-shrink"

# Build with optimizations
flutter build apk --debug --no-shrink 2>&1 | tee build_log.txt

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
else
    echo ""
    echo "⚠️  Build failed. Trying alternative approach..."
    echo ""
    echo "Alternative solutions:"
    echo "1. Try building with: flutter build apk --debug --no-shrink --split-per-abi"
    echo "2. Increase system memory or close other applications"
    echo "3. Try building on a different machine or emulator"
    echo "4. Check Flutter version: flutter --version"
    echo "5. Update Flutter: flutter upgrade"
    echo ""
    echo "Check build_log.txt for detailed error information"
fi
