import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/native_bridge.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/language_toggle_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../permissions/permissions_screen.dart';
import '../subscription/inactive_sub_screen.dart';
import 'widgets/account_drawer.dart';
import 'widgets/activity_log_card.dart';
import 'widgets/bubble_toggle_card.dart';
import 'widgets/criteria_card.dart';
import 'widgets/status_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  bool _isAutoAcceptEnabled = false;
  double _minFare = 5.0;
  int _maxPickupMins = 5;

  bool _isAccessibilityGranted = false;
  bool _isOverlayGranted = false;
  bool _isBatteryOk = false;
  bool _isSubscriptionActive = true;

  Map<String, dynamic>? _lastAcceptedOrder;
  Map<String, dynamic>? _profile;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDashboardState();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshRuntime();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshRuntime();
  }

  Future<void> _initDashboardState() async {
    // Restore last saved criteria BEFORE any sync — otherwise
    // _syncCriteriaToNative would overwrite the persisted values with
    // the Dart defaults on every cold start.
    final saved = await NativeBridge.getSavedCriteria();
    _isAutoAcceptEnabled = (saved['is_enabled'] as bool?) ?? false;
    _minFare = (saved['min_fare'] as num?)?.toDouble() ?? _minFare;
    _maxPickupMins = (saved['max_pickup_mins'] as num?)?.toInt() ?? _maxPickupMins;

    _profile = await SupabaseService.getDriverProfile();
    await _refreshRuntime();
    // Now sync — writes the RESTORED values back (no-op change).
    await _syncCriteriaToNative();
    if (mounted) setState(() {});
  }

  Future<void> _refreshRuntime() async {
    // Drain any orders the native service accepted while we weren't
    // looking and push them to Supabase so Order History reflects them.
    // Runs in parallel with the status polls — we don't block on it.
    unawaited(_drainAndUploadPendingOrders());

    final results = await Future.wait([
      NativeBridge.isAccessibilityServiceEnabled(),
      NativeBridge.isOverlayPermissionGranted(),
      NativeBridge.isBatteryOptimizationIgnored(),
      SupabaseService.isSubscriptionActive(),
      NativeBridge.getLastAcceptedOrder(),
      NativeBridge.getAutoAcceptEnabled(),
    ]);
    if (!mounted) return;
    final nativeEnabled = results[5] as bool;
    setState(() {
      _isAccessibilityGranted = results[0] as bool;
      _isOverlayGranted = results[1] as bool;
      _isBatteryOk = results[2] as bool;
      _isSubscriptionActive = results[3] as bool;
      _lastAcceptedOrder = results[4] as Map<String, dynamic>?;
      // If the bubble (or anything else) flipped is_enabled behind our
      // back, mirror the native truth into the Master Switch.
      if (nativeEnabled != _isAutoAcceptEnabled) {
        _isAutoAcceptEnabled = nativeEnabled;
      }
    });

    if (!_isSubscriptionActive && mounted) {
      final decision = await SupabaseService.resolveAccess();
      if (!mounted) return;
      InactiveReason reason;
      switch (decision) {
        case AccessDecision.trialExpired:
          reason = InactiveReason.trialExpired;
          break;
        case AccessDecision.subscriptionExpired:
          reason = InactiveReason.subscriptionExpired;
          break;
        default:
          reason = InactiveReason.inactive;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => InactiveSubScreen(reason: reason)),
      );
    }
  }

  Future<void> _drainAndUploadPendingOrders() async {
    final pending = await NativeBridge.drainPendingOrders();
    if (pending.isEmpty) return;
    for (final p in pending) {
      final fare = (p['fare'] as num?)?.toDouble() ?? 0;
      final pickup = (p['pickup_mins'] as num?)?.toInt() ?? 0;
      final raw = (p['raw_text'] as String?) ?? '';
      try {
        await SupabaseService.logAcceptedOrder(
          fareAmount: fare,
          pickupMins: pickup,
          rawText: raw,
        );
      } catch (_) {
        // Swallow — next tick will retry with fresh queue entries
        // (best-effort; we deliberately don't re-queue on failure
        // to avoid runaway duplicates on repeated errors).
      }
    }
  }

  Future<void> _syncCriteriaToNative() {
    return NativeBridge.updateCriteria(
      isEnabled: _isAutoAcceptEnabled,
      minFare: _minFare,
      maxPickupMins: _maxPickupMins,
    );
  }

  void _onToggleMasterSwitch(bool value) async {
    if (value && (!_isAccessibilityGranted || !_isOverlayGranted)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PermissionsScreen()),
      );
      return;
    }
    setState(() => _isAutoAcceptEnabled = value);
    await _syncCriteriaToNative();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AccountDrawer(profile: _profile),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryNeon,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.zap,
                  color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.appTagline,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: const [LanguageToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _masterSwitch(l10n),
              const SizedBox(height: 20),
              StatusCard(
                isAccessibilityGranted: _isAccessibilityGranted,
                isOverlayGranted: _isOverlayGranted,
                isBatteryOk: _isBatteryOk,
                isSubscriptionActive: _isSubscriptionActive,
                onFixPermissionsTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PermissionsScreen()));
                },
                onFixBattery: () async {
                  await NativeBridge.requestBatteryOptimizationExemption();
                  _refreshRuntime();
                },
                onOpenAutoStart: () async {
                  await NativeBridge.openAutoStartSettings();
                },
              ),
              const SizedBox(height: 20),
              CriteriaCard(
                minFare: _minFare,
                maxPickupMins: _maxPickupMins,
                onMinFareChanged: (v) {
                  setState(() => _minFare = v);
                  _syncCriteriaToNative();
                },
                onMaxPickupMinsChanged: (v) {
                  setState(() => _maxPickupMins = v);
                  _syncCriteriaToNative();
                },
              ),
              const SizedBox(height: 20),
              BubbleToggleCard(hasOverlayPermission: _isOverlayGranted),
              const SizedBox(height: 20),
              ActivityLogCard(lastAcceptedOrder: _lastAcceptedOrder),
            ],
          ),
        ),
      ),
    );
  }

  Widget _masterSwitch(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isAutoAcceptEnabled
              ? AppColors.primaryNeon
              : AppColors.cardBorder,
          width: _isAutoAcceptEnabled ? 2 : 1,
        ),
        boxShadow: _isAutoAcceptEnabled
            ? [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 15,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAutoAcceptEnabled
                      ? l10n.autoAcceptActive
                      : l10n.autoAcceptOff,
                  style: TextStyle(
                    color: _isAutoAcceptEnabled
                        ? AppColors.primaryNeon
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAutoAcceptEnabled
                      ? l10n.scanningJeeny
                      : l10n.turnOnSwitch,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAutoAcceptEnabled,
            activeColor: AppColors.primaryNeon,
            activeTrackColor: AppColors.primaryNeon.withOpacity(0.3),
            onChanged: _onToggleMasterSwitch,
          ),
        ],
      ),
    );
  }
}
