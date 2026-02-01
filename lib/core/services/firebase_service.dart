import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🟢 Generate a new Firestore Document ID
  String generateDocumentId(String collection) {
    return _firestore.collection(collection).doc().id;
  }

  // ✅ Create a new user in Firestore with fallback for `approved`
  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      // 🔒 Ensure approved is set
      userData['approved'] = userData['approved'] ?? false;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userData['uid'])
          .set(userData);
    } on FirebaseException catch (e) {
      throw CustomException('שגיאה ביצירת משתמש: ${e.message}');
    }
  }

  // 🟢 Fetch user data
  Future<DocumentSnapshot> getUser(String uid) async {
    try {
      return await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    } on FirebaseException catch (e) {
      throw CustomException('שגיאה בקבלת נתוני המשתמש: ${e.message}');
    }
  }

  // 🟢 Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(updates);
    } on FirebaseException catch (e) {
      throw CustomException('שגיאה בעדכון הנתונים: ${e.message}');
    }
  }

  // 🟢 Update Profile Picture
  Future<void> updateProfilePicture(String uid, String profilePictureUrl) async {
    try {
      await updateUser(uid, {'profile_picture': profilePictureUrl});
    } catch (e) {
      throw CustomException('שגיאה בעדכון תמונת הפרופיל.');
    }
  }

  // 🟢 Assign Role to User
  Future<void> assignRole(String uid, String role) async {
    try {
      await updateUser(uid, {'role': role});
    } catch (e) {
      throw CustomException('שגיאה בהקצאת תפקיד.');
    }
  }

  // 🔒 Check if email already exists
  Future<bool> isEmailTaken(String email) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 🔒 Check if phone number already exists
  Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 🔒 Check if ID number already exists
  Future<bool> isIdNumberTaken(String idNumber) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('idNumber', isEqualTo: idNumber)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 🔒 Validate user uniqueness (email, phone, ID)
  Future<Map<String, bool>> validateUserUniqueness({
    required String email,
    required String phoneNumber,
    required String idNumber,
  }) async {
    final results = await Future.wait([
      isEmailTaken(email),
      isPhoneNumberTaken(phoneNumber),
      isIdNumberTaken(idNumber),
    ]);

    return {
      'emailTaken': results[0],
      'phoneTaken': results[1],
      'idTaken': results[2],
    };
  }

  // 🟢 Fetch all shifts as a stream
  Stream<QuerySnapshot> getShiftsStream() {
    return _firestore.collection(AppConstants.shiftsCollection).snapshots();
  }

  // 🟢 Create a new shift
  Future<void> createShift(Map<String, dynamic> shiftData) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftData['shift_id']).set(shiftData);
    } on FirebaseException catch (e) {
      throw CustomException('שגיאה ביצירת משמרת: ${e.message}');
    }
  }

  // 🟢 Update a shift
  Future<void> updateShift(String shiftId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).update(updates);
    } on FirebaseException catch (e) {
      throw CustomException('שגיאה בעדכון משמרת: ${e.message}');
    }
  }

  // 🟢 Delete a shift
  Future<void> deleteShift(String shiftId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).delete();
    } on FirebaseException catch (e) {
      throw CustomException('שגיאה במחיקת המשמרת: ${e.message}');
    }
  }
}
