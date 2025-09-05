# Park Janana Management App
A Flutter mobile application for park staff management, shift scheduling, task tracking, and reporting at Park Janana recreational park in Jerusalem. Built with Flutter frontend and Firebase backend (Firestore, Auth, Cloud Functions).

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites Installation
- **CRITICAL NOTE**: Flutter SDK installation may fail in restricted network environments due to Dart SDK download issues.
- Install Flutter SDK:
  ```bash
  # Download Flutter SDK
  sudo git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
  
  # Add to PATH (add to ~/.bashrc for persistence)
  export PATH="/opt/flutter/bin:$PATH"
  
  # Verify installation - MAY FAIL due to network restrictions
  flutter --version  # May fail with "corrupt zipfile" error due to firewall limitations
  ```
- Install required system dependencies:
  ```bash
  sudo apt update
  sudo apt install -y git curl unzip xz-utils zip libglu1-mesa openjdk-17-jdk
  ```
- **ALTERNATIVE**: If Flutter installation fails due to network restrictions:
  ```bash
  # Document the limitation and work with static analysis
  echo "Flutter SDK installation blocked by network restrictions"
  echo "Can analyze project structure but cannot build/run application"
  ```

### Bootstrap, Build, and Test the Repository
- **NEVER CANCEL: All build operations can take 15-45 minutes. Set timeout to 60+ minutes.**
- **NETWORK LIMITATION**: Commands may fail due to firewall restrictions blocking Flutter/Dart SDK downloads.
- Install dependencies:
  ```bash
  cd /home/runner/work/Park-Janana/Park-Janana
  flutter pub get  # Takes 2-5 minutes. NEVER CANCEL. May fail due to network restrictions.
  ```
- Check Flutter doctor:
  ```bash
  flutter doctor  # Takes 1-2 minutes. NEVER CANCEL. May fail if Dart SDK download blocked.
  ```
- Build the application:
  ```bash
  # Android APK build
  flutter build apk --release  # Takes 20-30 minutes. NEVER CANCEL. Set timeout to 45+ minutes.
  
  # Web build  
  flutter build web  # Takes 10-15 minutes. NEVER CANCEL. Set timeout to 30+ minutes.
  ```
- Run tests:
  ```bash
  flutter test  # Takes 2-5 minutes. NEVER CANCEL. Set timeout to 10+ minutes.
  ```
- Run analysis and linting:
  ```bash
  flutter analyze  # Takes 1-2 minutes. NEVER CANCEL.
  dart format --set-exit-if-changed .  # Code formatting check
  ```
- **FALLBACK**: If Flutter commands fail due to network restrictions:
  ```bash
  # Use static analysis tools available in the environment
  find lib/ -name "*.dart" | wc -l  # Count Dart files
  grep -r "TODO\|FIXME\|HACK" lib/  # Find code issues  
  find . -name "pubspec.yaml" -exec cat {} \;  # Check dependencies
  ```

### Run the Application
- **ALWAYS run the bootstrapping steps first (flutter pub get).**
- Run in debug mode:
  ```bash
  # For web (Chrome required but not available in this environment)
  flutter run -d web-server --web-port 8080  # Takes 5-10 minutes initial build. NEVER CANCEL.
  
  # Note: Physical devices or emulators not available in this environment
  # Use flutter run -d android for Android emulator if available
  ```

## Validation

### Manual Validation Requirements
- **ALWAYS manually validate any new code changes by running through complete user scenarios.**
- **CRITICAL**: After making changes, ALWAYS run `flutter analyze` and `flutter test` before committing.
- **SCENARIO VALIDATION**: Test these key user workflows after making changes:
  1. **Authentication Flow**: User registration → login → role assignment
  2. **Shift Management**: Worker requests shift → Manager approves/rejects → Worker sees updated status
  3. **Task Assignment**: Manager creates task → Worker receives task → Worker marks complete
  4. **Attendance Tracking**: Worker clocks in → performs work → clocks out → View attendance summary
  5. **Reporting**: Generate PDF reports → Verify data accuracy and formatting

