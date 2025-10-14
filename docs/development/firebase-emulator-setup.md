# 🔥 Firebase Emulator Setup Guide

This guide will help you set up Firebase emulators for development across different environments (Android emulator, physical devices, different networks).

## 📋 Prerequisites

1. **Firebase CLI** installed: `npm install -g firebase-tools`
2. **Java 11+** for Firebase emulators
3. **Flutter** development environment set up

## 🔧 Quick Setup

### 1. Start Firebase Emulators

```bash
# In your project root
firebase emulators:start
```

The emulators will start with these default ports:
- **Auth**: `0.0.0.0:9099`
- **Firestore**: `0.0.0.0:8081`
- **Storage**: `0.0.0.0:9199`
- **Functions**: `0.0.0.0:5001`
- **UI**: `127.0.0.1:4000`

### 2. Run Your Flutter App

```bash
# For Android emulator
flutter run -d android

# For physical device
flutter run -d <device-id>

# For web
flutter run -d chrome
```

## 🌐 Network Configuration

### For Different Network Environments

1. **Find Your Computer's IP Address**:
   ```bash
   # Windows
   ipconfig
   
   # macOS/Linux
   ifconfig
   ```

2. **Update the Host Detection** (already configured in main.dart):
   - The app automatically detects the best host to use
   - You can override by setting environment variable: `FIREBASE_EMULATOR_HOST=your.ip.address`

3. **Common Network Scenarios**:

   | Scenario | Typical IP Range | Example |
   |----------|------------------|---------|
   | Home WiFi Router | `192.168.1.x` | `192.168.1.2` |
   | Alternative Router | `192.168.0.x` | `192.168.0.2` |
   | Corporate Network | `10.0.x.x` | `10.0.0.9` |
   | Android Emulator | `10.0.2.2` | `10.0.2.2` |
   | Localhost | `127.0.0.1` | `127.0.0.1` |

## 📱 Device-Specific Setup

### Android Emulator
- Uses `10.0.2.2` to access host machine
- No additional network config needed

### Physical Android Device
- Uses your computer's actual IP address on the network
- Make sure device and computer are on the same WiFi network
- Network security config automatically handles cleartext HTTP

### iOS Simulator/Device
- Uses `127.0.0.1` (localhost)
- No additional config needed

### Web (Chrome/Edge)
- Uses `127.0.0.1` (localhost)
- No additional config needed

## 🔧 Troubleshooting

### 1. "Cleartext HTTP traffic not permitted" Error

✅ **Already Fixed**: The network security config is pre-configured to handle this.

### 2. "Connection Refused" Error

**Solutions**:
1. Check if emulators are running: `firebase emulators:start`
2. Verify your computer's IP address hasn't changed
3. Ensure device and computer are on same network

### 3. Different Network/IP Address

**Quick Fix**:
1. Find your new IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Set environment variable:
   ```bash
   # Windows PowerShell
   $env:FIREBASE_EMULATOR_HOST="your.new.ip.address"
   flutter run
   
   # Mac/Linux
   export FIREBASE_EMULATOR_HOST="your.new.ip.address"
   flutter run
   ```

### 4. Adding New IP Addresses

If you frequently use different networks, add the IP to the network security config:

1. Edit `android/app/src/main/res/xml/network_security_config.xml`
2. Add your IP in the `<domain-config>` section:
   ```xml
   <domain includeSubdomains="true">your.new.ip.address</domain>
   ```

## 🚀 Advanced Configuration

### Custom Emulator Ports

Edit `firebase.json` to change ports:
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
    }
  }
}
```

### Environment-Specific Hosts

You can set different hosts per environment:

```bash
# Development
export FIREBASE_EMULATOR_HOST="192.168.1.2"

# Testing on different network
export FIREBASE_EMULATOR_HOST="10.0.0.15"

# Then run your app
flutter run
```

## 📊 Data Import/Export

### Export Data
```bash
# Export all data
firebase emulators:export ./emulator-data

# Export specific emulator
firebase emulators:export ./emulator-data --only firestore
```

### Import Data
```bash
# Import on startup
firebase emulators:start --import=./emulator-data

# Or in firebase.json
{
  "emulators": {
    "firestore": {
      "port": 8081,
      "host": "0.0.0.0"
    }
  }
}
```

## ✅ Verification Checklist

- [ ] Firebase emulators start successfully
- [ ] App connects to emulators (check console logs)
- [ ] Auth emulator UI accessible at `http://your-ip:4000`
- [ ] User creation works without reCAPTCHA errors
- [ ] Firestore operations work
- [ ] Storage operations work

## 🎯 Production vs Development

The app automatically switches between emulators (debug mode) and production Firebase:

- **Debug Mode**: Uses emulators
- **Release Mode**: Uses production Firebase

This is controlled by `kDebugMode` in `main.dart`.

---

## 🆘 Quick Help Commands

```bash
# Check Firebase CLI version
firebase --version

# List available emulators
firebase emulators:start --help

# Check Flutter devices
flutter devices

# Check app logs
flutter logs
```

Happy coding! 🚀
