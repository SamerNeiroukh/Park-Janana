import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_model.dart';

class ClockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'attendance_logs';

  Future<AttendanceModel?> getOngoingClockIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final query = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: user.uid)
        .where('clockIn', isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
        .where('clockOut', isNull: true)
        .orderBy('clockIn', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return AttendanceModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  Future<List<AttendanceModel>> getTodayClockSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final query = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: user.uid)
        .where('clockIn', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('clockIn', descending: true)
        .get();

    return query.docs
        .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> clockIn(String userName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = AttendanceModel(
      id: '',
      userId: user.uid,
      userName: userName,
      clockIn: DateTime.now(),
      clockOut: null,
    );

    await _firestore.collection(collectionName).add(data.toMap());
  }

  Future<void> clockOut(AttendanceModel session) async {
    final docRef = _firestore.collection(collectionName).doc(session.id);

    await docRef.update({
      'clockOut': Timestamp.fromDate(DateTime.now()),
    });
  }
}
