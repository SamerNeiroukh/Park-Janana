# 🚀 Quick Start Guide - Team Development

## One-Command Development Setup

### Windows (PowerShell)

```powershell
# Basic usage (auto-detects everything)
.\dev-start.ps1

# Run on web
.\dev-start.ps1 -Web

# Clean build first
.\dev-start.ps1 -CleanBuild

# Use specific device
.\dev-start.ps1 -Device android

# Force specific IP
.\dev-start.ps1 -ForceIP 192.168.1.5

# Skip emulators (use production Firebase)
.\dev-start.ps1 -NoEmulators
```

## What the Script Does

1. **🔍 Auto-detects your computer's IP address**
2. **🔧 Updates Android network security config automatically**
3. **🔥 Starts Firebase emulators in background**
4. **📱 Shows you available devices (Android, iOS, Web)**
5. **🚀 Launches your app with proper emulator connection**

## Smart Host Detection

The app now intelligently detects the emulator host:

- **Android Emulator (AVD)**: Always uses `10.0.2.2` ✅
- **Physical Android Device**: Uses your computer's IP from the script ✅
- **Web/Desktop/iOS**: Always uses `127.0.0.1` ✅

**No more guessing or hardcoded IP lists!** 🎉

## Configuration (.env file)

Update `.env` to customize for your team/network:

```bash
# Your specific network IP (leave empty for auto-detection)
FIREBASE_EMULATOR_HOST=

# Fallback IPs to try
FALLBACK_IPS=10.0.0.9,192.168.1.2,192.168.0.2

# Auto-start emulators?
AUTO_START_EMULATORS=true

# Project name for logging
PROJECT_NAME=Park Janana
```

## Troubleshooting

### "No devices found"

- Connect Android device with USB debugging
- Start Android emulator
- Or use `--web` flag

### "Emulators failed to start"

- Check if Firebase CLI is installed: `firebase --version`
- Login to Firebase: `firebase login`
- Run manually: `firebase emulators:start`

### "Cleartext HTTP traffic not permitted"

- Script auto-updates network config
- If issues persist, check `android/app/src/main/res/xml/network_security_config.xml`

### Different network/IP issues

- Use `-ForceIP` or `--ip` with your computer's IP
- Update `FIREBASE_EMULATOR_HOST` in `.env`
- Check your IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)

## Team Setup

1. **Clone the repo**
2. **Run the script**: `.\dev-start.ps1` or `./dev-start.sh`
3. **Everything is configured automatically!**

No manual IP configuration needed! 🎉
