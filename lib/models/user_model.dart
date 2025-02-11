class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String idNumber;
  final String phoneNumber;
  final String profilePicture;
  final String role; // Added role field

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.idNumber,
    required this.phoneNumber,
    required this.profilePicture,
    required this.role,
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
    );
  }
}
