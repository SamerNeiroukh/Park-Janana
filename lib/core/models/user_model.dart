import 'package:flutter/foundation.dart';

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
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      idNumber: map['idNumber'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePicture: map['profile_picture'] ?? '',
      profilePicturePath: (map['profile_picture_path'] as String?)
          ?? (map['uid'] != null && (map['uid'] as String).isNotEmpty
              ? 'profile_pictures/${map['uid']}/profile.jpg'
              : null),
      role: map['role'] ?? 'worker',
      licensedDepartments: List<String>.from(map['licensedDepartments'] ?? []),
    );
  }

  // Create a copy of UserModel with some fields updated
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? idNumber,
    String? phoneNumber,
    String? profilePicture,
    String? profilePicturePath,
    String? role,
    List<String>? licensedDepartments,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      idNumber: idNumber ?? this.idNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      role: role ?? this.role,
      licensedDepartments: licensedDepartments ?? this.licensedDepartments,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName, idNumber: $idNumber, phoneNumber: $phoneNumber, profilePicture: $profilePicture, profilePicturePath: $profilePicturePath, role: $role, licensedDepartments: $licensedDepartments)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.fullName == fullName &&
        other.idNumber == idNumber &&
        other.phoneNumber == phoneNumber &&
        other.profilePicture == profilePicture &&
        other.profilePicturePath == profilePicturePath &&
        other.role == role &&
        listEquals(other.licensedDepartments, licensedDepartments);
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        fullName.hashCode ^
        idNumber.hashCode ^
        phoneNumber.hashCode ^
        profilePicture.hashCode ^
        profilePicturePath.hashCode ^
        role.hashCode ^
        licensedDepartments.hashCode;
  }
}
