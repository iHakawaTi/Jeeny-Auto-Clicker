import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/native_bridge.dart';
import '../../core/widgets/language_toggle_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import 'accessibility_guide_sheet.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _isAccessibilityGranted = false;
  bool _isOverlayGranted = false;
  bool _isBatteryOk = false;
  Map<String, dynamic> _manufacturer = const {'manufacturer': ''};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final results = await Future.wait([
      NativeBridge.isAccessibilityServiceEnabled(),
      NativeBridge.isOverlayPermissionGranted(),
      NativeBridge.isBatteryOptimizationIgnored(),
      NativeBridge.getManufacturerInfo(),
    ]);
    if (!mounted) return;
    setState(() {
      _isAccessibilityGranted = results[0] as bool;
      _isOverlayGranted = results[1] as bool;
      _isBatteryOk = results[2] as bool;
      _manufacturer = results[3] as Map<String, dynamic>;
    });
  }

  Future<void> _tapAccessibility() async {
    await NativeBridge.openAccessibilitySettings();
    if (!mounted) return;
    // Show step-by-step guide overlay while user is away
    AccessibilityGuideSheet.show(
      context,
      manufacturer: (_manufacturer['manufacturer'] as String?) ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coreGranted = _isAccessibilityGranted && _isOverlayGranted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.requiredPermissions,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [LanguageToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.permissionsIntro,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              _permissionCard(
                l10n: l10n,
                title: l10n.accessibilityTitle,
                body: l10n.accessibilityBody,
                isGranted: _isAccessibilityGranted,
                onTap: _tapAccessibility,
              ),
              const SizedBox(height: 14),
              _permissionCard(
                l10n: l10n,
                title: l10n.overlayTitle,
                body: l10n.overlayBody,
                isGranted: _isOverlayGranted,
                onTap: () => NativeBridge.openOverlaySettings(),
              ),
              const SizedBox(height: 14),
              _permissionCard(
                l10n: l10n,
                title: l10n.batteryOptTitle,
                body: l10n.batteryOptBody,
                isGranted: _isBatteryOk,
                onTap: () => NativeBridge.requestBatteryOptimizationExemption(),
              ),
              const SizedBox(height: 14),
              _permissionCard(
                l10n: l10n,
                title: l10n.autoStartTitle,
                body: l10n.autoStartBody,
                // Auto-start can't be reliably detected -> always show the CTA.
                isGranted: false,
                showBadge: false,
                onTap: () => NativeBridge.openAutoStartSettings(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: coreGranted
                    ? () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const DashboardScreen()),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  coreGranted
                      ? l10n.continueToDashboard
                      : l10n.grantAllToProceed,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionCard({
    required AppLocalizations l10n,
    required String title,
    required String body,
    required bool isGranted,
    required VoidCallback onTap,
    bool showBadge = true,
  }) {
    final badge = isGranted ? l10n.granted : l10n.actionNeeded;
    final badgeColor =
        isGranted ? AppColors.primaryNeon : AppColors.alertAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.primaryNeon.withOpacity(0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGranted
                    ? LucideIcons.checkCircle
                    : LucideIcons.alertCircle,
                color: isGranted
                    ? AppColors.primaryNeon
                    : AppColors.alertAmber,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              if (showBadge)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(LucideIcons.settings,
                  size: 16, color: AppColors.textPrimary),
              label: Text(l10n.openSystemSettings,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
