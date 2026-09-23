import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns app-wide locale (persisted to SharedPreferences + optionally to Supabase).
///
/// Usage:
///   MaterialApp(locale: LocalizationService.instance.locale.value, …)
///   ValueListenableBuilder(valueListenable: LocalizationService.instance.locale, …)
class LocalizationService {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  static const _prefsKey = 'preferred_language_code';
  static const supportedLocales = <Locale>[Locale('en'), Locale('ar')];

  final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale('en'));

  /// Load persisted choice, or fall back to the device's system locale
  /// (only if the system language is one we support).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && _isSupported(saved)) {
      locale.value = Locale(saved);
      return;
    }

    final system = PlatformDispatcher.instance.locale.languageCode;
    if (_isSupported(system)) {
      locale.value = Locale(system);
    } else {
      locale.value = const Locale('en');
    }
  }

  Future<void> setLocale(Locale next) async {
    if (!_isSupported(next.languageCode)) return;
    locale.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next.languageCode);
  }

  Future<void> toggle() async {
    final next = locale.value.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }

  bool _isSupported(String code) =>
      supportedLocales.any((l) => l.languageCode == code);
}
