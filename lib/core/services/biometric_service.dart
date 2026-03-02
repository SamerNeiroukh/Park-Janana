import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static const _keyEmail = 'biometric_email';
  static const _keyPassword = 'biometric_password';
  static const _keyEnabled = 'biometric_enabled';

  /// Returns true if the device supports secure authentication (biometrics or
  /// PIN/passcode). Uses isDeviceSupported() rather than canCheckBiometrics so
  /// that devices with a PIN but no enrolled biometric are still offered the
  /// feature — the OS will show the appropriate prompt (fingerprint, Face ID,
  /// or PIN fallback) based on what the device has set up.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the user has previously opted in to biometric login.
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final value = await _storage.read(key: _keyEnabled);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric sheet. Returns true on success.
  Future<bool> authenticate({
    String reason = 'אמת את זהותך כדי להיכנס לאפליקציה',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Stores credentials in the device secure enclave and marks biometric enabled.
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  /// Returns stored credentials, or null if none exist.
  Future<({String email, String password})?> getCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      if (email == null || password == null) return null;
      return (email: email, password: password);
    } catch (_) {
      return null;
    }
  }

  /// Removes all stored biometric credentials (called on logout).
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyPassword);
      await _storage.delete(key: _keyEnabled);
    } catch (_) {}
  }
}
