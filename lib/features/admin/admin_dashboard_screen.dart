import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/language_toggle_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/driver_row.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<Map<String, dynamic>> _drivers = const [];
  Map<String, dynamic>? _adminSettings;
  bool _loading = true;
  String _search = '';

  final _whatsappCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _whatsappCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      SupabaseService.listAllDrivers(),
      SupabaseService.getAdminSettings(),
    ]);
    if (!mounted) return;
    setState(() {
      _drivers = results[0] as List<Map<String, dynamic>>;
      _adminSettings = results[1] as Map<String, dynamic>?;
      _whatsappCtrl.text =
          (_adminSettings?['admin_whatsapp_number'] as String?) ?? '';
      _displayNameCtrl.text =
          (_adminSettings?['admin_display_name'] as String?) ?? '';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(l10n.adminDashboard,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw,
                color: AppColors.textSecondary, size: 20),
            onPressed: _refresh,
          ),
          // Switch to the regular driver dashboard — admins can use
          // auto-accept themselves too.
          IconButton(
            tooltip: l10n.switchToDriverView,
            icon: const Icon(LucideIcons.car,
                color: AppColors.textSecondary, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DashboardScreen()),
              );
            },
          ),
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(LucideIcons.logOut,
                color: AppColors.textSecondary, size: 20),
            onPressed: () async {
              await SupabaseService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primaryNeon,
          labelColor: AppColors.primaryNeon,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.tabDrivers),
            Tab(text: l10n.tabOverview),
            Tab(text: l10n.tabSettings),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primaryNeon))
          : TabBarView(
              controller: _tabs,
              children: [
                _driversTab(l10n),
                _overviewTab(l10n),
                _settingsTab(l10n),
              ],
            ),
    );
  }

  // ------------------- Drivers Tab -------------------

  Widget _driversTab(AppLocalizations l10n) {
    final filtered = _drivers.where((d) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return ((d['email'] as String?)?.toLowerCase().contains(q) ?? false) ||
          ((d['full_name'] as String?)?.toLowerCase().contains(q) ?? false) ||
          ((d['phone_number'] as String?)?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.searchDrivers,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(LucideIcons.search,
                  color: AppColors.textSecondary, size: 18),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.cardBorder),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(l10n.noDriversYet,
                      style: const TextStyle(
                          color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => DriverRow(
                    driver: filtered[i],
                    onActivate: () =>
                        _confirmActivate(filtered[i], l10n),
                    onExtend: () => _promptExtend(filtered[i], l10n),
                    onDeactivate: () =>
                        _confirmDeactivate(filtered[i], l10n),
                    onResetDevice: () =>
                        _confirmResetDevice(filtered[i], l10n),
                    onWhatsapp: () => _messageDriver(filtered[i], l10n),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmActivate(
      Map<String, dynamic> driver, AppLocalizations l10n) async {
    final name = (driver['full_name'] as String?) ??
        (driver['email'] as String?) ??
        '';
    final ok = await _confirm(l10n.confirmActivate(name), l10n);
    if (!ok) return;
    await SupabaseService.adminActivateOneMonth(driver['id']);
    _refresh();
  }

  Future<void> _promptExtend(
      Map<String, dynamic> driver, AppLocalizations l10n) async {
    final ctrl = TextEditingController(text: '30');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.extendDays,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '30',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(ctrl.text) ?? 30),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (result == null) return;
    await SupabaseService.adminExtend(driver['id'], result);
    _refresh();
  }

  Future<void> _confirmDeactivate(
      Map<String, dynamic> driver, AppLocalizations l10n) async {
    final name = (driver['full_name'] as String?) ??
        (driver['email'] as String?) ??
        '';
    final ok = await _confirm(l10n.confirmDeactivate(name), l10n);
    if (!ok) return;
    await SupabaseService.adminDeactivate(driver['id']);
    _refresh();
  }

  Future<void> _confirmResetDevice(
      Map<String, dynamic> driver, AppLocalizations l10n) async {
    final name = (driver['full_name'] as String?) ??
        (driver['email'] as String?) ??
        '';
    final ok = await _confirm(l10n.confirmResetDevice(name), l10n);
    if (!ok) return;
    await SupabaseService.adminResetDevice(driver['id']);
    _refresh();
  }

  Future<bool> _confirm(String message, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Text(message,
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNeon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm,
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _messageDriver(
      Map<String, dynamic> driver, AppLocalizations l10n) async {
    final phone = (driver['phone_number'] as String?) ?? '';
    if (phone.trim().isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = digits.startsWith('0') ? '962${digits.substring(1)}' : digits;
    final uri = Uri.parse('https://wa.me/$normalized');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ------------------- Overview Tab -------------------

  Widget _overviewTab(AppLocalizations l10n) {
    final total = _drivers.length;
    int trial = 0, active = 0, expired = 0;
    int activationsThisMonth = 0;
    final now = DateTime.now();

    for (final d in _drivers) {
      final status = d['subscription_status'] as String?;
      if (status == 'trial') trial++;
      if (status == 'active') active++;
      if (status == 'expired') expired++;

      final updated = DateTime.tryParse(d['updated_at'] as String? ?? '');
      if (status == 'active' &&
          updated != null &&
          updated.year == now.year &&
          updated.month == now.month) {
        activationsThisMonth++;
      }
    }

    final tiles = [
      _StatTile(label: l10n.totalDrivers, value: total.toString(), color: AppColors.primaryNeon),
      _StatTile(label: l10n.trialDrivers, value: trial.toString(), color: AppColors.accentBlue),
      _StatTile(label: l10n.activeDrivers, value: active.toString(), color: AppColors.primaryNeon),
      _StatTile(label: l10n.expiredDrivers, value: expired.toString(), color: AppColors.warningRed),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: tiles,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.trendingUp,
                    color: AppColors.primaryNeon, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.activationsThisMonth,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
                Text(
                  '$activationsThisMonth',
                  style: const TextStyle(
                      color: AppColors.primaryNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- Settings Tab -------------------

  Widget _settingsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labeledField(l10n.adminWhatsappNumber, _whatsappCtrl,
              keyboard: TextInputType.phone, hint: '9627XXXXXXXX'),
          const SizedBox(height: 12),
          _labeledField(l10n.adminDisplayName, _displayNameCtrl),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNeon,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(LucideIcons.save, color: Colors.black),
            label: Text(l10n.save,
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              await SupabaseService.updateAdminSettings(
                whatsappNumber: _whatsappCtrl.text.trim(),
                displayName: _displayNameCtrl.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.saved)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController ctrl,
      {TextInputType? keyboard, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryNeon),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