### Build and Test Validation
- Always run the complete validation suite:
  ```bash
  # Full validation pipeline - NEVER CANCEL any of these steps
  flutter clean                    # Takes 30 seconds
  flutter pub get                  # Takes 2-5 minutes
  flutter analyze                  # Takes 1-2 minutes  
  flutter test                     # Takes 2-5 minutes
  flutter build web --release      # Takes 10-15 minutes
  ```

## Common Tasks

The following are outputs from frequently run commands. Reference them instead of viewing, searching, or running bash commands to save time.

### Repo Root Structure
```bash
ls -la
```
```
total 112
drwxr-xr-x 14 runner docker  4096 Sep  5 21:58 .
drwxr-xr-x  3 runner docker  4096 Sep  5 21:54 ..
drwxr-xr-x  7 runner docker  4096 Sep  5 21:57 .git
drwxr-xr-x  2 runner docker  4096 Sep  5 21:59 .github
-rw-r--r--  1 runner docker   874 Sep  5 21:54 .gitignore
-rw-r--r--  1 runner docker  1706 Sep  5 21:54 .metadata
drwxr-xr-x  2 runner docker  4096 Sep  5 21:54 .vscode
-rw-r--r--  1 runner docker  5673 Sep  5 21:54 README.md
-rw-r--r--  1 runner docker  1420 Sep  5 21:54 analysis_options.yaml
drwxr-xr-x  4 runner docker  4096 Sep  5 21:54 android
drwxr-xr-x  5 runner docker  4096 Sep  5 21:54 assets
drwxr-xr-x  7 runner docker  4096 Sep  5 21:54 ios
drwxr-xr-x  9 runner docker  4096 Sep  5 21:54 lib
drwxr-xr-x  3 runner docker  4096 Sep  5 21:54 linux
drwxr-xr-x  7 runner docker  4096 Sep  5 21:54 macos
-rw-r--r--  1 runner docker 30478 Sep  5 21:54 pubspec.lock
-rw-r--r--  1 runner docker  3248 Sep  5 21:54 pubspec.yaml
drwxr-xr-x  2 runner docker  4096 Sep  5 21:54 test
drwxr-xr-x  3 runner docker  4096 Sep  5 21:54 web
drwxr-xr-x  4 runner docker  4096 Sep  5 21:54 windows
```

### Project Statistics
```bash
find lib/ -name "*.dart" | wc -l
```
```
68  # Total Dart files in project
```

### Role Configuration
```bash
cat lib/config/roles.json
```
```json
{
    "roles": {
      "owner": {
        "permissions": [
          "manage_users",
          "view_reports", 
          "crud_shifts",
          "override_tasks",
          "resolve_conflicts"
        ],
        "dashboard": "OwnerDashboard"
      },
      "department_manager": {
        "permissions": [
          "crud_shifts",
          "assign_tasks",
          "view_reports",
          "resolve_conflicts"
        ],
        "dashboard": "DepartmentManagerDashboard"
      },
      "shift_manager": {
        "permissions": [
          "monitor_tasks",
          "report_issues"
        ],
        "dashboard": "ShiftManagerDashboard"
      },
      "worker": {
        "permissions": [
          "view_tasks",
          "complete_tasks"
        ],
        "dashboard": "WorkerDashboard"
      }
    }
}
```

### Assets Overview
```bash
find assets/ -type f
```
```
assets/fonts/NotoSansHebrew-Regular.ttf  # Hebrew font support
assets/fonts/SuezOne-Regular.ttf         # Custom font
assets/images/park_logo.png              # App logo
assets/images/team_image.jpg             # Team/park image
assets/images/colors.png                 # Color reference
assets/images/default_profile.png        # Default user avatar
assets/gifs/sand_watch1.gif             # Loading animation
assets/gifs/sand_watch.gif              # Alternative loading animation
```

### Testing Structure
```bash
find test/ -name "*.dart"
```
```
test/widget_test.dart  # Basic widget test (needs updating for app-specific tests)
```

**NOTE**: The default widget test needs to be updated to reflect actual app functionality instead of counter increments.

