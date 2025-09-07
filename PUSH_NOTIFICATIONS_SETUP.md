# Push Notifications Implementation - Setup Guide

## Overview
This implementation adds Firebase Cloud Messaging (FCM) push notifications to the Park Janana Flutter app for shift management, task updates, and announcements.

## Files Added/Modified

### New Files:
1. `lib/services/notification_service.dart` - Core FCM service
2. `lib/services/announcement_service.dart` - Announcement management
3. `lib/screens/settings/notification_settings_screen.dart` - User preferences UI
4. `android/app/src/main/res/values/colors.xml` - Android notification styling
5. `android/app/src/main/res/drawable/ic_notification.xml` - Notification icon

### Modified Files:
1. `pubspec.yaml` - Added firebase_messaging dependency
2. `lib/models/user_model.dart` - Added FCM token and notification preferences
3. `lib/services/shift_service.dart` - Added notification sending on approve/remove
4. `lib/services/task_service.dart` - Added notification sending on assign/update
5. `android/app/src/main/AndroidManifest.xml` - Added FCM permissions and services
6. `ios/Runner/Info.plist` - Added background modes for notifications
7. `lib/main.dart` - Initialize notification service
8. `lib/widgets/user_header.dart` - Added settings navigation

## Setup Required

### 1. Firebase Console Setup
- Enable Firebase Cloud Messaging in Firebase Console
- Download `google-services.json` and place in `android/app/`
- Download `GoogleService-Info.plist` and place in `ios/Runner/`

### 2. Android Configuration
- Add Firebase project configuration
- The AndroidManifest.xml has been pre-configured
- Notification icon and colors are already set up

### 3. iOS Configuration  
- Add Firebase configuration file
- Enable Push Notifications capability in Xcode
- The Info.plist has been pre-configured

### 4. Backend Setup (Required for Production)
For production use, you'll need to implement a backend service to send FCM messages since the Flutter Firebase SDK cannot send messages directly. The notification service includes placeholders for backend API calls.

## Key Features Implemented

### NotificationService Features:
- ✅ FCM token management and storage
- ✅ Permission handling
- ✅ Foreground/background message handling
- ✅ User preference management
- ✅ Topic subscription management
- ✅ Individual user targeting

### Integration Points:
- ✅ Shift approvals/removals trigger notifications
- ✅ Task assignments/updates trigger notifications
- ✅ Announcement broadcasting system
- ✅ User preference settings screen
- ✅ Notification categories: shifts, tasks, announcements

### User Experience:
- ✅ Hebrew UI for notification settings
- ✅ Per-category opt-in/opt-out toggles
- ✅ Accessible via app menu
- ✅ Handles foreground and background scenarios

## Usage Examples

### Send Notification on Shift Approval:
```dart
// Already integrated in ShiftService.approveWorker()
await _notificationService.sendNotificationToUser(
  userId: workerId,
  title: 'אושרת להצטרף למשמרת!',
  body: 'אושרת להצטרפות למשמרת ב$department ב$shiftDate',
  type: 'shift_approved',
  additionalData: {'shiftId': shiftId},
);
```

### Create Announcement:
```dart
final announcementService = AnnouncementService();
await announcementService.createAnnouncement(
  title: 'הודעה חשובה',
  content: 'תוכן ההודעה כאן',
  priority: 'high',
);
```

### Access Settings:
Users can access notification settings via the menu button in the top-right corner of the home screen.

## Testing Notes

1. Notifications require physical devices (not emulators) for full testing
2. FCM tokens are automatically generated and stored when users log in
3. Background notifications work even when app is closed
4. Foreground notifications show as in-app dialogs/snackbars

## Production Considerations

1. Implement backend API for sending FCM messages
2. Add Firebase project configuration files
3. Enable APNs certificates for iOS (for production)
4. Consider implementing notification analytics
5. Add notification sound customization
6. Implement notification scheduling for reminders

## Security Notes

- FCM tokens are securely stored in Firestore
- User preferences are stored locally and in Firestore
- Only authenticated users can send/receive notifications
- Manager permissions should be verified before sending announcements