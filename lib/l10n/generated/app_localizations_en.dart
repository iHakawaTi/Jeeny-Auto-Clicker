// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Jeeny Auto-Clicker';

  @override
  String get appTagline => 'Jeeny Auto-Clicker';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInSubtitle =>
      'Sign in to access your auto-accept driver panel';

  @override
  String get signOut => 'Sign Out';

  @override
  String get register => 'Register';

  @override
  String get registerNow => 'Register Now';

  @override
  String get createAccount => 'Create Account';

  @override
  String get createDriverAccount => 'Create Driver Account';

  @override
  String get registerSubtitle =>
      'Register your profile to set up auto-accept criteria';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number (e.g. 079XXXXXXX)';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get driverEmail => 'Driver Email';

  @override
  String get password => 'Password';

  @override
  String get trialActive => 'Trial Active';

  @override
  String get trialActiveBody =>
      'Your 48-hour trial is running. Enjoy full auto-accept.';

  @override
  String trialTimeLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m left on trial';
  }

  @override
  String subscriptionActiveDaysLeft(int days) {
    return '$days days left on subscription';
  }

  @override
  String get trialExpiredTitle => 'Trial Expired';

  @override
  String get trialExpiredBody =>
      'Your 48-hour free trial has ended. Contact the admin to activate a monthly subscription.';

  @override
  String get subscriptionInactiveTitle => 'Subscription Inactive';

  @override
  String get subscriptionInactiveBody =>
      'Your account is registered but requires an active monthly subscription approved by the administrator.';

  @override
  String get subscriptionExpiredTitle => 'Subscription Expired';

  @override
  String get subscriptionExpiredBody =>
      'Your monthly subscription has ended. Contact the admin to renew.';

  @override
  String get accountStatus => 'Account Status:';

  @override
  String get autoAcceptService => 'Auto-Accept Service:';

  @override
  String get statusInactive => 'INACTIVE';

  @override
  String get statusExpired => 'EXPIRED';

  @override
  String get statusLocked => 'LOCKED';

  @override
  String get refreshStatus => 'Refresh Subscription Status';

  @override
  String get checking => 'Checking...';

  @override
  String get messageAdminWhatsApp => 'Message Admin on WhatsApp';

  @override
  String get adminWhatsAppUnavailable =>
      'Admin has not set a WhatsApp number yet. Please contact them another way.';

  @override
  String adminMessageTemplate(String name, String email, String phone) {
    return 'Hi, this is $name ($email, $phone). I would like to activate my Jeeny Auto-Clicker subscription.';
  }

  @override
  String get subscriptionStillInactive =>
      'Subscription still inactive. Please contact Admin.';

  @override
  String get autoAcceptActive => 'AUTO-ACCEPT ACTIVE';

  @override
  String get autoAcceptOff => 'AUTO-ACCEPT OFF';

  @override
  String get scanningJeeny => 'Scanning Jeeny screen for qualifying orders...';

  @override
  String get turnOnSwitch => 'Turn on switch to start auto-accepting orders';

  @override
  String get autoAcceptCriteria => 'Auto-Accept Criteria';

  @override
  String get minimumTripPrice => 'Minimum Trip Price:';

  @override
  String get maxPickupEta => 'Max Pickup ETA / Distance:';

  @override
  String farePlusSuffix(String fare) {
    return '$fare JDs +';
  }

  @override
  String pickupUnderMins(int mins) {
    return '≤ $mins mins';
  }

  @override
  String acceptedOrderPrefix(String fare) {
    return 'Accepted Order: $fare';
  }

  @override
  String pickupEtaLabel(String time) {
    return 'Pickup ETA: $time';
  }

  @override
  String get systemReady => 'System Ready & Operational';

  @override
  String get systemReadyBody =>
      'Accessibility Service is listening for Jeeny orders';

  @override
  String get actionRequired => 'Action Required';

  @override
  String get actionRequiredBody =>
      'Some permissions or subscription checks are missing';

  @override
  String get grantMissingPermissions => 'GRANT MISSING PERMISSIONS';

  @override
  String get subActive => 'Sub Active';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get overlay => 'Overlay';

  @override
  String get batteryOpt => 'Battery';

  @override
  String get autoStartLabel => 'Auto-Start';

  @override
  String get recentActivity => 'Recent Activity & Accepted Orders';

  @override
  String get noOrdersYet => 'No orders accepted yet';

  @override
  String get turnOnMasterAndOpenJeeny =>
      'Turn on master switch & open Jeeny app';

  @override
  String get requiredPermissions => 'Required Permissions';

  @override
  String get permissionsIntro =>
      'To read Jeeny order requests and auto-accept them, Android requires system permissions:';

  @override
  String get accessibilityTitle => '1. Accessibility Service';

  @override
  String get accessibilityBody =>
      'Allows the app to read Jeeny screen order prices & pickup times and click Accept.';

  @override
  String get overlayTitle => '2. Overlay / System Alert Window';

  @override
  String get overlayBody =>
      'Allows the app to operate continuously over the Jeeny driver application.';

  @override
  String get batteryOptTitle => '3. Battery Optimization Exemption';

  @override
  String get batteryOptBody =>
      'Prevents Android from silently killing the auto-accept service after a while.';

  @override
  String get autoStartTitle => '4. Auto-Start (Xiaomi / Huawei / OPPO / Vivo)';

  @override
  String get autoStartBody =>
      'Some phones need an extra toggle so the service can start after reboot. Skip if not applicable.';

  @override
  String get granted => 'GRANTED';

  @override
  String get actionNeeded => 'ACTION NEEDED';

  @override
  String get notApplicable => 'N/A';

  @override
  String get openSystemSettings => 'OPEN SYSTEM SETTINGS';

  @override
  String get continueToDashboard => 'CONTINUE TO DASHBOARD';

  @override
  String get grantAllToProceed => 'GRANT ALL PERMISSIONS TO PROCEED';

  @override
  String accessibilityGuideTitle(String manufacturer) {
    return 'How to enable on your $manufacturer';
  }

  @override
  String get accessibilityGuideGenericStep1 =>
      'Find «Installed apps» or «Downloaded services» in Accessibility.';

  @override
  String get accessibilityGuideGenericStep2 =>
      'Tap «Keemo Auto-Accept Engine».';

  @override
  String get accessibilityGuideGenericStep3 =>
      'Turn the switch ON and confirm.';

  @override
  String get accessibilityGuideSamsungStep1 =>
      'Open Installed apps in Accessibility.';

  @override
  String get accessibilityGuideSamsungStep2 =>
      'Tap «Keemo Auto-Accept Engine».';

  @override
  String get accessibilityGuideSamsungStep3 => 'Toggle it ON, then tap Allow.';

  @override
  String get accessibilityGuideXiaomiStep1 => 'Scroll to Downloaded services.';

  @override
  String get accessibilityGuideXiaomiStep2 =>
      'Tap Keemo, enable it and confirm the warning.';

  @override
  String get accessibilityGuideXiaomiStep3 =>
      'Return to Keemo — you should see «Granted».';

  @override
  String get gotIt => 'GOT IT';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get orderHistory => 'Order History';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get trialLabel => 'Trial';

  @override
  String get activeLabel => 'Active';

  @override
  String get expiredLabel => 'Expired';

  @override
  String get inactiveLabel => 'Inactive';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get tabDrivers => 'Drivers';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabSettings => 'Settings';

  @override
  String get searchDrivers => 'Search drivers…';

  @override
  String get activateOneMonth => 'Activate 1 Month';

  @override
  String get extend => 'Extend';

  @override
  String get extendDays => 'Extend by days';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get resetDevice => 'Reset Device';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get totalDrivers => 'Total Drivers';

  @override
  String get trialDrivers => 'On Trial';

  @override
  String get activeDrivers => 'Active';

  @override
  String get expiredDrivers => 'Expired';

  @override
  String get activationsThisMonth => 'Activations this month';

  @override
  String get adminWhatsappNumber => 'Admin WhatsApp Number';

  @override
  String get adminDisplayName => 'Admin Display Name';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String confirmActivate(String name) {
    return 'Activate $name for 1 month?';
  }

  @override
  String confirmDeactivate(String name) {
    return 'Deactivate $name? They will lose access immediately.';
  }

  @override
  String confirmResetDevice(String name) {
    return 'Reset device binding for $name? They will be able to log in from a new phone.';
  }

  @override
  String get noDriversYet => 'No drivers registered yet.';

  @override
  String get errorDeviceAlreadyRegistered =>
      'This device is already registered to another account. Contact admin.';

  @override
  String errorLockedToDifferentDevice(String model) {
    return 'Account locked to another Android device ($model). Contact Admin to reset your device binding.';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get unknown => '—';

  @override
  String get floatingBubble => 'Floating Toggle Button';

  @override
  String get floatingBubbleBody =>
      'Show a draggable green/red bubble over other apps. Tap it to turn auto-accept on/off without opening Keemo.';

  @override
  String get floatingBubbleNeedsOverlay =>
      'Grant the Overlay permission first so the bubble can appear over Jeeny.';

  @override
  String get deviceMismatchTitle => 'This device is not your registered device';

  @override
  String get deviceMismatchBody =>
      'Your account is locked to a different Android device. Ask the admin to reset your device binding, then try again.';

  @override
  String get switchToDriverView => 'Driver View';

  @override
  String get switchToAdminView => 'Admin Dashboard';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordBody =>
      'Enter your account email. We\'ll send you a link to set a new password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent =>
      'Check your email — the reset link has been sent.';

  @override
  String get backToLogin => 'Back to Sign In';
}