### Project Structure Overview
```
lib/
├── config/           # Configuration files (roles.json)
├── constants/        # App constants, colors, strings, themes
├── main.dart        # Application entry point
├── models/          # Data models (User, Shift, Task, Attendance)
├── screens/         # UI screens organized by feature
│   ├── auth/        # Authentication screens
│   ├── home/        # Dashboard screens
│   ├── shifts/      # Shift management
│   ├── tasks/       # Task management
│   └── reports/     # Reporting screens
├── services/        # Business logic and Firebase integration
├── utils/           # Utility functions
└── widgets/         # Reusable UI components
```

### Key Files and Their Purpose
- `lib/main.dart` - Application entry point with Firebase initialization
- `lib/services/firebase_service.dart` - Core Firebase operations
- `lib/services/auth_service.dart` - Authentication management
- `lib/config/roles.json` - Role-based permission configuration
- `lib/constants/app_constants.dart` - Firebase collection names and asset paths
- `pubspec.yaml` - Flutter dependencies and project configuration
- `analysis_options.yaml` - Dart analysis and linting rules

### Firebase Collections Structure
- `users` - User profiles with role-based permissions
- `shifts` - Shift scheduling and worker assignments
- `tasks` - Task assignment and completion tracking
- `attendance` - Clock in/out records and time tracking

### Role-Based Permission System
- **Worker**: View tasks, complete tasks, clock in/out, request shifts
- **Shift Manager**: Monitor tasks, report issues, approve worker requests
- **Department Manager**: CRUD shifts, assign tasks, view reports, resolve conflicts
- **Owner**: Full system access, manage users, view all analytics

### Common Commands Reference
```bash
# Development workflow
flutter pub get                          # Install dependencies
flutter run -d web-server --web-port 8080  # Run development server
flutter hot-reload                       # Hot reload (press 'r' in terminal)
flutter hot-restart                      # Hot restart (press 'R' in terminal)

# Building
flutter build apk --debug               # Debug Android build
flutter build apk --release             # Release Android build  
flutter build web --release             # Production web build

# Testing and validation
flutter test                            # Run unit tests
flutter analyze                         # Static analysis
dart format --set-exit-if-changed .     # Format code
flutter clean                           # Clean build artifacts

# Dependency management
flutter pub get                         # Install dependencies
flutter pub upgrade                     # Upgrade dependencies
flutter pub deps                        # Show dependency tree
```

### Firebase Setup Requirements
- Project requires Firebase configuration files:
  - `android/app/google-services.json` (for Android)
  - `ios/Runner/GoogleService-Info.plist` (for iOS) 
  - Firebase project must have Authentication, Firestore, and Storage enabled
- **NOTE**: Firebase config files are typically not committed to repository for security

### Troubleshooting Common Issues
- **Build failures**: Run `flutter clean && flutter pub get` before rebuilding
- **Dependency conflicts**: Check `pubspec.yaml` for version conflicts
- **Firebase connection issues**: Verify Firebase config files are present and valid
- **Analysis errors**: Run `dart format .` to fix formatting issues
- **Missing dependencies**: Run `flutter doctor` to check for missing SDK components

### Development Environment Notes
- **CRITICAL**: This environment may have network restrictions affecting:
  - Firebase SDK downloads during initial setup
  - Package downloads from pub.dev
  - If flutter commands fail with network errors, document the limitation
- **UI Testing**: Cannot interact with actual device UI, but can validate builds complete successfully
- **Web Testing**: Limited browser access, use `flutter run -d web-server` for headless testing

### Performance Expectations
- **Initial `flutter pub get`**: 2-5 minutes
- **First build**: 20-30 minutes (downloads and compiles dependencies)
- **Subsequent builds**: 5-10 minutes
- **Hot reload**: 1-3 seconds
- **Tests**: 2-5 minutes for full suite
- **Analysis**: 1-2 minutes

### Code Style and Standards
- Follow Dart/Flutter official style guide
- Use `dart format .` for consistent formatting  
- Address all warnings from `flutter analyze`
- Use meaningful variable and function names in English
- Add comments for complex business logic
- Maintain consistent file structure within feature directories

### Multi-language Support
- App supports Hebrew, Arabic, and English
- Use `flutter_localizations` for internationalization
- Text direction handled automatically for RTL languages
- Test UI layout with different language directions

Always check `lib/services/firebase_service.dart` and related service files after making changes to data models or Firebase operations.