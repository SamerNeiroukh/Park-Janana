class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String idNumber;
  final String phoneNumber;
  final String profilePicture;
  final String role;
  final List<String> licensedDepartments; // 🆕 New field
  final String? fcmToken; // 🆕 FCM token for push notifications
  final Map<String, bool> notificationPreferences; // 🆕 Notification preferences

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.idNumber,
    required this.phoneNumber,
    required this.profilePicture,
    required this.role,
    this.licensedDepartments = const [], // Default: not licensed for any department
    this.fcmToken,
    this.notificationPreferences = const {
      'shifts': true,
      'tasks': true,
      'announcements': true,
    }, // Default: all notifications enabled
  });

  Map<String, dynamic> toMap() {
    print("firebase logs: Converting UserModel to Map");
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'profile_picture': profilePicture,
      'role': role,
      'licensedDepartments': licensedDepartments, // 🆕 Save licenses to Firestore
      'fcmToken': fcmToken, // 🆕 Save FCM token
      'notificationPreferences': notificationPreferences, // 🆕 Save notification preferences
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    print("firebase logs: Converting Map to UserModel");
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      idNumber: map['idNumber'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePicture: map['profile_picture'] ?? '',
      role: map['role'] ?? 'worker',
      licensedDepartments: List<String>.from(map['licensedDepartments'] ?? []), // 🆕 Read licenses
      fcmToken: map['fcmToken'], // 🆕 Read FCM token
      notificationPreferences: Map<String, bool>.from(map['notificationPreferences'] ?? {
        'shifts': true,
        'tasks': true,
        'announcements': true,
      }), // 🆕 Read notification preferences
    );
  }
}
