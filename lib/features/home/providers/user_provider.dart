import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/features/attendance/services/clock_service.dart';
import 'package:park_janana/core/constants/app_constants.dart';

/// UserProvider manages user data and work statistics
/// Provides centralized access to current user information
class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  Map<String, double>? _workStats;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  // Cache for user data to avoid redundant fetches.
  // A TTL ensures that role/profile changes made by managers are picked up
  // within a reasonable window without requiring a full logout/login cycle.
  final Map<String, UserModel> _userCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  UserProvider() {
    // Auto-clear whenever the user signs out or the session expires,
    // regardless of whether the explicit logout button was used.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) clearUser();
    });
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  Map<String, double>? get workStats => _workStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load current user data from Firestore
  Future<void> loadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return;
    }

    await loadUser(uid);
  }

  bool _isCacheValid(String uid) {
    final ts = _cacheTimestamps[uid];
    return ts != null && DateTime.now().difference(ts) < _cacheTtl;
  }

  /// Load specific user by UID
  Future<void> loadUser(String uid) async {
    // Check cache first (with TTL so role changes propagate within 5 minutes)
    if (_userCache.containsKey(uid) && _isCacheValid(uid)) {
      _currentUser = _userCache[uid];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid);

      final userDoc = await docRef.get().timeout(const Duration(seconds: 8));

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(userData);
        _userCache[uid] = _currentUser!;
        _cacheTimestamps[uid] = DateTime.now();
      } else {
        _error = 'User not found';
      }
    } catch (e) {
      _error = 'Error loading user: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load monthly work statistics for current user
  Future<void> loadWorkStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final stats = await ClockService().getMonthlyWorkStats(uid);
      _workStats = {
        'hoursWorked': stats['hoursWorked']?.toDouble() ?? 0.0,
        'daysWorked': stats['daysWorked']?.toDouble() ?? 0.0,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading work stats: $e');
      _workStats = {
        'hoursWorked': 0.0,
        'daysWorked': 0.0,
      };
      notifyListeners();
    }
  }

  /// Update user profile picture
  Future<void> updateProfilePicture(String profilePictureUrl) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.uid)
          .update({'profile_picture': profilePictureUrl});

      // Update local state
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        fullName: _currentUser!.fullName,
        idNumber: _currentUser!.idNumber,
        phoneNumber: _currentUser!.phoneNumber,
        profilePicture: profilePictureUrl,
        profilePicturePath: _currentUser!.profilePicturePath,
        role: _currentUser!.role,
        licensedDepartments: _currentUser!.licensedDepartments,
      );

      // Update cache
      _userCache[_currentUser!.uid] = _currentUser!;

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      rethrow;
    }
  }

  /// Clear user data (on logout)
  void clearUser() {
    _currentUser = null;
    _workStats = null;
    _userCache.clear();
    _cacheTimestamps.clear();
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Refresh user data (useful after profile updates)
  Future<void> refresh() async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      // Clear cache to force fresh fetch
      _userCache.remove(uid);
      await loadUser(uid);
      await loadWorkStats();
    }
  }

  /// Get cached user by UID (for other screens needing user data)
  Future<UserModel?> getUserById(String uid) async {
    if (_userCache.containsKey(uid) && _isCacheValid(uid)) {
      return _userCache[uid];
    }

    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final user = UserModel.fromMap(userData);
        _userCache[uid] = user;
        _cacheTimestamps[uid] = DateTime.now();
        return user;
      }
    } catch (e) {
      debugPrint('Error fetching user by ID: $e');
    }
    return null;
  }
}
