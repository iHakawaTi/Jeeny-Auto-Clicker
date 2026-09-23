import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/services/localization_service.dart';
import 'core/services/supabase_service.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/subscription/inactive_sub_screen.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService.instance.load();
  await SupabaseService.initialize();
  runApp(const JeenyAutoClickerApp());
}

class JeenyAutoClickerApp extends StatelessWidget {
  const JeenyAutoClickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Keemo',
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: LocalizationService.supportedLocales,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryNeon,
              surface: AppColors.surface,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const AuthGateScreen(),
        );
      },
    );
  }
}

/// Decides where to send the user on cold start, based on session + role
/// + subscription status. Also re-evaluates whenever we come back to it.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late Future<Widget> _decision;

  @override
  void initState() {
    super.initState();
    _decision = _resolve();
  }

  Future<Widget> _resolve() async {
    if (!SupabaseService.isConfigured) {
      return const DashboardScreen();
    }
    if (!SupabaseService.hasSession) {
      return const LoginScreen();
    }
    // Session survived from a previous run — before trusting it, re-verify
    // that this physical device is the one bound to the account.
    final deviceOk = await SupabaseService.verifyCurrentDeviceOrSignOut();
    if (!deviceOk) return const LoginScreen();

    final access = await SupabaseService.resolveAccess();
    switch (access) {
      case AccessDecision.admin:
        return const AdminDashboardScreen();
      case AccessDecision.trialActive:
      case AccessDecision.subscriptionActive:
        return const DashboardScreen();
      case AccessDecision.trialExpired:
        return const InactiveSubScreen(reason: InactiveReason.trialExpired);
      case AccessDecision.subscriptionExpired:
        return const InactiveSubScreen(reason: InactiveReason.subscriptionExpired);
      case AccessDecision.inactive:
        return const InactiveSubScreen(reason: InactiveReason.inactive);
      case AccessDecision.notLoggedIn:
        return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decision,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryNeon),
            ),
          );
        }
        return snap.data!;
      },
    );
  }
}
