import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class ActivityLogCard extends StatelessWidget {
  final Map<String, dynamic>? lastAcceptedOrder;

  const ActivityLogCard({super.key, required this.lastAcceptedOrder});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.history,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.recentActivity,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lastAcceptedOrder == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.clock,
                      color: AppColors.textMuted, size: 32),
                  const SizedBox(height: 8),
                  Text(l10n.noOrdersYet,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(l10n.turnOnMasterAndOpenJeeny,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primaryNeon.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNeon,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.check,
                        color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.acceptedOrderPrefix(
                              lastAcceptedOrder!['fare'] as String? ?? '—'),
                          style: const TextStyle(
                              color: AppColors.primaryNeon,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.pickupEtaLabel(
                              lastAcceptedOrder!['time'] as String? ?? '—'),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (lastAcceptedOrder!['timestamp'] != null)
                    Text(
                      DateFormat('hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            (lastAcceptedOrder!['timestamp'] as num)
                                .toInt()),
                      ),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
