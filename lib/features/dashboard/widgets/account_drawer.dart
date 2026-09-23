import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../auth/login_screen.dart';
import '../order_history_screen.dart';

class AccountDrawer extends StatelessWidget {
  const AccountDrawer({super.key, required this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final email = (profile?['email'] as String?) ?? l10n.unknown;
    final name = (profile?['full_name'] as String?) ?? l10n.unknown;
    final phone = (profile?['phone_number'] as String?) ?? l10n.unknown;
    final status = profile?['subscription_status'] as String? ?? 'inactive';
    final expiresAtStr = profile?['subscription_expires_at'] as String?;
    final expiresAt =
        expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
    final isAdmin = (profile?['role'] as String?) == 'admin';

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(l10n, name, email, phone, status, expiresAt),
            const Divider(color: AppColors.cardBorder, height: 1),
            // Admins get a shortcut back to the admin dashboard.
            if (isAdmin)
              _tile(
                icon: LucideIcons.shieldCheck,
                label: l10n.switchToAdminView,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen()));
                },
              ),
            _tile(
              icon: LucideIcons.listOrdered,
              label: l10n.orderHistory,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const OrderHistoryScreen()));
              },
            ),
            _tile(
              icon: LucideIcons.messageCircle,
              label: l10n.messageAdminWhatsApp,
              onTap: () => _messageAdmin(context, l10n),
            ),
            _tile(
              icon: LucideIcons.languages,
              label: l10n.language,
              trailing: _LanguageChip(),
              onTap: () => LocalizationService.instance.toggle(),
            ),
            _tile(
              icon: LucideIcons.logOut,
              label: l10n.signOut,
              onTap: () async {
                await SupabaseService.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const Spacer(),
            const Divider(color: AppColors.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${l10n.appVersionLabel} 1.0.0',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    AppLocalizations l10n,
    String name,
    String email,
    String phone,
    String status,
    DateTime? expiresAt,
  ) {
    final chip = _StatusChip(status: status, expiresAt: expiresAt);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryNeon,
                child: Icon(LucideIcons.user, color: Colors.black),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.phone,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(phone,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          chip,
        ],
      ),
    );
  }

  Widget _tile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Open WhatsApp to the admin with a pre-filled message that includes
  /// the driver's name, email and phone so the admin knows who they are.
  Future<void> _messageAdmin(
      BuildContext context, AppLocalizations l10n) async {
    final settings = await SupabaseService.getAdminSettings();
    final rawNumber = settings?['admin_whatsapp_number'] as String?;
    if (!context.mounted) return;
    if (rawNumber == null || rawNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminWhatsAppUnavailable)),
      );
      return;
    }
    final digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final name = (profile?['full_name'] as String?) ?? '';
    final email = (profile?['email'] as String?) ?? '';
    final phone = (profile?['phone_number'] as String?) ?? '';
    final body = l10n.adminMessageTemplate(name, email, phone);
    final uri =
        Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(body)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.expiresAt});
  final String status;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    late Color color;
    late String label;
    switch (status) {
      case 'trial':
        color = AppColors.accentBlue;
        label = l10n.trialLabel;
        break;
      case 'active':
        color = AppColors.primaryNeon;
        label = l10n.activeLabel;
        break;
      case 'expired':
        color = AppColors.warningRed;
        label = l10n.expiredLabel;
        break;
      default:
        color = AppColors.alertAmber;
        label = l10n.inactiveLabel;
    }

    final now = DateTime.now();
    String? countdown;
    if (expiresAt != null && expiresAt!.isAfter(now)) {
      final diff = expiresAt!.difference(now);
      if (status == 'trial') {
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        countdown = l10n.trialTimeLeft(h, m);
      } else if (status == 'active') {
        final d = diff.inDays;
        countdown = l10n.subscriptionActiveDaysLeft(d);
      }
    } else if (expiresAt != null) {
      countdown = DateFormat.yMMMd().format(expiresAt!);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        if (countdown != null)
          Expanded(
            child: Text(
              countdown,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.locale,
      builder: (context, locale, _) {
        final label =
            locale.languageCode == 'ar' ? 'العربية' : 'English';
        return Text(label,
            style: const TextStyle(
                color: AppColors.primaryNeon,
                fontWeight: FontWeight.bold,
                fontSize: 12));
      },
    );
  }
}
