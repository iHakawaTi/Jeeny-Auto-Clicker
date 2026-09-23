import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class CriteriaCard extends StatelessWidget {
  final double minFare;
  final int maxPickupMins;
  final ValueChanged<double> onMinFareChanged;
  final ValueChanged<int> onMaxPickupMinsChanged;

  const CriteriaCard({
    super.key,
    required this.minFare,
    required this.maxPickupMins,
    required this.onMinFareChanged,
    required this.onMaxPickupMinsChanged,
  });

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
              const Icon(LucideIcons.sliders,
                  color: AppColors.primaryNeon, size: 22),
              const SizedBox(width: 10),
              Text(
                l10n.autoAcceptCriteria,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(l10n.minimumTripPrice,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryNeon.withOpacity(0.4)),
                ),
                child: Text(
                  l10n.farePlusSuffix(minFare.toStringAsFixed(1)),
                  style: const TextStyle(
                      color: AppColors.primaryNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryNeon,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.primaryNeon,
              overlayColor: AppColors.primaryGlow,
            ),
            child: Slider(
              value: minFare,
              min: 1.0,
              max: 20.0,
              divisions: 38,
              label: '${minFare.toStringAsFixed(1)} JDs',
              onChanged: onMinFareChanged,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(l10n.maxPickupEta,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accentBlue.withOpacity(0.4)),
                ),
                child: Text(
                  l10n.pickupUnderMins(maxPickupMins),
                  style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.accentBlue,
              overlayColor: AppColors.accentBlue.withOpacity(0.2),
            ),
            child: Slider(
              value: maxPickupMins.toDouble(),
              min: 1,
              max: 25,
              divisions: 24,
              label: '$maxPickupMins mins',
              onChanged: (v) => onMaxPickupMinsChanged(v.toInt()),
            ),
          ),
        ],
      ),
    );
  }
}
