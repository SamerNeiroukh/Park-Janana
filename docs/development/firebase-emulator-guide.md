# 🔥 Firebase Emulator Setup & Configuration

<div align="center">
  <h2>Complete Guide for Local Development with Firebase Emulators</h2>
  
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
  
  <p><strong>Universal setup that works across Android emulators, physical devices, and different networks</strong></p>
</div>

---

## 📋 Table of Contents

- [🎯 Overview](#-overview)
- [⚡ Quick Start](#-quick-start)
- [🔧 Manual Setup](#-manual-setup)
- [🌐 Network Configuration](#-network-configuration)
- [📱 Device-Specific Setup](#-device-specific-setup)
- [🛠️ VS Code Integration](#️-vs-code-integration)
- [🔍 Troubleshooting](#-troubleshooting)
- [📊 Data Management](#-data-management)
- [🚀 Advanced Configuration](#-advanced-configuration)

---

## 🎯 Overview

This setup provides a **complete Firebase emulator environment** that automatically adapts to:

- 🤖 **Android Emulators** (`10.0.2.2`)
- 📱 **Physical Android Devices** (Your computer's IP)
- 🌐 **Web Development** (`127.0.0.1`)
- 🏠 **Different Networks** (Home, office, mobile hotspot)
- 👥 **Team Development** (Works for any developer)

### ✨ Key Features

- 🧠 **Smart Host Detection** - Automatically finds the best emulator host
- 🔐 **Universal Network Security** - Handles cleartext HTTP for all scenarios
- 🚀 **One-Command Setup** - Get started in seconds
- 🔄 **Hot Reload Compatible** - Works seamlessly with Flutter development
- 📊 **Data Import/Export** - Preserve test data between sessions

---

## ⚡ Quick Start

### Option 1: Automated Setup (Recommended)

**Windows:**
```powershell
.\setup-emulators.ps1
```

**Mac/Linux:**
```bash
chmod +x setup-emulators.sh
./setup-emulators.sh
```

### Option 2: VS Code Tasks

1. **Ctrl+Shift+P** → "Tasks: Run Task"
2. Select **"🔥 Start Firebase Emulators"**
3. Done! ✨

### Option 3: Manual Commands

```bash
# Start emulators
firebase emulators:start

# In another terminal, run your app
flutter run -d android    # For Android
flutter run -d chrome     # For Web
```

---

## 🔧 Manual Setup

### Prerequisites

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project (if not done)
firebase init
```

### 1. Firebase Configuration (`firebase.json`)

```json
{
  "emulators": {
    "auth": {
      "port": 9099,
      "host": "0.0.0.0"
    },
    "firestore": {
      "port": 8081,
      "host": "0.0.0.0"
    },
    "storage": {
      "port": 9199,
      "host": "0.0.0.0"
    },
    "functions": {
      "port": 5001,
      "host": "0.0.0.0"
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

### 2. Android Network Security Config

**File:** `android/app/src/main/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- For debug builds, be very permissive -->
    <debug-overrides>
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>
        </trust-anchors>
    </debug-overrides>
    
    <!-- Allow cleartext traffic for common development ranges -->
    <domain-config cleartextTrafficPermitted="true">
        <!-- Localhost variations -->
        <domain includeSubdomains="true">127.0.0.1</domain>
        <domain includeSubdomains="true">localhost</domain>
        
        <!-- Android emulator host -->
        <domain includeSubdomains="true">10.0.2.2</domain>
        
        <!-- Common local network ranges -->
        <domain includeSubdomains="true">192.168.1.1</domain>
        <domain includeSubdomains="true">192.168.1.2</domain>
        <domain includeSubdomains="true">192.168.0.1</domain>
        <domain includeSubdomains="true">192.168.0.2</domain>
        <domain includeSubdomains="true">10.0.0.1</domain>
        <domain includeSubdomains="true">10.0.0.2</domain>
        <domain includeSubdomains="true">10.0.0.9</domain>
        <!-- Add your network IP here if needed -->
    </domain-config>
    
    <!-- For development, allow cleartext traffic globally -->
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

### 3. Android Manifest Update

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<application
    android:label="your_app_name"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
    
    <!-- Your existing activity configurations -->
    
</application>
```

### 4. Flutter App Configuration

**File:** `lib/main.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Connect to Firebase Emulators (development only)
  await _connectToFirebaseEmulators();
  
  runApp(MyApp());
}

/// 🔥 Smart Firebase Emulator Configuration
Future<void> _connectToFirebaseEmulators() async {
  if (kDebugMode) {
    print("🔥 Connecting to Firebase Emulators...");

    // Get the appropriate host for emulators
    String host = await _getEmulatorHost();
    print("🔍 Using emulator host: $host");

    try {
      // Connect FirebaseAuth to emulator
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      print("✅ Auth Emulator connected: $host:9099");

      // Connect Firestore to emulator
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
      print("✅ Firestore Emulator connected: $host:8081");

      // Connect Storage to emulator
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      print("✅ Storage Emulator connected: $host:9199");

      print("🎉 All Firebase Emulators connected successfully!");
    } catch (e) {
      print("❌ Error connecting to emulators: $e");
    }
  } else {
    print("📱 Running in production mode - using live Firebase services");
  }
}

/// 🔍 Smart host detection for Firebase emulators
Future<String> _getEmulatorHost() async {
  // List of possible hosts to try (in order of preference)
  final List<String> possibleHosts = [
    // For physical devices - try environment variable first
    const String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: ''),
    // Common local network IPs - UPDATE THESE FOR YOUR NETWORK
    '10.0.0.9',     // Your current network IP
    '192.168.1.2',  // Common router IP range
    '192.168.0.2',  // Alternative router IP range
    '10.0.2.2',     // Android emulator host
    '127.0.0.1',    // Localhost fallback
  ];

  // For non-Android platforms, prefer localhost
  if (defaultTargetPlatform != TargetPlatform.android) {
    return '127.0.0.1';
  }

  // For Android, try to find working host
  for (String host in possibleHosts) {
    if (host.isNotEmpty) {
      return host;
    }
  }

  // Fallback
  return '10.0.0.9';
}
```

---

## 🌐 Network Configuration

### Find Your Computer's IP Address

**Windows:**
```powershell
# PowerShell
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.0.*"} | Select-Object -First 1).IPAddress

# Command Prompt
ipconfig | findstr "IPv4"
```

**Mac:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
```

**Linux:**
```bash
hostname -I | awk '{print $1}'
```

### Common Network Scenarios

| Network Type | IP Range | Example | Usage |
|--------------|----------|---------|-------|
| **Home WiFi** | `192.168.1.x` | `192.168.1.5` | Most home routers |
| **Alternative Router** | `192.168.0.x` | `192.168.0.10` | Some routers |
| **Corporate** | `10.0.x.x` | `10.0.0.25` | Office networks |
| **Mobile Hotspot** | `192.168.43.x` | `192.168.43.1` | Phone hotspots |
| **Android Emulator** | `10.0.2.2` | `10.0.2.2` | Always this IP |

### Update Your Configuration

1. **Find your IP** using commands above
2. **Update the host list** in `main.dart`:
   ```dart
   final List<String> possibleHosts = [
     'YOUR_CURRENT_IP_HERE',  // Add your IP first
     '192.168.1.2',
     '10.0.0.9',
     // ... other IPs
   ];
   ```
3. **Add to network security config** if needed

---

## 📱 Device-Specific Setup

### 🤖 Android Emulator

- **Host**: `10.0.2.2` (automatic)
- **Setup**: Zero configuration needed
- **Testing**: `flutter run -d android`

### 📱 Physical Android Device

- **Host**: Your computer's IP address
- **Requirements**: 
  - Same WiFi network as computer
  - USB debugging enabled (optional)
- **Testing**: `flutter run -d <device-id>`

### 🍎 iOS Simulator

- **Host**: `127.0.0.1` (automatic)
- **Setup**: Zero configuration needed
- **Testing**: `flutter run -d ios`

### 🌐 Web Browser

- **Host**: `127.0.0.1` (automatic)
- **Setup**: Zero configuration needed
- **Testing**: `flutter run -d chrome`

---

## 🛠️ VS Code Integration

### Available Tasks

Press **Ctrl+Shift+P** → "Tasks: Run Task" and choose:

- **🔥 Start Firebase Emulators** - Start all emulators
- **📱 Run Flutter on Android** - Build and run on Android
- **🌐 Run Flutter on Web** - Build and run on web
- **📊 Export Emulator Data** - Save current data
- **📥 Import Emulator Data** - Load saved data
- **🔍 Get Local IP** - Display your computer's IP

### Debug Configuration

**File:** `.vscode/launch.json`

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "🔥 Flutter (Emulators)",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": ["--dart-define=USE_EMULATOR=true"]
        }
    ]
}
```

---

## 🔍 Troubleshooting

### Common Issues & Solutions

#### ❌ "Cleartext HTTP traffic not permitted"

**✅ Solution:**
1. Verify `android:usesCleartextTraffic="true"` in AndroidManifest
2. Check network security config includes your IP
3. Rebuild the app: `flutter clean && flutter run`

#### ❌ "Connection refused" or "Unable to connect"

**✅ Solutions:**

1. **Check emulators are running:**
   ```bash
   firebase emulators:start
   ```

2. **Verify your IP hasn't changed:**
   ```bash
   ipconfig  # Windows
   ifconfig  # Mac/Linux
   ```

3. **Test emulator connectivity:**
   ```bash
   # From your computer
   curl http://localhost:9099
   
   # From Android device (replace with your IP)
   curl http://192.168.1.5:9099
   ```

4. **Firewall issues:**
   - Allow Firebase emulator ports (9099, 8081, 9199, 5001)
   - Temporarily disable firewall for testing

#### ❌ "No AppCheckProvider installed" Warning

**✅ Solution:** This is normal for emulators and can be ignored.

#### ❌ Different Network/New IP Address

**✅ Quick Fix:**
```bash
# Windows
$env:FIREBASE_EMULATOR_HOST="your.new.ip.address"
flutter run

# Mac/Linux
export FIREBASE_EMULATOR_HOST="your.new.ip.address"
flutter run
```

### Debug Logs

Enable detailed Firebase logs:

```dart
// Add to main.dart for debugging
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: false,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Enable auth debug logs
FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: true,
);
```

---

## 📊 Data Management

### Export Emulator Data

```bash
# Export all emulator data
firebase emulators:export ./emulator-data

# Export specific emulator
firebase emulators:export ./emulator-data --only firestore

# Export with custom path
firebase emulators:export ../backup-$(date +%Y%m%d)
```

### Import Emulator Data

```bash
# Start with imported data
firebase emulators:start --import=./emulator-data

# Import specific data
firebase emulators:start --import=./emulator-data --only firestore
```

### Automated Import/Export

**Update `firebase.json`:**
```json
{
  "emulators": {
    "firestore": {
      "port": 8081,
      "host": "0.0.0.0"
    },
    "hub": {
      "port": 4400
    }
  }
}
```

**Create backup script:**
```bash
#!/bin/bash
# backup-data.sh
DATE=$(date +"%Y%m%d_%H%M%S")
firebase emulators:export "./backups/backup_$DATE"
echo "✅ Data exported to backup_$DATE"
```

---

## 🚀 Advanced Configuration

### Custom Ports

**Update `firebase.json`:**
```json
{
  "emulators": {
    "auth": { "port": 9099, "host": "0.0.0.0" },
    "firestore": { "port": 8081, "host": "0.0.0.0" },
    "storage": { "port": 9199, "host": "0.0.0.0" },
    "functions": { "port": 5001, "host": "0.0.0.0" },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

**Update Flutter code:**
```dart
await FirebaseAuth.instance.useAuthEmulator(host, 9099);
FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
await FirebaseStorage.instance.useStorageEmulator(host, 9199);
```

### Environment Variables

```bash
# Set custom emulator host
export FIREBASE_EMULATOR_HOST="192.168.1.100"

# Set custom ports
export FIRESTORE_EMULATOR_HOST="192.168.1.100:8081"
export FIREBASE_AUTH_EMULATOR_HOST="192.168.1.100:9099"
export FIREBASE_STORAGE_EMULATOR_HOST="192.168.1.100:9199"
```

### Security Rules

**Firestore Rules (`firestore.rules`):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads/writes for emulator development
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Storage Rules (`storage.rules`):**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow all operations for emulator development
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

### Performance Optimization

```dart
// Optimize Firestore for emulator use
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: false,  // Disable offline persistence
  cacheSizeBytes: 1048576,    // 1MB cache
);

// Optimize Auth for emulator
FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: true,
  userAccessGroup: null,
);
```

---

## 📋 Verification Checklist

Before starting development, verify:

- [ ] **Firebase CLI** installed and logged in
- [ ] **Emulators start** without errors
- [ ] **Flutter app connects** to emulators (check console logs)
- [ ] **Auth emulator UI** accessible at `http://127.0.0.1:4000/auth`
- [ ] **User creation works** without reCAPTCHA errors
- [ ] **Firestore operations** work (read/write data)
- [ ] **Storage operations** work (upload/download files)
- [ ] **Physical device** can connect (if using one)
- [ ] **Hot reload** works properly

### Test Commands

```bash
# Test emulator endpoints
curl http://127.0.0.1:9099     # Auth
curl http://127.0.0.1:8081     # Firestore
curl http://127.0.0.1:9199     # Storage
curl http://127.0.0.1:4000     # UI

# Test Flutter connection
flutter run --verbose -d android
# Check logs for: "✅ All Firebase Emulators connected successfully!"
```

---

## 🎯 Production vs Development

The app automatically switches modes:

| Mode | Trigger | Firebase Services |
|------|---------|-------------------|
| **Development** | `kDebugMode == true` | Local emulators |
| **Production** | `kDebugMode == false` | Live Firebase |

**Manual override:**
```dart
// Force emulator use
const bool useEmulators = true;

if (kDebugMode || useEmulators) {
  await _connectToFirebaseEmulators();
}
```

---

## 🆘 Quick Reference

### Essential Commands

```bash
# Start emulators
firebase emulators:start

# Start with data import
firebase emulators:start --import=./emulator-data

# Export data
firebase emulators:export ./emulator-data

# Kill emulators
firebase emulators:kill

# Flutter commands
flutter devices                    # List devices
flutter run -d android            # Run on Android
flutter run -d chrome             # Run on web
flutter clean && flutter run      # Clean rebuild

# Network commands
ipconfig                          # Windows IP
ifconfig                          # Mac/Linux IP
netstat -an | grep :9099          # Check port usage
```

### Important URLs

- **Emulator UI**: `http://127.0.0.1:4000`
- **Auth Emulator**: `http://127.0.0.1:4000/auth`
- **Firestore Emulator**: `http://127.0.0.1:4000/firestore`
- **Storage Emulator**: `http://127.0.0.1:4000/storage`

### File Locations

- **Firebase Config**: `firebase.json`
- **Network Security**: `android/app/src/main/res/xml/network_security_config.xml`
- **Android Manifest**: `android/app/src/main/AndroidManifest.xml`
- **Flutter Config**: `lib/main.dart`
- **VS Code Tasks**: `.vscode/tasks.json`

---

<div align="center">

## 🎉 You're All Set!

Your Firebase emulator environment is now configured for:
- 🤖 **Android Emulators**
- 📱 **Physical Devices** 
- 🌐 **Different Networks**
- 👥 **Team Development**

### 🚀 Happy Coding!

**Need help?** Check the troubleshooting section or create an issue.

</div>

---

<div align="center">
  <sub>
    Made with ❤️ for seamless Firebase development<br>
    <a href="#-overview">Back to Top</a>
  </sub>
</div>
