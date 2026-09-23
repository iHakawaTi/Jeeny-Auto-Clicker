// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'النقر التلقائي لجيني';

  @override
  String get appTagline => 'النقر التلقائي لجيني';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInSubtitle => 'سجّل الدخول للوصول إلى لوحة القبول التلقائي';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get registerNow => 'أنشئ حسابًا الآن';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get createDriverAccount => 'إنشاء حساب سائق';

  @override
  String get registerSubtitle => 'سجّل بياناتك لضبط معايير القبول التلقائي';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف (مثال: 079XXXXXXX)';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get driverEmail => 'البريد الإلكتروني للسائق';

  @override
  String get password => 'كلمة المرور';

  @override
  String get trialActive => 'الفترة التجريبية مفعّلة';

  @override
  String get trialActiveBody => 'لديك 48 ساعة تجربة كاملة الصلاحيات.';

  @override
  String trialTimeLeft(int hours, int minutes) {
    return 'متبقٍّ $hoursس $minutesد على انتهاء التجربة';
  }

  @override
  String subscriptionActiveDaysLeft(int days) {
    return 'متبقٍّ $days يومًا على الاشتراك';
  }

  @override
  String get trialExpiredTitle => 'انتهت الفترة التجريبية';

  @override
  String get trialExpiredBody =>
      'انتهت الـ 48 ساعة المجانية. تواصل مع المشرف لتفعيل اشتراك شهري.';

  @override
  String get subscriptionInactiveTitle => 'الاشتراك غير مفعّل';

  @override
  String get subscriptionInactiveBody =>
      'حسابك مسجّل ولكن يتطلب اشتراكًا شهريًا مفعّلًا من قِبل المشرف.';

  @override
  String get subscriptionExpiredTitle => 'انتهى الاشتراك';

  @override
  String get subscriptionExpiredBody =>
      'انتهى اشتراكك الشهري. تواصل مع المشرف للتجديد.';

  @override
  String get accountStatus => 'حالة الحساب:';

  @override
  String get autoAcceptService => 'خدمة القبول التلقائي:';

  @override
  String get statusInactive => 'غير مفعّل';

  @override
  String get statusExpired => 'منتهٍ';

  @override
  String get statusLocked => 'مقفول';

  @override
  String get refreshStatus => 'تحديث حالة الاشتراك';

  @override
  String get checking => 'جارٍ التحقق...';

  @override
  String get messageAdminWhatsApp => 'مراسلة المشرف عبر واتساب';

  @override
  String get adminWhatsAppUnavailable =>
      'لم يُضِف المشرف رقم واتساب بعد. تواصل معه بطريقة أخرى.';

  @override
  String adminMessageTemplate(String name, String email, String phone) {
    return 'مرحبًا، أنا $name ($email, $phone). أرغب في تفعيل اشتراكي في تطبيق النقر التلقائي لجيني.';
  }

  @override
  String get subscriptionStillInactive =>
      'الاشتراك لا يزال غير مفعّل. تواصل مع المشرف.';

  @override
  String get autoAcceptActive => 'القبول التلقائي مفعّل';

  @override
  String get autoAcceptOff => 'القبول التلقائي متوقّف';

  @override
  String get scanningJeeny => 'يجري فحص شاشة جيني للطلبات المطابقة...';

  @override
  String get turnOnSwitch => 'فعّل المفتاح لبدء قبول الطلبات تلقائيًا';

  @override
  String get autoAcceptCriteria => 'معايير القبول التلقائي';

  @override
  String get minimumTripPrice => 'أقل سعر للرحلة:';

  @override
  String get maxPickupEta => 'أقصى وقت وصول للمسافر:';

  @override
  String farePlusSuffix(String fare) {
    return '$fare د.أ +';
  }

  @override
  String pickupUnderMins(int mins) {
    return '≤ $mins دقيقة';
  }

  @override
  String acceptedOrderPrefix(String fare) {
    return 'تم قبول طلب: $fare';
  }

  @override
  String pickupEtaLabel(String time) {
    return 'وقت الوصول: $time';
  }

  @override
  String get systemReady => 'النظام جاهز ويعمل';

  @override
  String get systemReadyBody => 'خدمة إمكانية الوصول تراقب طلبات جيني';

  @override
  String get actionRequired => 'إجراء مطلوب';

  @override
  String get actionRequiredBody => 'بعض الأذونات أو التحقق من الاشتراك مفقودة';

  @override
  String get grantMissingPermissions => 'منح الأذونات المفقودة';

  @override
  String get subActive => 'الاشتراك';

  @override
  String get accessibility => 'إمكانية الوصول';

  @override
  String get overlay => 'طبقة';

  @override
  String get batteryOpt => 'البطارية';

  @override
  String get autoStartLabel => 'التشغيل التلقائي';

  @override
  String get recentActivity => 'النشاط الأخير والطلبات المقبولة';

  @override
  String get noOrdersYet => 'لم يتم قبول أي طلب بعد';

  @override
  String get turnOnMasterAndOpenJeeny => 'فعّل المفتاح وافتح تطبيق جيني';

  @override
  String get requiredPermissions => 'الأذونات المطلوبة';

  @override
  String get permissionsIntro =>
      'لقراءة طلبات جيني وقبولها تلقائيًا، يتطلّب أندرويد بعض الأذونات:';

  @override
  String get accessibilityTitle => '1. خدمة إمكانية الوصول';

  @override
  String get accessibilityBody =>
      'تُتيح للتطبيق قراءة أسعار وأوقات طلبات جيني والنقر على قبول.';

  @override
  String get overlayTitle => '2. الرسم فوق التطبيقات';

  @override
  String get overlayBody =>
      'تُتيح للتطبيق العمل بشكل مستمر فوق تطبيق سائق جيني.';

  @override
  String get batteryOptTitle => '3. استثناء تحسين البطارية';

  @override
  String get batteryOptBody =>
      'يمنع أندرويد من إيقاف خدمة القبول التلقائي بصمت بعد فترة.';

  @override
  String get autoStartTitle =>
      '4. التشغيل التلقائي (Xiaomi / Huawei / OPPO / Vivo)';

  @override
  String get autoStartBody =>
      'بعض الأجهزة تحتاج تفعيلًا إضافيًا لكي تعمل الخدمة بعد إعادة التشغيل. تجاهل إن لم يظهر.';

  @override
  String get granted => 'تم المنح';

  @override
  String get actionNeeded => 'يتطلب إجراء';

  @override
  String get notApplicable => 'غير متاح';

  @override
  String get openSystemSettings => 'فتح إعدادات النظام';

  @override
  String get continueToDashboard => 'المتابعة إلى لوحة التحكم';

  @override
  String get grantAllToProceed => 'امنح جميع الأذونات للمتابعة';

  @override
  String accessibilityGuideTitle(String manufacturer) {
    return 'طريقة التفعيل على جهاز $manufacturer';
  }

  @override
  String get accessibilityGuideGenericStep1 =>
      'ابحث عن «التطبيقات المثبتة» أو «الخدمات المُنزّلة» داخل إمكانية الوصول.';

  @override
  String get accessibilityGuideGenericStep2 =>
      'اضغط على «Keemo Auto-Accept Engine».';

  @override
  String get accessibilityGuideGenericStep3 => 'فعّل المفتاح وأكّد.';

  @override
  String get accessibilityGuideSamsungStep1 =>
      'افتح «التطبيقات المثبتة» داخل إمكانية الوصول.';

  @override
  String get accessibilityGuideSamsungStep2 =>
      'اضغط «Keemo Auto-Accept Engine».';

  @override
  String get accessibilityGuideSamsungStep3 => 'فعّل المفتاح ثم اضغط «سماح».';

  @override
  String get accessibilityGuideXiaomiStep1 => 'انزل إلى «الخدمات المُنزّلة».';

  @override
  String get accessibilityGuideXiaomiStep2 =>
      'اضغط على كيمو، فعّلها وأكّد التحذير.';

  @override
  String get accessibilityGuideXiaomiStep3 =>
      'ارجع إلى كيمو، يجب أن تظهر حالة «تم المنح».';

  @override
  String get gotIt => 'فهمت';

  @override
  String get accountDetails => 'بيانات الحساب';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get appVersionLabel => 'إصدار التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get trialLabel => 'تجربة';

  @override
  String get activeLabel => 'نشط';

  @override
  String get expiredLabel => 'منتهٍ';

  @override
  String get inactiveLabel => 'غير مفعّل';

  @override
  String get adminDashboard => 'لوحة المشرف';

  @override
  String get tabDrivers => 'السائقون';

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get searchDrivers => 'ابحث عن سائق…';

  @override
  String get activateOneMonth => 'تفعيل شهر';

  @override
  String get extend => 'تمديد';

  @override
  String get extendDays => 'تمديد بأيام';

  @override
  String get deactivate => 'إلغاء التفعيل';

  @override
  String get resetDevice => 'إعادة تعيين الجهاز';

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get totalDrivers => 'إجمالي السائقين';

  @override
  String get trialDrivers => 'قيد التجربة';

  @override
  String get activeDrivers => 'مفعّلون';

  @override
  String get expiredDrivers => 'منتهون';

  @override
  String get activationsThisMonth => 'التفعيلات هذا الشهر';

  @override
  String get adminWhatsappNumber => 'رقم واتساب المشرف';

  @override
  String get adminDisplayName => 'اسم المشرف';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'تم الحفظ';

  @override
  String confirmActivate(String name) {
    return 'تفعيل $name لمدة شهر؟';
  }

  @override
  String confirmDeactivate(String name) {
    return 'إلغاء تفعيل $name؟ سيتم منعه فورًا.';
  }

  @override
  String confirmResetDevice(String name) {
    return 'إعادة تعيين ربط الجهاز لـ $name؟ سيتمكّن من الدخول من هاتف جديد.';
  }

  @override
  String get noDriversYet => 'لا يوجد سائقون مسجّلون بعد.';

  @override
  String get errorDeviceAlreadyRegistered =>
      'هذا الجهاز مسجّل مسبقًا لحساب آخر. تواصل مع المشرف.';

  @override
  String errorLockedToDifferentDevice(String model) {
    return 'الحساب مقفول على جهاز أندرويد آخر ($model). تواصل مع المشرف لإعادة الربط.';
  }

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get unknown => '—';

  @override
  String get floatingBubble => 'الزر العائم';

  @override
  String get floatingBubbleBody =>
      'أظهر زرًا دائريًا (أخضر/أحمر) فوق التطبيقات الأخرى. اضغط عليه لتشغيل/إيقاف القبول التلقائي دون فتح كيمو.';

  @override
  String get floatingBubbleNeedsOverlay =>
      'امنح إذن الطبقة (Overlay) أولًا حتى يظهر الزر فوق تطبيق جيني.';

  @override
  String get deviceMismatchTitle => 'هذا ليس جهازك المسجّل';

  @override
  String get deviceMismatchBody =>
      'الحساب مقفول على جهاز أندرويد آخر. اطلب من المشرف إعادة ربط جهازك ثم أعد المحاولة.';

  @override
  String get switchToDriverView => 'عرض السائق';

  @override
  String get switchToAdminView => 'لوحة المشرف';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordBody =>
      'أدخل البريد الإلكتروني لحسابك، وسنرسل لك رابطًا لتعيين كلمة مرور جديدة.';

  @override
  String get sendResetLink => 'أرسل رابط إعادة التعيين';

  @override
  String get resetLinkSent => 'تحقّق من بريدك — تم إرسال رابط إعادة التعيين.';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';
}
