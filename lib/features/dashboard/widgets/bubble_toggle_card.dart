import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/native_bridge.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A compact card with a switch that shows/hides the floating bubble.
/// The bubble itself is rendered by the accessibility service via
/// WindowManager, so this card just flips a SharedPreferences flag.
class BubbleToggleCard extends StatefulWidget {
  const BubbleToggleCard({super.key, required this.hasOverlayPermission});

  final bool hasOverlayPermission;

  @override
  State<BubbleToggleCard> createState() => _BubbleToggleCardState();
}

class _BubbleToggleCardState extends State<BubbleToggleCard> {
  bool _enabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await NativeBridge.isBubbleEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = v;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() => _enabled = v);
    await NativeBridge.setBubbleEnabled(v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEnable = widget.hasOverlayPermission;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.circle,
                  color: AppColors.primaryNeon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.floatingBubble,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Switch.adaptive(
                value: _enabled && canEnable,
                onChanged: (!_loaded || !canEnable) ? null : _toggle,
                activeThumbColor: AppColors.primaryNeon,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            canEnable
                ? l10n.floatingBubbleBody
                : l10n.floatingBubbleNeedsOverlay,
            style: TextStyle(
              color: canEnable
                  ? AppColors.textSecondary
                  : AppColors.alertAmber,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
