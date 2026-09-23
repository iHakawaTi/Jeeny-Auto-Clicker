import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Bottom sheet that walks the user through enabling the accessibility
/// service on their specific phone brand. Called AFTER we've launched
/// the settings intent, so the sheet is visible when they return.
class AccessibilityGuideSheet {
  static Future<void> show(BuildContext context,
      {required String manufacturer}) async {
    final normalized = manufacturer.toLowerCase();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final steps = _stepsFor(l10n, normalized);
        final label = manufacturer.isEmpty ? 'Android' : _pretty(manufacturer);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.accessibility,
                        color: AppColors.primaryNeon),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.accessibilityGuideTitle(label),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < steps.length; i++) ...[
                  _step(index: i + 1, text: steps[i]),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      l10n.gotIt,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _step({required int index, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
                color: AppColors.primaryNeon,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5),
          ),
        ),
      ],
    );
  }

  static List<String> _stepsFor(AppLocalizations l10n, String manufacturer) {
    if (manufacturer.contains('samsung')) {
      return [
        l10n.accessibilityGuideSamsungStep1,
        l10n.accessibilityGuideSamsungStep2,
        l10n.accessibilityGuideSamsungStep3,
      ];
    }
    if (manufacturer.contains('xiaomi') || manufacturer.contains('redmi')) {
      return [
        l10n.accessibilityGuideXiaomiStep1,
        l10n.accessibilityGuideXiaomiStep2,
        l10n.accessibilityGuideXiaomiStep3,
      ];
    }
    return [
      l10n.accessibilityGuideGenericStep1,
      l10n.accessibilityGuideGenericStep2,
      l10n.accessibilityGuideGenericStep3,
    ];
  }

  static String _pretty(String v) => v.isEmpty
      ? v
      : v[0].toUpperCase() + v.substring(1).toLowerCase();
}
