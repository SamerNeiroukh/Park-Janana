import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// AppAuthProvider manages authentication state
/// Centralizes login, logout, and auth state management
/// (Named AppAuthProvider to avoid conflict with Firebase AuthProvider)
class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _userRole;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get uid => _user?.uid;

  AppAuthProvider() {
    _initAuthListener();
  }

  /// Initialize Firebase Auth state listener
  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserRole();
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  /// Load user role from Firestore
  Future<void> _loadUserRole() async {
    if (_user == null) return;

    try {
      _userRole = await _authService.fetchUserRole(_user!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _userRole = null;
    } catch (e) {
      _error = 'Error signing out: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user role (useful after role changes)
  Future<void> refreshUserRole() async {
    await _loadUserRole();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
