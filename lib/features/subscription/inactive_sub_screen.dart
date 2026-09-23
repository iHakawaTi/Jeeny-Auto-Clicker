import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/language_toggle_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

enum InactiveReason { trialExpired, subscriptionExpired, inactive }

class InactiveSubScreen extends StatefulWidget {
  const InactiveSubScreen({super.key, this.reason = InactiveReason.inactive});
  final InactiveReason reason;

  @override
  State<InactiveSubScreen> createState() => _InactiveSubScreenState();
}

class _InactiveSubScreenState extends State<InactiveSubScreen>
    with WidgetsBindingObserver {
  bool _isChecking = false;
  Map<String, dynamic>? _adminSettings;
  Map<String, dynamic>? _profile;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadContext();
    // Poll every 8 seconds so when the admin activates the driver's
    // account, we route them to the Dashboard without them tapping.
    _autoRefresh = Timer.periodic(const Duration(seconds: 8), (_) {
      _silentCheckAndMaybeRoute();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Coming back to the app is the most common time the driver's
      // status has changed — check immediately.
      _silentCheckAndMaybeRoute();
    }
  }

  /// Same as _checkStatus but without the loading UI or the "still
  /// inactive" snack bar — used by the auto-poll + lifecycle callbacks.
  Future<void> _silentCheckAndMaybeRoute() async {
    if (!mounted) return;
    final active = await SupabaseService.isSubscriptionActive();
    if (!mounted) return;
    if (active) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _loadContext() async {
    final admin = await SupabaseService.getAdminSettings();
    final profile = await SupabaseService.getDriverProfile();
    if (!mounted) return;
    setState(() {
      _adminSettings = admin;
      _profile = profile;
    });
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final l10n = AppLocalizations.of(context);
    final active = await SupabaseService.isSubscriptionActive();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (active) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionStillInactive),
          backgroundColor: AppColors.alertAmber,
        ),
      );
    }
  }

  Future<void> _messageAdmin() async {
    final l10n = AppLocalizations.of(context);
    final rawNumber = _adminSettings?['admin_whatsapp_number'] as String?;
    if (rawNumber == null || rawNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminWhatsAppUnavailable)),
      );
      return;
    }

    final digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final name = (_profile?['full_name'] as String?) ?? '';
    final email = (_profile?['email'] as String?) ?? '';
    final phone = (_profile?['phone_number'] as String?) ?? '';
    final body = l10n.adminMessageTemplate(name, email, phone);
    final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(body)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  ({String title, String body}) _copy(AppLocalizations l10n) {
    switch (widget.reason) {
      case InactiveReason.trialExpired:
        return (title: l10n.trialExpiredTitle, body: l10n.trialExpiredBody);
      case InactiveReason.subscriptionExpired:
        return (
          title: l10n.subscriptionExpiredTitle,
          body: l10n.subscriptionExpiredBody
        );
      case InactiveReason.inactive:
        return (
          title: l10n.subscriptionInactiveTitle,
          body: l10n.subscriptionInactiveBody
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = _copy(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LanguageToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.alertAmber.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.alertAmber, width: 2),
                  ),
                  child: const Icon(LucideIcons.shieldAlert,
                      size: 46, color: AppColors.alertAmber),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                copy.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                copy.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _statusRow(l10n.accountStatus, _statusLabel(l10n)),
                    const Divider(color: AppColors.cardBorder, height: 24),
                    _statusRow(l10n.autoAcceptService, l10n.statusLocked),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _messageAdmin,
                icon: const Icon(LucideIcons.messageCircle,
                    color: Colors.black),
                label: Text(
                  l10n.messageAdminWhatsApp,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isChecking ? null : _checkStatus,
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primaryNeon),
                      )
                    : const Icon(LucideIcons.refreshCw,
                        size: 18, color: AppColors.primaryNeon),
                label: Text(
                  _isChecking ? l10n.checking : l10n.refreshStatus,
                  style: const TextStyle(color: AppColors.primaryNeon),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryNeon),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await SupabaseService.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(LucideIcons.logOut,
                    size: 18, color: AppColors.textSecondary),
                label: Text(l10n.signOut,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (widget.reason) {
      case InactiveReason.trialExpired:
      case InactiveReason.subscriptionExpired:
        return l10n.statusExpired;
      case InactiveReason.inactive:
        return l10n.statusInactive;
    }
  }

  Widget _statusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(
              color: AppColors.warningRed, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
