# Running ScholaTransit Parent App on WSL

## “Dart compiler exited unexpectedly” / “Failed to compile”

This often happens on WSL when the Dart compiler runs out of memory. Do the following.

### 1. Give WSL more memory (recommended)

On **Windows** (not inside WSL):

1. Create or edit: `C:\Users\<YourWindowsUsername>\.wslconfig`
2. Set for example:

   ```ini
   [wsl2]
   memory=4GB
   swap=16GB
   localhostForwarding=true
   ```

3. In **PowerShell (Admin)** or **CMD (Admin)** run:

   ```text
   wsl --shutdown
   ```

4. Start WSL again (e.g. open your Ubuntu terminal). Then in the project:

   ```bash
   cd ~/Projects/cortexgrid/scholatransit_parent_app
   flutter clean && flutter pub get
   flutter run -d chrome
   ```

(Use `flutter run -d linux` if you prefer the Linux desktop build.)

### 2. Use Chrome in the same terminal

For web, set Chrome **in the same terminal** before running Flutter:

```bash
export CHROME_EXECUTABLE="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
flutter run -d chrome
```

### 3. Free memory before building

Close other heavy apps (browsers, IDEs, etc.) and avoid running multiple `flutter run` or `flutter build` at once.

---

## Option 1: Linux desktop (after installing deps)

The app uses **audioplayers_linux**, which needs **GStreamer** and GTK. Install once:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config \
  libgtk-3-dev libglib2.0-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  liblzma-dev libstdc++-12-dev
```

Then from the project root:

```bash
flutter pub get
flutter run -d linux
```

---

## Option 2: Chrome (web) – no extra packages

Use Windows Chrome from WSL. In the **same terminal** where you run Flutter:

```bash
# Point to Windows Chrome (adjust path if Chrome is elsewhere)
export CHROME_EXECUTABLE="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# If you use 64-bit Chrome in "Program Files (x86)":
# export CHROME_EXECUTABLE="/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"

flutter pub get
flutter run -d chrome
```

To make Chrome the default for this project, add the `export` line to your `~/.bashrc`.

To find Chrome on Windows (from WSL):

```bash
ls "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" 2>/dev/null && echo "Found in Program Files"
ls "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" 2>/dev/null && echo "Found in Program Files (x86)"
```

---

## Summary

| Goal              | Command / step |
|-------------------|----------------|
| Linux app         | Install GStreamer/GTK packages above, then `flutter run -d linux` |
| Web (Chrome)      | `export CHROME_EXECUTABLE="..."` then `flutter run -d chrome` |
