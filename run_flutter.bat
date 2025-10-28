@echo off
set GRADLE_OPTS=-Dorg.gradle.daemon=false -Dorg.gradle.timeout=300000 -Dorg.gradle.internal.http.connectionTimeout=300000 -Dorg.gradle.internal.http.socketTimeout=300000
set JAVA_OPTS=-Xmx4G -XX:MaxMetaspaceSize=2G
REM Force debug, disable build caching quirks, and ensure incremental compiler consistency
set FLUTTER_ENGINE_SWITCHES=--enable-impeller=false

REM Kill stray gradle daemons to avoid stale artifacts
taskkill /f /im java.exe 2>nul

REM Light clean for hot reload (use run_fresh.bat if changes don't show)
flutter clean
flutter pub get
flutter run -d bfa4c29 --debug --no-fast-start --hot
