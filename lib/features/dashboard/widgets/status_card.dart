import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class StatusCard extends StatelessWidget {
  final bool isAccessibilityGranted;
  final bool isOverlayGranted;
  final bool isBatteryOk;
  final bool isSubscriptionActive;
  final VoidCallback onFixPermissionsTap;
  final VoidCallback onFixBattery;
  final VoidCallback onOpenAutoStart;

  const StatusCard({
    super.key,
    required this.isAccessibilityGranted,
    required this.isOverlayGranted,
    required this.isBatteryOk,
    required this.isSubscriptionActive,
    required this.onFixPermissionsTap,
    required this.onFixBattery,
    required this.onOpenAutoStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coreOk =
        isAccessibilityGranted && isOverlayGranted && isSubscriptionActive;
    final allSystemsGo = coreOk && isBatteryOk;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allSystemsGo
              ? AppColors.primaryNeon.withOpacity(0.5)
              : AppColors.alertAmber,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: allSystemsGo
                      ? AppColors.primaryNeon.withOpacity(0.15)
                      : AppColors.alertAmber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allSystemsGo
                      ? LucideIcons.shieldCheck
                      : LucideIcons.shieldAlert,
                  color: allSystemsGo
                      ? AppColors.primaryNeon
                      : AppColors.alertAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allSystemsGo ? l10n.systemReady : l10n.actionRequired,
                      style: TextStyle(
                          color: allSystemsGo
                              ? AppColors.primaryNeon
                              : AppColors.alertAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allSystemsGo
                          ? l10n.systemReadyBody
                          : l10n.actionRequiredBody,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorder, height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _pill(label: l10n.subActive, isOk: isSubscriptionActive),
              _pill(
                  label: l10n.accessibility, isOk: isAccessibilityGranted),
              _pill(label: l10n.overlay, isOk: isOverlayGranted),
              _pill(label: l10n.batteryOpt, isOk: isBatteryOk),
              _pill(label: l10n.autoStartLabel, isOk: null),
            ],
          ),
          if (!isAccessibilityGranted || !isOverlayGranted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onFixPermissionsTap,
                icon: const Icon(LucideIcons.settings,
                    size: 16, color: AppColors.primaryNeon),
                label: Text(
                  l10n.grantMissingPermissions,
                  style: const TextStyle(
                      color: AppColors.primaryNeon,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryNeon),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          if (isAccessibilityGranted && isOverlayGranted && !isBatteryOk) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onFixBattery,
                icon: const Icon(LucideIcons.batteryCharging,
                    size: 16, color: AppColors.alertAmber),
                label: Text(
                  l10n.batteryOptTitle,
                  style: const TextStyle(
                      color: AppColors.alertAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.alertAmber),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill({required String label, required bool? isOk}) {
    // null -> unknown/informational (Auto-Start)
    final color = isOk == null
        ? AppColors.textSecondary
        : isOk
            ? AppColors.primaryNeon
            : AppColors.warningRed;
    final icon = isOk == null
        ? LucideIcons.helpCircle
        : isOk
            ? LucideIcons.checkCircle2
            : LucideIcons.xCircle;
    return GestureDetector(
      onTap: isOk == null ? onOpenAutoStart : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: isOk == false
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight:
                      isOk == true ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
