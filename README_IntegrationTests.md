# 🧪 Integration Tests - Firebase Emulator Testing

Quick guide to run E2E integration tests with Firebase emulators.

## 🚀 Quick Start

### 1. **Prerequisites**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install Flutter dependencies
flutter pub get
```

### 2. **Start Firebase Emulators**

```bash
# Start emulators (separate terminal)
firebase emulators:start
```

### 3. **Run Integration Tests**

```bash
# Run E2E tests (main terminal)
.\scripts\firebase\test-e2e.ps1
```

## 📋 **Available Test Commands**

| Command                                           | Description                           |
| ------------------------------------------------- | ------------------------------------- |
| `.\scripts\firebase\test-e2e.ps1`                 | Run tests (emulators must be running) |
| `.\scripts\firebase\test-e2e.ps1 -StartEmulators` | Start emulators + run tests           |
| `.\scripts\firebase\test-e2e.ps1 -StopEmulators`  | Run tests + stop emulators            |
| `.\scripts\firebase\test-e2e.ps1 -Help`           | Show help                             |

## 🔥 **Firebase Emulator Endpoints**

| Service          | URL                   | Port |
| ---------------- | --------------------- | ---- |
| **Auth**         | http://127.0.0.1:9099 | 9099 |
| **Firestore**    | http://127.0.0.1:8081 | 8081 |
| **Storage**      | http://127.0.0.1:9199 | 9199 |
| **UI Dashboard** | http://127.0.0.1:4000 | 4000 |

## 🧪 **Test Coverage**

### **Current Integration Tests:**

- ✅ **App Launch** - Firebase emulator connection
- ✅ **Authentication Flow** - Login/logout with emulators
- ✅ **Navigation** - UI elements and screen transitions
- ✅ **Error Handling** - Firebase initialization failures
- ✅ **Registration → Approval → Login Flow** - Complete user journey

### **Test Flow Example:**

```
1. User opens app → Welcome screen
2. User registers → Account created (pending approval)
3. User tries login → Blocked (not approved)
4. Admin approves user → Firebase status updated
5. User logs in → Success → Home screen displayed
```

## 🔧 **Manual Testing**

### **Start Emulators Only**

```bash
firebase emulators:start
```

### **View Emulator Data**

- Open http://127.0.0.1:4000
- View Auth users, Firestore collections, Storage files
- Manually create/edit test data

### **Run Specific Test File**

```bash
flutter test integration_test/e2e_firebase_test.dart --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

## 🐛 **Troubleshooting**

### **Emulators Not Starting**

```bash
# Kill existing processes
taskkill /f /im java.exe
firebase emulators:start --only auth,firestore,storage
```

### **Tests Failing to Connect**

```bash
# Check emulator status
curl http://127.0.0.1:9099
curl http://127.0.0.1:8081

# Verify environment variable
echo $env:FIREBASE_EMULATOR_HOST
```

### **Port Already in Use**

```bash
# Find process using port
netstat -ano | findstr :9099
# Kill process
taskkill /pid <PID> /f
```

## 📱 **Device Requirements**

- **Android**: Physical device or emulator running
- **iOS**: iOS Simulator running (macOS only)
- **Web**: Chrome browser available

## ⚡ **Pro Tips**

1. **Keep emulators running** during development for faster test cycles
2. **Check emulator UI** at http://127.0.0.1:4000 to debug test data
3. **Use hot reload** - integration tests work with `flutter run`
4. **Multiple devices** - Run tests on different platforms simultaneously

## 🎯 **Next Steps**

- Add more test scenarios (data persistence, offline behavior)
- Set up CI/CD pipeline with emulator testing
- Create test data fixtures for consistent testing

---

**Happy Testing!** 🚀 Your Firebase emulator setup is production-ready!
