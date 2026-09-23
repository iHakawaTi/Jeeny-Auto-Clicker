import 'dart:convert';

import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel =
      MethodChannel('com.jeeny.autoaccept/native_bridge');

  // ---------------- Device info ----------------

  /// Returns {manufacturer, brand, model, sdk (int)}.
  static Future<Map<String, dynamic>> getManufacturerInfo() async {
    try {
      final res = await _channel.invokeMethod('getManufacturer');
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {}
    return const {
      'manufacturer': '',
      'brand': '',
      'model': '',
      'sdk': 0,
    };
  }

  /// Settings.Secure.ANDROID_ID — a genuine per-device identifier.
  static Future<String> getAndroidId() async {
    try {
      final res = await _channel.invokeMethod('getAndroidId');
      if (res is String) return res;
    } catch (_) {}
    return '';
  }

  // ---------------- Bubble overlay ----------------

  static Future<bool> isBubbleEnabled() async {
    try {
      final res = await _channel.invokeMethod('isBubbleEnabled');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBubbleEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setBubbleEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  // ---------------- Accessibility ----------------

  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final res = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the manufacturer-appropriate accessibility settings page.
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  // ---------------- Overlay ----------------

  static Future<bool> isOverlayPermissionGranted() async {
    try {
      final res = await _channel.invokeMethod('isOverlayPermissionGranted');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  // ---------------- Battery optimization ----------------

  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final res = await _channel.invokeMethod('isBatteryOptimizationIgnored');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final res = await _channel.invokeMethod('requestBatteryOptimizationExemption');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  // ---------------- Auto-start (OEM specific) ----------------

  /// Attempts to launch the manufacturer's auto-start settings screen.
  /// Falls back to app details page if no OEM match.
  static Future<bool> openAutoStartSettings() async {
    try {
      final res = await _channel.invokeMethod('openAutoStartSettings');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  // ---------------- Auto-accept criteria ----------------

  /// True if the accessibility service's internal `is_enabled` flag is set.
  /// This can drift out of sync with Dart state if the user flips the
  /// floating bubble from outside the app, so we poll it in the Dashboard.
  static Future<bool> getAutoAcceptEnabled() async {
    try {
      final res = await _channel.invokeMethod('getAutoAcceptEnabled');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Loads the last saved is_enabled + min_fare + max_pickup_mins from
  /// the native side's SharedPreferences, so the Dashboard sliders can
  /// restore their positions instead of always starting at defaults.
  static Future<Map<String, dynamic>> getSavedCriteria() async {
    try {
      final res = await _channel.invokeMethod('getSavedCriteria');
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {}
    return const {
      'is_enabled': false,
      'min_fare': 5.0,
      'max_pickup_mins': 5,
    };
  }

  static Future<void> updateCriteria({
    required bool isEnabled,
    required double minFare,
    required int maxPickupMins,
  }) async {
    try {
      await _channel.invokeMethod('updateCriteria', {
        'is_enabled': isEnabled,
        'min_fare': minFare,
        'max_pickup_mins': maxPickupMins,
      });
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getLastAcceptedOrder() async {
    try {
      final result = await _channel.invokeMethod('getLastAcceptedOrder');
      if (result is Map) return Map<String, dynamic>.from(result);
    } catch (_) {}
    return null;
  }

  /// Atomically read-and-clear the queue of accepted orders that were
  /// clicked by the native service. The Dashboard uploads these into
  /// Supabase so the drawer's Order History has a real history.
  static Future<List<Map<String, dynamic>>> drainPendingOrders() async {
    try {
      final res = await _channel.invokeMethod('drainPendingOrders');
      if (res is String && res.isNotEmpty) {
        final decoded = jsonDecode(res);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (_) {}
    return const [];
  }
}
