import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime clockIn;
  final DateTime? clockOut;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.clockIn,
    this.clockOut,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AttendanceModel(
      id: documentId,
      userId: data['userId'],
      userName: data['userName'],
      clockIn: (data['clockIn'] as Timestamp).toDate(),
      clockOut: data['clockOut'] != null ? (data['clockOut'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'clockIn': Timestamp.fromDate(clockIn),
      'clockOut': clockOut != null ? Timestamp.fromDate(clockOut!) : null,
    };
  }
}
