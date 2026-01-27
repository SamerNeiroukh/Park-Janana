class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String idNumber;
  final String phoneNumber;

  /// Legacy (download URL) – kept for backward compatibility
  final String profilePicture;

  /// NEW: Firebase Storage path (preferred)
  final String? profilePicturePath;

  final String role;
  final List<String> licensedDepartments;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.idNumber,
    required this.phoneNumber,
    required this.profilePicture,
    this.profilePicturePath, // ✅ NEW
    required this.role,
    this.licensedDepartments = const [],
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
      'profile_picture_path': profilePicturePath,
      'role': role,
      'licensedDepartments': licensedDepartments,
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
      profilePicturePath: map['profile_picture_path'] as String?,
      role: map['role'] ?? 'worker',
      licensedDepartments: List<String>.from(map['licensedDepartments'] ?? []),
    );
  }
}
