class UserModel {
  final String fullName;
  final String email;
  final String idNumber;
  final String phoneNumber;

  UserModel({
    required this.fullName,
    required this.email,
    required this.idNumber,
    required this.phoneNumber,
  });

  // Convert user data to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
    };
  }

  // Convert Map data from Firebase to a UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      idNumber: map['idNumber'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}
