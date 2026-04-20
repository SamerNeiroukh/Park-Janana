import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/services/notification_service.dart';

const _kLocaleKey = 'app_locale';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('he');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
    // Sync current locale to Firestore so Cloud Functions always have it.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'locale': _locale.languageCode}).catchError((_) {});
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final code = locale.languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, code);
    // Persist locale to Firestore so Cloud Functions can send
    // notifications in the user's chosen language.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'locale': code}).catchError((_) {});
    }
    // Reschedule any active local notifications in the new language.
    NotificationService().rescheduleIfActive().catchError((_) {});
  }

  static const supportedLocales = [
    Locale('he'),
    Locale('en'),
    Locale('ar'),
  ];
}
