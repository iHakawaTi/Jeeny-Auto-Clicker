import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Jeeny Auto-Clicker'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Jeeny Auto-Clicker'**
  String get appTagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your auto-accept driver panel'**
  String get signInSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNow;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createDriverAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Driver Account'**
  String get createDriverAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your profile to set up auto-accept criteria'**
  String get registerSubtitle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (e.g. 079XXXXXXX)'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @driverEmail.
  ///
  /// In en, this message translates to:
  /// **'Driver Email'**
  String get driverEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @trialActive.
  ///
  /// In en, this message translates to:
  /// **'Trial Active'**
  String get trialActive;

  /// No description provided for @trialActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your 48-hour trial is running. Enjoy full auto-accept.'**
  String get trialActiveBody;

  /// No description provided for @trialTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left on trial'**
  String trialTimeLeft(int hours, int minutes);

  /// No description provided for @subscriptionActiveDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left on subscription'**
  String subscriptionActiveDaysLeft(int days);

  /// No description provided for @trialExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial Expired'**
  String get trialExpiredTitle;

  /// No description provided for @trialExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your 48-hour free trial has ended. Contact the admin to activate a monthly subscription.'**
  String get trialExpiredBody;

  /// No description provided for @subscriptionInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Inactive'**
  String get subscriptionInactiveTitle;

  /// No description provided for @subscriptionInactiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is registered but requires an active monthly subscription approved by the administrator.'**
  String get subscriptionInactiveBody;

  /// No description provided for @subscriptionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpiredTitle;

  /// No description provided for @subscriptionExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your monthly subscription has ended. Contact the admin to renew.'**
  String get subscriptionExpiredBody;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status:'**
  String get accountStatus;

  /// No description provided for @autoAcceptService.
  ///
  /// In en, this message translates to:
  /// **'Auto-Accept Service:'**
  String get autoAcceptService;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get statusInactive;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get statusExpired;

  /// No description provided for @statusLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get statusLocked;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Subscription Status'**
  String get refreshStatus;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @messageAdminWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message Admin on WhatsApp'**
  String get messageAdminWhatsApp;

  /// No description provided for @adminWhatsAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Admin has not set a WhatsApp number yet. Please contact them another way.'**
  String get adminWhatsAppUnavailable;

  /// No description provided for @adminMessageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Hi, this is {name} ({email}, {phone}). I would like to activate my Jeeny Auto-Clicker subscription.'**
  String adminMessageTemplate(String name, String email, String phone);

  /// No description provided for @subscriptionStillInactive.
  ///
  /// In en, this message translates to:
  /// **'Subscription still inactive. Please contact Admin.'**
  String get subscriptionStillInactive;

  /// No description provided for @autoAcceptActive.
  ///
  /// In en, this message translates to:
  /// **'AUTO-ACCEPT ACTIVE'**
  String get autoAcceptActive;

  /// No description provided for @autoAcceptOff.
  ///
  /// In en, this message translates to:
  /// **'AUTO-ACCEPT OFF'**
  String get autoAcceptOff;

  /// No description provided for @scanningJeeny.
  ///
  /// In en, this message translates to:
  /// **'Scanning Jeeny screen for qualifying orders...'**
  String get scanningJeeny;

  /// No description provided for @turnOnSwitch.
  ///
  /// In en, this message translates to:
  /// **'Turn on switch to start auto-accepting orders'**
  String get turnOnSwitch;

  /// No description provided for @autoAcceptCriteria.
  ///
  /// In en, this message translates to:
  /// **'Auto-Accept Criteria'**
  String get autoAcceptCriteria;

  /// No description provided for @minimumTripPrice.
  ///
  /// In en, this message translates to:
  /// **'Minimum Trip Price:'**
  String get minimumTripPrice;

  /// No description provided for @maxPickupEta.
  ///
  /// In en, this message translates to:
  /// **'Max Pickup ETA / Distance:'**
  String get maxPickupEta;

  /// No description provided for @farePlusSuffix.
  ///
  /// In en, this message translates to:
  /// **'{fare} JDs +'**
  String farePlusSuffix(String fare);

  /// No description provided for @pickupUnderMins.
  ///
  /// In en, this message translates to:
  /// **'≤ {mins} mins'**
  String pickupUnderMins(int mins);

  /// No description provided for @acceptedOrderPrefix.
  ///
  /// In en, this message translates to:
  /// **'Accepted Order: {fare}'**
  String acceptedOrderPrefix(String fare);

  /// No description provided for @pickupEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup ETA: {time}'**
  String pickupEtaLabel(String time);

  /// No description provided for @systemReady.
  ///
  /// In en, this message translates to:
  /// **'System Ready & Operational'**
  String get systemReady;

  /// No description provided for @systemReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service is listening for Jeeny orders'**
  String get systemReadyBody;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @actionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Some permissions or subscription checks are missing'**
  String get actionRequiredBody;

  /// No description provided for @grantMissingPermissions.
  ///
  /// In en, this message translates to:
  /// **'GRANT MISSING PERMISSIONS'**
  String get grantMissingPermissions;

  /// No description provided for @subActive.
  ///
  /// In en, this message translates to:
  /// **'Sub Active'**
  String get subActive;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @overlay.
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get overlay;

  /// No description provided for @batteryOpt.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get batteryOpt;

  /// No description provided for @autoStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-Start'**
  String get autoStartLabel;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity & Accepted Orders'**
  String get recentActivity;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders accepted yet'**
  String get noOrdersYet;

  /// No description provided for @turnOnMasterAndOpenJeeny.
  ///
  /// In en, this message translates to:
  /// **'Turn on master switch & open Jeeny app'**
  String get turnOnMasterAndOpenJeeny;

  /// No description provided for @requiredPermissions.
  ///
  /// In en, this message translates to:
  /// **'Required Permissions'**
  String get requiredPermissions;

  /// No description provided for @permissionsIntro.
  ///
  /// In en, this message translates to:
  /// **'To read Jeeny order requests and auto-accept them, Android requires system permissions:'**
  String get permissionsIntro;

  /// No description provided for @accessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Accessibility Service'**
  String get accessibilityTitle;

  /// No description provided for @accessibilityBody.
  ///
  /// In en, this message translates to:
  /// **'Allows the app to read Jeeny screen order prices & pickup times and click Accept.'**
  String get accessibilityBody;

  /// No description provided for @overlayTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Overlay / System Alert Window'**
  String get overlayTitle;

  /// No description provided for @overlayBody.
  ///
  /// In en, this message translates to:
  /// **'Allows the app to operate continuously over the Jeeny driver application.'**
  String get overlayBody;

  /// No description provided for @batteryOptTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Battery Optimization Exemption'**
  String get batteryOptTitle;

  /// No description provided for @batteryOptBody.
  ///
  /// In en, this message translates to:
  /// **'Prevents Android from silently killing the auto-accept service after a while.'**
  String get batteryOptBody;

  /// No description provided for @autoStartTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Auto-Start (Xiaomi / Huawei / OPPO / Vivo)'**
  String get autoStartTitle;

  /// No description provided for @autoStartBody.
  ///
  /// In en, this message translates to:
  /// **'Some phones need an extra toggle so the service can start after reboot. Skip if not applicable.'**
  String get autoStartBody;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'GRANTED'**
  String get granted;

  /// No description provided for @actionNeeded.
  ///
  /// In en, this message translates to:
  /// **'ACTION NEEDED'**
  String get actionNeeded;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notApplicable;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'OPEN SYSTEM SETTINGS'**
  String get openSystemSettings;

  /// No description provided for @continueToDashboard.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE TO DASHBOARD'**
  String get continueToDashboard;

  /// No description provided for @grantAllToProceed.
  ///
  /// In en, this message translates to:
  /// **'GRANT ALL PERMISSIONS TO PROCEED'**
  String get grantAllToProceed;

  /// No description provided for @accessibilityGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to enable on your {manufacturer}'**
  String accessibilityGuideTitle(String manufacturer);

  /// No description provided for @accessibilityGuideGenericStep1.
  ///
  /// In en, this message translates to:
  /// **'Find «Installed apps» or «Downloaded services» in Accessibility.'**
  String get accessibilityGuideGenericStep1;

  /// No description provided for @accessibilityGuideGenericStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap «Keemo Auto-Accept Engine».'**
  String get accessibilityGuideGenericStep2;

  /// No description provided for @accessibilityGuideGenericStep3.
  ///
  /// In en, this message translates to:
  /// **'Turn the switch ON and confirm.'**
  String get accessibilityGuideGenericStep3;

  /// No description provided for @accessibilityGuideSamsungStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Installed apps in Accessibility.'**
  String get accessibilityGuideSamsungStep1;

  /// No description provided for @accessibilityGuideSamsungStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap «Keemo Auto-Accept Engine».'**
  String get accessibilityGuideSamsungStep2;

  /// No description provided for @accessibilityGuideSamsungStep3.
  ///
  /// In en, this message translates to:
  /// **'Toggle it ON, then tap Allow.'**
  String get accessibilityGuideSamsungStep3;

  /// No description provided for @accessibilityGuideXiaomiStep1.
  ///
  /// In en, this message translates to:
  /// **'Scroll to Downloaded services.'**
  String get accessibilityGuideXiaomiStep1;

  /// No description provided for @accessibilityGuideXiaomiStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap Keemo, enable it and confirm the warning.'**
  String get accessibilityGuideXiaomiStep2;

  /// No description provided for @accessibilityGuideXiaomiStep3.
  ///
  /// In en, this message translates to:
  /// **'Return to Keemo — you should see «Granted».'**
  String get accessibilityGuideXiaomiStep3;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'GOT IT'**
  String get gotIt;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @trialLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trialLabel;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredLabel;

  /// No description provided for @inactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveLabel;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @tabDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get tabDrivers;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @searchDrivers.
  ///
  /// In en, this message translates to:
  /// **'Search drivers…'**
  String get searchDrivers;

  /// No description provided for @activateOneMonth.
  ///
  /// In en, this message translates to:
  /// **'Activate 1 Month'**
  String get activateOneMonth;

  /// No description provided for @extend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get extend;

  /// No description provided for @extendDays.
  ///
  /// In en, this message translates to:
  /// **'Extend by days'**
  String get extendDays;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @resetDevice.
  ///
  /// In en, this message translates to:
  /// **'Reset Device'**
  String get resetDevice;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @totalDrivers.
  ///
  /// In en, this message translates to:
  /// **'Total Drivers'**
  String get totalDrivers;

  /// No description provided for @trialDrivers.
  ///
  /// In en, this message translates to:
  /// **'On Trial'**
  String get trialDrivers;

  /// No description provided for @activeDrivers.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeDrivers;

  /// No description provided for @expiredDrivers.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredDrivers;

  /// No description provided for @activationsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Activations this month'**
  String get activationsThisMonth;

  /// No description provided for @adminWhatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'Admin WhatsApp Number'**
  String get adminWhatsappNumber;

  /// No description provided for @adminDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Admin Display Name'**
  String get adminDisplayName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @confirmActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate {name} for 1 month?'**
  String confirmActivate(String name);

  /// No description provided for @confirmDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}? They will lose access immediately.'**
  String confirmDeactivate(String name);

  /// No description provided for @confirmResetDevice.
  ///
  /// In en, this message translates to:
  /// **'Reset device binding for {name}? They will be able to log in from a new phone.'**
  String confirmResetDevice(String name);

  /// No description provided for @noDriversYet.
  ///
  /// In en, this message translates to:
  /// **'No drivers registered yet.'**
  String get noDriversYet;

  /// No description provided for @errorDeviceAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This device is already registered to another account. Contact admin.'**
  String get errorDeviceAlreadyRegistered;

  /// No description provided for @errorLockedToDifferentDevice.
  ///
  /// In en, this message translates to:
  /// **'Account locked to another Android device ({model}). Contact Admin to reset your device binding.'**
  String errorLockedToDifferentDevice(String model);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get unknown;

  /// No description provided for @floatingBubble.
  ///
  /// In en, this message translates to:
  /// **'Floating Toggle Button'**
  String get floatingBubble;

  /// No description provided for @floatingBubbleBody.
  ///
  /// In en, this message translates to:
  /// **'Show a draggable green/red bubble over other apps. Tap it to turn auto-accept on/off without opening Keemo.'**
  String get floatingBubbleBody;

  /// No description provided for @floatingBubbleNeedsOverlay.
  ///
  /// In en, this message translates to:
  /// **'Grant the Overlay permission first so the bubble can appear over Jeeny.'**
  String get floatingBubbleNeedsOverlay;

  /// No description provided for @deviceMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'This device is not your registered device'**
  String get deviceMismatchTitle;

  /// No description provided for @deviceMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is locked to a different Android device. Ask the admin to reset your device binding, then try again.'**
  String get deviceMismatchBody;

  /// No description provided for @switchToDriverView.
  ///
  /// In en, this message translates to:
  /// **'Driver View'**
  String get switchToDriverView;

  /// No description provided for @switchToAdminView.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get switchToAdminView;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email. We\'ll send you a link to set a new password.'**
  String get forgotPasswordBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email — the reset link has been sent.'**
  String get resetLinkSent;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToLogin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
