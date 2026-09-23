import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/app_colors.dart';
import '../services/localization_service.dart';

/// A compact language switcher shown top-right on every screen.
/// Shows the *other* language as a hint (so the user knows what tapping does).
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.locale,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        final label = isAr ? 'EN' : 'ع';
        final tone = color ?? AppColors.textPrimary;

        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => LocalizationService.instance.toggle(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.globe, size: 16, color: tone),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: tone,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
