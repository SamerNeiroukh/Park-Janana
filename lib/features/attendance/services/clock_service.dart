import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';

class ClockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'attendance_logs';

  String _getDocId(String userId, DateTime date) =>
      '${userId}_${date.year}_${date.month.toString().padLeft(2, '0')}';

  Future<void> clockIn(String userName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final docId = _getDocId(user.uid, now);
    final docRef = _firestore.collection(collectionName).doc(docId);
    final snapshot = await docRef.get();

    final newSession = AttendanceRecord(clockIn: now, clockOut: now); // placeholder for clockOut

    if (snapshot.exists) {
      await docRef.update({
        'sessions': FieldValue.arrayUnion([newSession.toMap()])
      });
    } else {
      final newModel = AttendanceModel(
        id: docId,
        userId: user.uid,
        userName: userName,
        year: now.year,
        month: now.month,
        sessions: [newSession],
      );
      await docRef.set(newModel.toMap());
    }
  }

  Future<void> clockOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final docId = _getDocId(user.uid, now);
    final docRef = _firestore.collection(collectionName).doc(docId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data == null || data['sessions'] == null) return;

    try {
      final model = AttendanceModel.fromMap(data, docId);
      final updatedSessions = [...model.sessions];
      if (updatedSessions.isEmpty) return;

      final last = updatedSessions.last;
      if (last.clockIn != last.clockOut) return; // already clocked out

      final newRecord = AttendanceRecord(
        clockIn: last.clockIn,
        clockOut: now,
      );

      updatedSessions.removeLast();
      updatedSessions.add(newRecord);

      await docRef.update({
        'sessions': updatedSessions.map((r) => r.toMap()).toList()
      });
    } catch (e) {
      debugPrint('Error clocking out: $e');
    }
  }

  Future<AttendanceRecord?> getOngoingClockIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final docId = _getDocId(user.uid, now);
    final snapshot = await _firestore.collection(collectionName).doc(docId).get();

    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null || data['sessions'] == null) return null;

    try {
      final model = AttendanceModel.fromMap(data, docId);
      final sessions = model.sessions;
      if (sessions.isEmpty) return null;

      final last = sessions.last;
      return last.clockIn == last.clockOut ? last : null;
    } catch (e) {
      debugPrint('Error parsing attendance model: $e');
      return null;
    }
  }

  Future<Map<String, double>> getMonthlyWorkStats(String userId) async {
  final now = DateTime.now();
  final docId = _getDocId(userId, now);

  final snapshot = await _firestore.collection(collectionName).doc(docId).get();
  if (!snapshot.exists) {
    return {
      'hoursWorked': 0.0,
      'daysWorked': 0.0,
    };
  }

  final model = AttendanceModel.fromMap(snapshot.data()!, docId);
  return {
    'hoursWorked': model.totalHoursWorked,
    'daysWorked': model.daysWorked.toDouble(), // ⬅ ensure both are double
  };
}


}
