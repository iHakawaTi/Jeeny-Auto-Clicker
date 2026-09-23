import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../utils/device_info_util.dart';

/// Thin Supabase wrapper. All business rules that MUST NOT be trusted
/// on the client (activate, extend, deactivate, reset_device) live as
/// SECURITY DEFINER SQL functions and are called via `rpc(...)`.
///
/// Credentials come from `--dart-define-from-file=.env` at build time
/// (see `lib/core/config/env.dart` + `.env.example`). No values are
/// hard-coded — safe to fork this repo.
class SupabaseService {
  static String get supabaseUrl => Env.supabaseUrl;
  static String get supabaseAnonKey => Env.supabaseAnonKey;

  static bool get isConfigured => Env.hasSupabase;

  static SupabaseClient get client => Supabase.instance.client;

  // Local preview fallback (no creds configured yet)
  static bool _mockIsLoggedIn = false;

  // --------------------------------------------------------------
  // Bootstrap
  // --------------------------------------------------------------
  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // --------------------------------------------------------------
  // Auth
  // --------------------------------------------------------------

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      _mockIsLoggedIn = true;
      return;
    }

    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.user != null) {
      await _enforceDeviceBinding(response.user!.id);
    }
  }

  /// Register the driver.
  ///
  /// 1. Pre-check the device fingerprint via the `is_device_registered` RPC —
  ///    Supabase Auth swallows trigger-raised errors, so we surface duplicate-
  ///    device rejections BEFORE creating the auth.users row.
  /// 2. Call `auth.signUp` with device metadata so the server-side trigger
  ///    creates the profile, starts the 48h trial, and binds the device.
  static Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String preferredLanguage = 'en',
  }) async {
    if (!isConfigured) {
      _mockIsLoggedIn = true;
      return;
    }

    final device = await DeviceInfoUtil.getAndroidDeviceInfo();
    final deviceId = device['deviceId'] ?? '';

    // 1. Client-side pre-check (no session required — RPC is SECURITY DEFINER)
    if (deviceId.isNotEmpty) {
      try {
        final res = await client
            .rpc('is_device_registered', params: {'p_device_id': deviceId});
        if (res == true) {
          throw const DeviceAlreadyRegisteredException();
        }
      } on DeviceAlreadyRegisteredException {
        rethrow;
      } catch (_) {
        // RPC unreachable? Fall through to the trigger safety net.
      }
    }

    // 2. Actual signup
    try {
      await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phone,
          'device_id': deviceId,
          'device_model': device['model'],
          'preferred_language': preferredLanguage,
        },
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('device_already_registered') ||
          msg.contains('unique_violation') ||
          msg.contains('duplicate key') ||
          msg.contains('database error saving new user')) {
        throw const DeviceAlreadyRegisteredException();
      }
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '23505' ||
          (e.message).toLowerCase().contains('device_already_registered')) {
        throw const DeviceAlreadyRegisteredException();
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    if (!isConfigured) {
      _mockIsLoggedIn = false;
      return;
    }
    await client.auth.signOut();
  }

  /// Send a password-reset email. Supabase mails a magic link to the
  /// address; clicking it opens a Supabase-hosted page where the user
  /// picks a new password. No deep link is required.
  static Future<void> sendPasswordReset(String email) async {
    if (!isConfigured) return;
    await client.auth.resetPasswordForEmail(email.trim());
  }

  static bool get hasSession =>
      isConfigured ? client.auth.currentUser != null : _mockIsLoggedIn;

  // --------------------------------------------------------------
  // Device binding
  // --------------------------------------------------------------

  /// Re-verifies the current device against the account's stored binding.
  /// Called on cold app start with a valid session (in AuthGate), not just
  /// on signIn — otherwise a session file lifted from device A would let
  /// device B pass right through.
  ///
  /// Returns true if the current device matches the binding (or if the
  /// account has no binding yet, in which case it stamps a new one).
  /// Returns false if it caught a device mismatch and signed the user out.
  static Future<bool> verifyCurrentDeviceOrSignOut() async {
    if (!isConfigured) return true;
    final user = client.auth.currentUser;
    if (user == null) return true;
    try {
      await _enforceDeviceBinding(user.id);
      return true;
    } on DeviceMismatchException {
      return false;
    } catch (_) {
      // Network / RLS error — don't lock the user out for a transient issue.
      return true;
    }
  }

  static Future<void> _enforceDeviceBinding(String userId) async {
    if (!isConfigured) return;

    final deviceInfo = await DeviceInfoUtil.getAndroidDeviceInfo();
    final currentDeviceId = deviceInfo['deviceId']!;
    final modelName = deviceInfo['model']!;

    final existing = await client
        .from('device_bindings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      // First-ever binding for this account. Match is_trial_device to the
      // user's current subscription state so admin-activated users who
      // never opened the trial app still get is_trial_device=false.
      final profile = await getDriverProfile();
      final isTrial =
          (profile?['subscription_status'] as String?) == 'trial';

      await client.from('device_bindings').insert({
        'user_id': userId,
        'device_id': currentDeviceId,
        'device_model': modelName,
        'is_trial_device': isTrial,
      });
    } else if ((existing['device_id'] as String) != currentDeviceId) {
      await client.auth.signOut();
      throw DeviceMismatchException(
        boundDeviceModel: (existing['device_model'] as String?) ?? 'Unknown',
      );
    }
  }

  // --------------------------------------------------------------
  // Profile / subscription
  // --------------------------------------------------------------

  static Future<Map<String, dynamic>?> getDriverProfile() async {
    if (!isConfigured) {
      return {
        'email': 'driver@jeeny.jo',
        'full_name': 'Demo Driver',
        'phone_number': '079xxxxxxx',
        'subscription_status': 'trial',
        'is_active': true,
        'subscription_expires_at':
            DateTime.now().add(const Duration(hours: 47)).toIso8601String(),
        'trial_started_at': DateTime.now().toIso8601String(),
        'role': 'driver',
        'preferred_language': 'en',
      };
    }

    final user = client.auth.currentUser;
    if (user == null) return null;

    return client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  static Future<AccessDecision> resolveAccess() async {
    final profile = await getDriverProfile();
    if (profile == null) return AccessDecision.notLoggedIn;

    final role = profile['role'] as String? ?? 'driver';
    if (role == 'admin') return AccessDecision.admin;

    final status = profile['subscription_status'] as String? ??
        (profile['is_active'] == true ? 'active' : 'inactive');
    final expiresAtStr = profile['subscription_expires_at'] as String?;
    final expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : null;
    final now = DateTime.now();

    final withinExpiry = expiresAt != null && now.isBefore(expiresAt);

    switch (status) {
      case 'trial':
        return withinExpiry ? AccessDecision.trialActive : AccessDecision.trialExpired;
      case 'active':
        return withinExpiry ? AccessDecision.subscriptionActive : AccessDecision.subscriptionExpired;
      case 'expired':
        return AccessDecision.subscriptionExpired;
      case 'inactive':
      default:
        return AccessDecision.inactive;
    }
  }

  /// Convenience for existing call sites (dashboard etc.)
  static Future<bool> isSubscriptionActive() async {
    final decision = await resolveAccess();
    return decision == AccessDecision.trialActive ||
        decision == AccessDecision.subscriptionActive ||
        decision == AccessDecision.admin;
  }

  static Future<void> updatePreferredLanguage(String code) async {
    if (!isConfigured) return;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client
        .from('profiles')
        .update({'preferred_language': code})
        .eq('id', user.id);
  }

  // --------------------------------------------------------------
  // Admin settings
  // --------------------------------------------------------------

  static Future<Map<String, dynamic>?> getAdminSettings() async {
    if (!isConfigured) {
      return {
        'admin_whatsapp_number': '962700000000',
        'admin_display_name': 'Keemo Admin',
      };
    }
    return client
        .from('admin_settings')
        .select()
        .eq('id', 1)
        .maybeSingle();
  }

  static Future<void> updateAdminSettings({
    String? whatsappNumber,
    String? displayName,
  }) async {
    if (!isConfigured) return;
    final payload = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (whatsappNumber != null) payload['admin_whatsapp_number'] = whatsappNumber;
    if (displayName != null) payload['admin_display_name'] = displayName;
    await client.from('admin_settings').update(payload).eq('id', 1);
  }

  // --------------------------------------------------------------
  // Admin-only driver management (RPC wraps SECURITY DEFINER fns)
  // --------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> listAllDrivers() async {
    if (!isConfigured) return const [];
    final rows = await client
        .from('profiles')
        .select('*, device_bindings(device_model, device_id, is_trial_device)')
        .eq('role', 'driver')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  static Future<void> adminActivateOneMonth(String userId) async {
    await client.rpc('activate_subscription_one_month',
        params: {'target_user_id': userId});
  }

  static Future<void> adminExtend(String userId, int days) async {
    await client.rpc('extend_subscription',
        params: {'target_user_id': userId, 'extend_days': days});
  }

  static Future<void> adminDeactivate(String userId) async {
    await client.rpc('deactivate_subscription',
        params: {'target_user_id': userId});
  }

  static Future<void> adminResetDevice(String userId) async {
    await client.rpc('reset_user_device_binding',
        params: {'target_user_id': userId});
  }

  // --------------------------------------------------------------
  // Order log
  // --------------------------------------------------------------

  static Future<void> logAcceptedOrder({
    required double fareAmount,
    required int pickupMins,
    required String rawText,
  }) async {
    if (!isConfigured) return;
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('accepted_orders_log').insert({
      'user_id': user.id,
      'fare_amount': fareAmount,
      'pickup_time_mins': pickupMins,
      'raw_screen_text': rawText,
    });
  }

  static Future<List<Map<String, dynamic>>> listMyOrders({int limit = 50}) async {
    if (!isConfigured) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];
    final rows = await client
        .from('accepted_orders_log')
        .select()
        .eq('user_id', user.id)
        .order('accepted_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}

enum AccessDecision {
  notLoggedIn,
  admin,
  trialActive,
  trialExpired,
  subscriptionActive,
  subscriptionExpired,
  inactive,
}

class DeviceAlreadyRegisteredException implements Exception {
  const DeviceAlreadyRegisteredException();
  @override
  String toString() => 'DEVICE_ALREADY_REGISTERED';
}

class DeviceMismatchException implements Exception {
  const DeviceMismatchException({required this.boundDeviceModel});
  final String boundDeviceModel;
  @override
  String toString() => 'DEVICE_MISMATCH';
}
