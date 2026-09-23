import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class DriverRow extends StatelessWidget {
  const DriverRow({
    super.key,
    required this.driver,
    required this.onActivate,
    required this.onExtend,
    required this.onDeactivate,
    required this.onResetDevice,
    required this.onWhatsapp,
  });

  final Map<String, dynamic> driver;
  final VoidCallback onActivate;
  final VoidCallback onExtend;
  final VoidCallback onDeactivate;
  final VoidCallback onResetDevice;
  final VoidCallback onWhatsapp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = (driver['full_name'] as String?) ?? '';
    final email = (driver['email'] as String?) ?? '';
    final phone = (driver['phone_number'] as String?) ?? '';
    final status = driver['subscription_status'] as String? ?? 'inactive';
    final expiresAt = DateTime.tryParse(
        (driver['subscription_expires_at'] as String?) ?? '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _colorFor(status).withOpacity(0.2),
                child: Icon(LucideIcons.user, color: _colorFor(status)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? email : name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    if (phone.isNotEmpty)
                      Text(phone,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              _statusChip(status, l10n),
            ],
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_expiryLabel(status, expiresAt)} ${DateFormat.yMMMd().format(expiresAt.toLocal())}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn(icon: LucideIcons.checkCircle, label: l10n.activateOneMonth, color: AppColors.primaryNeon, onTap: onActivate),
              _btn(icon: LucideIcons.plusCircle, label: l10n.extend, color: AppColors.accentBlue, onTap: onExtend),
              _btn(icon: LucideIcons.pauseCircle, label: l10n.deactivate, color: AppColors.alertAmber, onTap: onDeactivate),
              _btn(icon: LucideIcons.smartphone, label: l10n.resetDevice, color: AppColors.textSecondary, onTap: onResetDevice),
              if (phone.isNotEmpty)
                _btn(icon: LucideIcons.messageCircle, label: 'WhatsApp', color: AppColors.primaryNeon, onTap: onWhatsapp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label,
          style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _statusChip(String status, AppLocalizations l10n) {
    final color = _colorFor(status);
    final label = _labelFor(status, l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'trial':
        return AppColors.accentBlue;
      case 'active':
        return AppColors.primaryNeon;
      case 'expired':
        return AppColors.warningRed;
      case 'inactive':
      default:
        return AppColors.alertAmber;
    }
  }

  String _labelFor(String status, AppLocalizations l10n) {
    switch (status) {
      case 'trial':
        return l10n.trialLabel;
      case 'active':
        return l10n.activeLabel;
      case 'expired':
        return l10n.expiredLabel;
      case 'inactive':
      default:
        return l10n.inactiveLabel;
    }
  }

  String _expiryLabel(String status, DateTime expiresAt) {
    return status == 'trial' ? '⏱' : '📅';
  }
}
