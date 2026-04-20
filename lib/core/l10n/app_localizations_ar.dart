// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'بارك جنانا';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get newWorkerButton => 'موظف جديد؟';

  @override
  String get logoutLabel => 'تسجيل الخروج';

  @override
  String get logoutTitle => 'تسجيل الخروج';

  @override
  String get logoutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get errorGeneral => 'حدث خطأ، يرجى المحاولة مرة أخرى';

  @override
  String get retryButton => 'حاول مجدداً';

  @override
  String get profileScreenTitle => 'منطقتك الشخصية';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get shiftsTitle => 'الورديات المتاحة';

  @override
  String get managerDashboardTitle => 'لوحة إدارة الورديات';

  @override
  String get newShiftButton => 'إنشاء وردية جديدة';

  @override
  String get profileUpdateSuccess => 'تم تحديث صورة الملف الشخصي بنجاح';

  @override
  String get shiftRequestSuccess => 'تم إرسال طلب الوردية';

  @override
  String get shiftCancelSuccess => 'تم إلغاء طلب الوردية';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get saveButton => 'حفظ';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get noInternetError =>
      'تعذر الاتصال بخوادم التطبيق. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get appInitializationError => 'خطأ في تهيئة التطبيق';

  @override
  String get contactSupportMessage =>
      'إذا استمرت المشكلة، يرجى التواصل مع الدعم';

  @override
  String get offlineStatusText => 'لا يوجد اتصال بالإنترنت';

  @override
  String get onlineStatusText => 'تمت استعادة الاتصال بالإنترنت ✓';

  @override
  String get offlineModeLabel => 'يعمل بدون اتصال';

  @override
  String get managerRole => 'مدير';

  @override
  String get messageUpdateError => 'خطأ في تحديث الرسالة';

  @override
  String get messageDeletionError => 'خطأ في حذف الرسالة';

  @override
  String get passwordRecoveryTitle => 'استعادة كلمة المرور';

  @override
  String get enterEmailAddressPrompt => 'يرجى إدخال عنوان بريدك الإلكتروني';

  @override
  String get emailRequiredValidation => 'يرجى إدخال عنوان بريد إلكتروني';

  @override
  String get emailInvalidValidation => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get resetLinkSent =>
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني';

  @override
  String get resetLinkError => 'خطأ في إرسال رابط إعادة تعيين كلمة المرور';

  @override
  String get sendResetLinkButton => 'إرسال رابط الإعادة';

  @override
  String get backButton => 'رجوع';

  @override
  String get welcomeTitle => 'مرحباً، أهلاً وسهلاً';

  @override
  String get loginCredentialsPrompt => 'يرجى إدخال بيانات تسجيل الدخول';

  @override
  String get emailFieldLabel => 'البريد الإلكتروني';

  @override
  String get emailFieldHint => 'أدخل عنوان بريدك الإلكتروني';

  @override
  String get passwordFieldLabel => 'كلمة المرور';

  @override
  String get passwordFieldHint => 'أدخل كلمة المرور';

  @override
  String get passwordRequiredError => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordLengthError =>
      'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';

  @override
  String get orDividerText => 'أو';

  @override
  String get biometricLoginTitle => 'تسجيل الدخول البيومتري';

  @override
  String get biometricSetupPrompt =>
      'هل تسمح بتسجيل الدخول مستقبلاً عبر بصمة الإصبع / التعرف على الوجه؟';

  @override
  String get enableBiometricButton => 'تفعيل';

  @override
  String get declineBiometricButton => 'لا، شكراً';

  @override
  String get biometricAuthFailed =>
      'فشل المصادقة البيومترية. يرجى المحاولة مجدداً.';

  @override
  String get noBiometricCredentials =>
      'لم يتم العثور على بيانات محفوظة. يرجى تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.';

  @override
  String get applicationRejectedTitle => 'تم رفض الطلب';

  @override
  String get applicationRejectedMessage =>
      'تم رفض طلب الموافقة من قِبل الإدارة.\nيمكنك إرسال طلب موافقة جديد.';

  @override
  String get reApplyButton => 'إعادة التقديم';

  @override
  String get reApplySuccess =>
      'تمت إعادة إرسال الطلب. ستقوم الإدارة بإخطارك بقرارها.';

  @override
  String get registrationTitle => 'التسجيل في بارك جنانا';

  @override
  String get registrationSubtitle => 'أكمل بياناتك لإرسال طلب الانضمام';

  @override
  String get nameRequiredValidation => 'يرجى إدخال الاسم الكامل';

  @override
  String get nameInvalidCharsValidation =>
      'يرجى إدخال اسم يحتوي على أحرف صحيحة فقط';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameHint => 'مثال: محمد أحمد';

  @override
  String get phoneDigitsValidation =>
      'يجب أن يحتوي رقم الهاتف على 10 أرقام بالضبط';

  @override
  String get phoneFormatValidation => 'يجب أن يبدأ رقم الهاتف الإسرائيلي بـ 05';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneHint => '05XXXXXXXX';

  @override
  String get idDigitsValidation => 'يجب أن يحتوي رقم الهوية على 9 أرقام بالضبط';

  @override
  String get idCheckDigitValidation => 'رقم الهوية غير صحيح';

  @override
  String get idLabel => 'رقم الهوية';

  @override
  String get idHint => '9 أرقام';

  @override
  String get emailLabel => 'عنوان البريد الإلكتروني';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordMinLengthValidation =>
      'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordHint => '6 أحرف على الأقل';

  @override
  String get passwordMismatchValidation => 'كلمتا المرور غير متطابقتين';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordHint => 'أدخل كلمة المرور مرة أخرى';

  @override
  String get personalDetailsSection => 'البيانات الشخصية';

  @override
  String get loginDetailsSection => 'بيانات تسجيل الدخول';

  @override
  String validationErrorsBanner(int count, String noun) {
    return 'يرجى تصحيح $count $noun قبل الإرسال';
  }

  @override
  String get validationErrorSingular => 'خطأ';

  @override
  String get validationErrorPlural => 'أخطاء';

  @override
  String get registrationApprovalNotice =>
      'بعد إرسال طلبك، ستوافق الإدارة على حسابك وستتمكن من تسجيل الدخول.';

  @override
  String get submitRegistrationButton => 'إرسال طلب الانضمام';

  @override
  String get registrationSuccessTitle => 'تم إرسال الطلب بنجاح!';

  @override
  String get registrationSuccessMessage =>
      'ستراجع إدارة الحديقة بياناتك وستتواصل معك في أقرب وقت ممكن.';

  @override
  String get registrationApprovalInfo =>
      'بعد موافقة الإدارة ستحصل على الوصول إلى التطبيق وتتمكن من تسجيل الدخول.';

  @override
  String get backToHomeButton => 'العودة للصفحة الرئيسية';

  @override
  String get newWorkerWelcomeTitle => 'موظف جديد؟ مرحباً بك!';

  @override
  String get registrationStepsSubtitle =>
      'انضم إلى فريق بارك جنانا في خطوات بسيطة';

  @override
  String get howItWorksSection => 'كيف يعمل؟';

  @override
  String get step1Title => 'أكمل نموذج التسجيل';

  @override
  String get step1Subtitle => 'أدخل بياناتك الشخصية واختر كلمة مرور';

  @override
  String get step2Title => 'موافقة الإدارة';

  @override
  String get step2Subtitle => 'ستراجع إدارة الحديقة بياناتك وتوافق على حسابك';

  @override
  String get step3Title => 'انضم إلى الفريق';

  @override
  String get step3Subtitle => 'بعد الموافقة يمكنك تسجيل الدخول والبدء بالعمل';

  @override
  String get welcomeSubtitle => 'أهلاً وسهلاً';

  @override
  String get shiftsNavLabel => 'الورديات';

  @override
  String get weeklyScheduleNavLabel => 'جدول العمل';

  @override
  String get tasksNavLabel => 'المهام';

  @override
  String get reportsNavLabel => 'التقارير';

  @override
  String get newsfeedNavLabel => 'لوحة الإعلانات';

  @override
  String get manageWorkersNavLabel => 'إدارة الموظفين';

  @override
  String get weeklySchedulingNavLabel => 'الجدول الأسبوعي';

  @override
  String get dashboardNavLabel => 'لوحة التحكم';

  @override
  String get totalTeamLabel => 'إجمالي الفريق';

  @override
  String get monthlyHoursLabel => 'ساعات الشهر';

  @override
  String get openTasksLabel => 'المهام المفتوحة';

  @override
  String get presentTodayLabel => 'الحاضرون اليوم';

  @override
  String get createShiftAction => 'إنشاء وردية';

  @override
  String get createTaskAction => 'إنشاء مهمة';

  @override
  String get publishPostAction => 'نشر إعلان';

  @override
  String get hoursReportAction => 'تقرير الساعات';

  @override
  String get workersTabLabel => 'الموظفون';

  @override
  String get managersTabLabel => 'المديرون';

  @override
  String get todayTabLabel => 'اليوم';

  @override
  String get thisWeekTabLabel => 'هذا الأسبوع';

  @override
  String get openTasksTabLabel => 'مفتوحة';

  @override
  String get urgentTasksTabLabel => 'عاجل';

  @override
  String get cropImageTitle => 'اقتصاص الصورة';

  @override
  String get profilePictureUpdated => 'تم تحديث صورة الملف الشخصي بنجاح';

  @override
  String uploadError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get takePhotoAction => 'التقاط صورة';

  @override
  String get takePhrotoSubtitle => 'استخدم الكاميرا';

  @override
  String get chooseFromGalleryAction => 'اختر من المعرض';

  @override
  String get uploadFromGallerySubtitle => 'رفع من صورك';

  @override
  String get noDataFound => 'لم يتم العثور على بيانات';

  @override
  String get authorizedDepartmentsLabel => 'الأقسام المعتمدة';

  @override
  String get departmentPermissionsSection => 'صلاحيات القسم';

  @override
  String get workerRoleLabel => 'موظف';

  @override
  String get ownerRoleLabel => 'مالك';

  @override
  String get coOwnerRoleLabel => 'مالك مشترك';

  @override
  String get attendanceSaved => 'تم حفظ الحضور بنجاح';

  @override
  String get attendanceSaveError => 'خطأ في حفظ الحضور';

  @override
  String get endShiftDialogTitle => 'إنهاء الوردية';

  @override
  String get recordCheckoutConfirmation =>
      'هل تسجل وقت الخروج الآن لهذه الوردية؟';

  @override
  String get endShiftButton => 'إنهاء الوردية';

  @override
  String get checkoutRecordedReminder => 'تم تسجيل وقت الخروج — تذكر الحفظ';

  @override
  String get recordUpdatedReminder => 'تم تحديث السجل — تذكر الحفظ';

  @override
  String get recordAddedReminder => 'تمت إضافة السجل — تذكر الحفظ';

  @override
  String recordDeleted(int recordNumber) {
    return 'تم حذف السجل رقم $recordNumber';
  }

  @override
  String get undoButton => 'تراجع';

  @override
  String get unsavedChangesTitle => 'تغييرات غير محفوظة';

  @override
  String get stayButton => 'ابق';

  @override
  String get exitWithoutSavingButton => 'الخروج دون حفظ';

  @override
  String get workDaysLabel => 'أيام العمل';

  @override
  String get hoursLabel => 'ساعات';

  @override
  String get hoursShortLabel => 'سا';

  @override
  String get recordsLabel => 'سجلات';

  @override
  String get missingCheckoutLabel => 'خروج مفقود';

  @override
  String get addRecordButton => 'إضافة سجل';

  @override
  String get checkInFieldLabel => 'دخول';

  @override
  String get checkOutFieldLabel => 'خروج';

  @override
  String attendanceReportError(String error) {
    return 'خطأ في تقرير الحضور: $error';
  }

  @override
  String get outsideParkBoundsMessage => 'أنت لست داخل حدود الحديقة';

  @override
  String get draftRestoredSnackbar => 'تمت استعادة المسودة';

  @override
  String get clearDraftAction => 'مسح';

  @override
  String get taskTitleRequiredValidation => 'يرجى إدخال عنوان المهمة';

  @override
  String get selectAtLeastOneWorkerValidation =>
      'يرجى اختيار موظف واحد على الأقل';

  @override
  String get selectDeadlineValidation => 'يرجى اختيار تاريخ ووقت';

  @override
  String get noCommentsEmpty => 'لا توجد تعليقات بعد';

  @override
  String get callDialogTitle => 'مكالمة صادرة';

  @override
  String callConfirmation(String name, String phone) {
    return 'هل تتصل بـ $name؟\n$phone';
  }

  @override
  String dialFailed(String phone) {
    return 'لا يمكن الاتصال بـ $phone';
  }

  @override
  String get noPendingWorkersEmpty => 'لا يوجد موظفون بانتظار الموافقة';

  @override
  String get callTooltip => 'اتصال';

  @override
  String get noActiveWorkersEmpty => 'لا يوجد موظفون نشطون في النظام';

  @override
  String get workerApproved => 'تمت الموافقة على الموظف بنجاح';

  @override
  String get applicationRejectedSnackbar => 'تم رفض الطلب. تم إخطار الموظف.';

  @override
  String get approveWorkerButton => 'الموافقة على الموظف';

  @override
  String get approveWorkerTitle => 'الموافقة على الموظف';

  @override
  String get rejectApplicationButton => 'رفض الطلب';

  @override
  String get rejectApplicationTitle => 'رفض الطلب';

  @override
  String get showShiftsButton => 'عرض الورديات';

  @override
  String get assignTaskButton => 'تعيين مهمة';

  @override
  String get viewPerformanceButton => 'عرض الأداء';

  @override
  String get correctAttendanceButton => 'تصحيح الحضور';

  @override
  String get managePermissionsButton => 'إدارة الصلاحيات والدور';

  @override
  String get revokeApprovalButton => 'إلغاء موافقة الموظف';

  @override
  String get revokeApprovalTitle => 'إلغاء موافقة الموظف';

  @override
  String get revokeApprovalMessage =>
      'سيتم نقل الموظف مرة أخرى إلى قائمة انتظار الموافقة. يمكن التراجع عن هذا الإجراء.';

  @override
  String get approvalRevoked => 'تم إلغاء موافقة الموظف';

  @override
  String get licensesUpdated => 'تم تحديث الصلاحيات بنجاح';

  @override
  String get saveLicensesError => 'خطأ في حفظ البيانات';

  @override
  String get attendanceReportTitle => 'تقرير الحضور';

  @override
  String get daysLabel => 'أيام';

  @override
  String get averagePerDayLabel => 'متوسط/يوم';

  @override
  String get hoursPerDayChartTitle => 'ساعات العمل حسب اليوم';

  @override
  String get attendanceDetailsTitle => 'تفاصيل الحضور';

  @override
  String get shiftReportTitle => 'تقرير الورديات';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get approvedLabel => 'معتمدة';

  @override
  String get rejectedOtherLabel => 'مرفوضة/أخرى';

  @override
  String get decisionsDistributionTitle => 'توزيع القرارات';

  @override
  String get shiftsDetailsTitle => 'تفاصيل الورديات';

  @override
  String get shiftCoverageTitle => 'تغطية الورديات';

  @override
  String get totalShiftsLabel => 'إجمالي الورديات';

  @override
  String get staffingRateLabel => 'معدل التوظيف';

  @override
  String get activeDepartmentsLabel => 'الأقسام النشطة';

  @override
  String get shiftsByDepartmentTitle => 'الورديات حسب القسم';

  @override
  String get departmentDetailsTitle => 'تفاصيل الأقسام';

  @override
  String get missingCheckoutsTitle => 'المخرجات المفقودة';

  @override
  String get noMissingCheckoutsEmpty => 'لا توجد مخرجات مفقودة';

  @override
  String get detailsByWorkerTitle => 'التفاصيل حسب الموظف';

  @override
  String get myReportsTitle => 'تقاريري';

  @override
  String get taskReportCard => 'تقرير المهام';

  @override
  String get selectPhotosAction => 'اختر صوراً';

  @override
  String get selectPhotosFromGallery => 'اختر صوراً من المعرض';

  @override
  String get selectVideoAction => 'اختر مقطع فيديو';

  @override
  String get selectVideoFromGallery => 'اختر مقطع فيديو من المعرض';

  @override
  String get openCameraSubtitle => 'افتح الكاميرا';

  @override
  String get postTitleHint => 'أدخل عنوان المنشور...';

  @override
  String get postContentHint => 'ماذا تريد أن تشارك؟';

  @override
  String get deleteCommentTitle => 'حذف التعليق';

  @override
  String get deleteCommentConfirmation =>
      'هل أنت متأكد أنك تريد حذف هذا التعليق؟';

  @override
  String get deletePostTitle => 'حذف المنشور';

  @override
  String get deletePostConfirmation =>
      'هل أنت متأكد أنك تريد حذف هذا المنشور؟\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get editPostAction => 'تعديل المنشور';

  @override
  String get deletePostAction => 'حذف المنشور';

  @override
  String get editingPostTitle => 'تعديل المنشور';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get markAllAsReadButton => 'تحديد الكل كمقروء';

  @override
  String get loadNotificationsError => 'خطأ في تحميل الإشعارات';

  @override
  String get openShiftError => 'خطأ في فتح الوردية';

  @override
  String get openTaskError => 'خطأ في فتح المهمة';

  @override
  String get noNotificationsEmpty => 'لا توجد إشعارات';

  @override
  String get newNotificationsWillAppear => 'ستظهر الإشعارات الجديدة هنا';

  @override
  String get cannotOpenLink => 'لا يمكن فتح الرابط';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get biometricMethodsSubtitle => 'بصمة الإصبع / التعرف على الوجه';

  @override
  String get pushNotificationsTitle => 'الإشعارات الفورية';

  @override
  String get pushNotificationsSubtitle => 'تلقي تحديثات حول الورديات والمهام';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get termsOfServiceTitle => 'شروط الاستخدام';

  @override
  String get crashReportsTitle => 'إرسال تقارير الأعطال';

  @override
  String get crashReportsSubtitle => 'يساعدنا على تحسين استقرار التطبيق';

  @override
  String get appVersionTitle => 'إصدار التطبيق';

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get deleteAccountSubtitle =>
      'إجراء لا رجعة فيه — سيتم حذف جميع البيانات';

  @override
  String get passwordChanged => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get biometricAuthFailedSnackbar => 'فشلت المصادقة البيومترية';

  @override
  String get enableBiometricError => 'خطأ في تفعيل تسجيل الدخول البيومتري';

  @override
  String get enableBiometricTitle => 'تفعيل تسجيل الدخول البيومتري';

  @override
  String get permanentDeletionTitle => 'الحذف النهائي';

  @override
  String get optionsTooltip => 'خيارات';

  @override
  String get settingsMenu => 'الإعدادات';

  @override
  String get noButton => 'لا';

  @override
  String get yesButton => 'نعم';

  @override
  String get longPressHint => 'اضغط مطولاً';

  @override
  String get weatherLabel => 'الطقس';

  @override
  String get loadDataError =>
      'لا يمكن تحميل البيانات. تحقق من الاتصال أو الفهرس.';

  @override
  String get noShiftsEmpty => 'لا توجد ورديات للعرض';

  @override
  String shiftHoursFormat(String startTime, String endTime) {
    return 'الساعات: $startTime - $endTime';
  }

  @override
  String departmentPrefix(String department) {
    return 'القسم: $department';
  }

  @override
  String get unsavedChangesMessage =>
      'لديك تغييرات غير محفوظة. هل أنت متأكد أنك تريد الخروج؟';

  @override
  String get noAttendanceRecords => 'لا توجد سجلات حضور لهذا الشهر';

  @override
  String get addManualRecordHint => 'أضف سجلاً يدوياً أو اختر شهراً آخر';

  @override
  String get missingLabel => 'مفقود';

  @override
  String get activeLabel => 'نشط';

  @override
  String get saveChangesButton => 'حفظ التغييرات';

  @override
  String get editAttendanceRecordTitle => 'تعديل سجل الحضور';

  @override
  String get locationPermissionTitle => 'مطلوب الوصول إلى الموقع';

  @override
  String get locationPermissionMessage =>
      'لتسجيل الحضور أو الانصراف، يجب تفعيل خدمات الموقع على جهازك.';

  @override
  String get enableLocationButton => 'تفعيل الموقع';

  @override
  String get clockInOutsideParkMessage =>
      'أنت تحاول تسجيل الحضور خارج النطاق المسموح به. هل تريد المتابعة على أي حال؟';

  @override
  String get clockOutOutsideParkMessage =>
      'أنت تحاول تسجيل الانصراف خارج النطاق المسموح به. هل تريد المتابعة على أي حال؟';

  @override
  String get longPressToEndShift => 'اضغط مطولاً لإنهاء الوردية';

  @override
  String get longPressToStartShift => 'اضغط مطولاً لبدء الوردية';

  @override
  String clockedInSince(String time) {
    return 'منذ $time';
  }

  @override
  String datePrefix(String date) {
    return 'التاريخ: $date';
  }

  @override
  String clockInTimePrefix(String time) {
    return 'وقت الدخول: $time';
  }

  @override
  String clockOutTimePrefix(String time) {
    return 'وقت الخروج: $time';
  }

  @override
  String workDurationLabel(int hours, int minutes) {
    return 'مدة العمل: $hoursس $minutesد';
  }

  @override
  String get greetingNight => 'مساء النور،';

  @override
  String get greetingMorning => 'صباح الخير،';

  @override
  String get greetingAfternoon => 'مرحباً،';

  @override
  String get greetingEvening => 'مساء الخير،';

  @override
  String get motivationalMsg1 => 'أنت جزء مهم من فريقنا 💪';

  @override
  String get motivationalMsg2 => 'كل وردية هي فرصة للتأثير ✨';

  @override
  String get motivationalMsg3 => 'حافظ على ابتسامتك – إنها معدية 😄';

  @override
  String get thisMonthLabel => 'هذا الشهر';

  @override
  String get nowLabel => 'الآن';

  @override
  String minutesAgoLabel(int n) {
    return 'منذ $n د';
  }

  @override
  String hoursAgoLabel(int n) {
    return 'منذ $n س';
  }

  @override
  String get yesterdayLabel => 'أمس';

  @override
  String daysAgoLabel(int n) {
    return 'منذ $n أيام';
  }

  @override
  String get latestUpdateLabel => 'آخر تحديث';

  @override
  String get readMoreLabel => 'اقرأ المزيد';

  @override
  String get whatIsImportantNow => 'ما المهم الآن';

  @override
  String get allUpToDate => 'كل شيء محدّث — لا توجد عناصر عاجلة';

  @override
  String get shiftChangesWaiting => 'تغييرات الوردية معلقة';

  @override
  String get tasksWaitingApproval => 'مهام بانتظار الموافقة';

  @override
  String get newPostsInBoard => 'منشورات جديدة على لوحة الإعلانات';

  @override
  String get newUpdatesInBoard => 'تحديثات جديدة على لوحة الإعلانات';

  @override
  String get newBusinessActivity => 'نشاط تجاري جديد للمراجعة';

  @override
  String get newShiftsAssigned => 'ورديات جديدة مخصصة لك';

  @override
  String get openTasksWaiting => 'مهام مفتوحة بانتظارك';

  @override
  String get clickToResetClockOut => 'اضغط لإعادة ضبط وقت الخروج';

  @override
  String get clickToRegisterClockIn => 'اضغط لتسجيل وقت الدخول';

  @override
  String get completedLabel => 'مكتملة';

  @override
  String get presentNowLabel => 'حاضرون الآن';

  @override
  String get noWorkersConnected => 'لا يوجد موظفون متصلون حالياً';

  @override
  String get topWorkersThisMonth => 'أفضل الموظفين هذا الشهر';

  @override
  String get workHoursThisMonth => 'ساعات العمل — هذا الشهر';

  @override
  String averageHoursPerWorker(String hours) {
    return 'متوسط $hours ساعة لكل موظف';
  }

  @override
  String get ownerDashboardTitle => 'لوحة التحكم — المالك';

  @override
  String helloName(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get quickActionsLabel => 'الإجراءات السريعة';

  @override
  String get staffLabel => 'الموظفون';

  @override
  String staffCountSummary(int count) {
    return 'المجموع $count من أعضاء الفريق • اضغط للإدارة';
  }

  @override
  String get employeeManagementSystem => 'نظام إدارة الموظفين';

  @override
  String get myProfileTitle => 'ملفي الشخصي';

  @override
  String get gpsUnavailableTitle => 'لا يمكن التحقق من الموقع';

  @override
  String get gpsUnavailableMessage =>
      'خدمة الموقع غير متاحة أو لم يتم منح أذونات GPS. هل تريد المتابعة على أي حال؟';

  @override
  String get searchingLocationLabel => '...جارٍ تحديد الموقع';

  @override
  String get networkErrorLoadMessage =>
      'تعذّر تحميل البيانات.\nتحقق من الاتصال وحاول مجدداً.';

  @override
  String get profileTooltip => 'الملف الشخصي';

  @override
  String get notificationsTooltip => 'الإشعارات';

  @override
  String get permissionsCoverageLabel => 'تغطية الصلاحيات';

  @override
  String get noActivePermissions => 'لا توجد صلاحيات نشطة';

  @override
  String get updateProfilePictureTitle => 'تحديث صورة الملف الشخصي';

  @override
  String get chooseImageSourceTitle => 'اختر مصدر الصورة';

  @override
  String get setAsProfilePictureConfirm =>
      'هل تريد تعيين هذه الصورة كصورة ملفك الشخصي؟';

  @override
  String get ctaOpenButton => 'افتح';

  @override
  String get clickForWeeklySchedule => 'اضغط للجدول الأسبوعي';

  @override
  String get clickForManageWorkers => 'اضغط لإدارة الموظفين';

  @override
  String get daysWorkedLabel => 'أيام العمل';

  @override
  String get hoursWorkedLabel => 'ساعات العمل';

  @override
  String clockInFromLabel(String clockIn, String duration) {
    return 'من $clockIn · $duration';
  }

  @override
  String get accountSectionHeader => 'الحساب';

  @override
  String get languageSectionHeader => 'اللغة';

  @override
  String get languageSubtitle => 'اختر لغة الواجهة';

  @override
  String get notificationsSectionHeader => 'الإشعارات';

  @override
  String get infoSectionHeader => 'المعلومات';

  @override
  String get signOutSectionHeader => 'تسجيل الخروج';

  @override
  String get dangerZoneSectionHeader => 'منطقة الخطر';

  @override
  String get requiresRecentLoginError =>
      'يرجى تسجيل الدخول مجدداً قبل تغيير كلمة المرور';

  @override
  String get updatePasswordError => 'خطأ في تحديث كلمة المرور';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get passwordRequiredValidator => 'يرجى إدخال كلمة المرور';

  @override
  String get updatePasswordButton => 'تحديث كلمة المرور';

  @override
  String get biometricEnableDescription =>
      'أدخل كلمة المرور الحالية لتفعيل تسجيل الدخول ببصمة الإصبع / التعرف على الوجه.';

  @override
  String get currentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get biometricVerifyReason =>
      'تحقق من هويتك لتفعيل تسجيل الدخول البيومتري';

  @override
  String get activateBiometricButton => 'تفعيل تسجيل الدخول البيومتري';

  @override
  String get permanentDeletionMessage =>
      'هذا الإجراء لا رجعة فيه تمامًا.\nسيتم حذف جميع بياناتك الشخصية نهائياً.';

  @override
  String get deleteAccountButton => 'حذف الحساب';

  @override
  String get wrongPasswordError =>
      'كلمة المرور غير صحيحة. يرجى المحاولة مجدداً.';

  @override
  String get requiresRecentLoginDeleteError =>
      'يلزم تسجيل الدخول مجدداً قبل حذف الحساب';

  @override
  String get deleteAccountError => 'خطأ في حذف الحساب. يرجى المحاولة مجدداً.';

  @override
  String get deleteAccountWarning =>
      'سيؤدي هذا إلى حذف جميع بياناتك الشخصية نهائياً ولا يمكن التراجع عنه.\nيرجى إدخال كلمة المرور للتأكيد.';

  @override
  String get deleteMyAccountButton => 'حذف حسابي نهائياً';

  @override
  String get newBadgeLabel => 'جديد';

  @override
  String get newWorkersTabLabel => 'موظفون جدد';

  @override
  String get activeWorkersTabLabel => 'موظفون نشطون';

  @override
  String get searchWorkerHint => 'البحث عن موظف بالاسم...';

  @override
  String get noSearchResultsEmpty => 'لم يتم العثور على نتائج';

  @override
  String workersMissingClockOutBanner(int count, String workers) {
    return '$count $workers بخروج مفقود هذا الشهر';
  }

  @override
  String get workerLabelSingular => 'موظف';

  @override
  String get workerLabelPlural => 'موظفون';

  @override
  String get missingClockOutWarning => 'وقت خروج مفقود — اضغط للتصحيح';

  @override
  String get workerSubtitleInPark => 'موظف في بارك جنانا';

  @override
  String get workerEmailInfoLabel => 'بريد إلكتروني';

  @override
  String get workerPhoneInfoLabel => 'هاتف';

  @override
  String get workerDetailsCardTitle => '🧾 بيانات الموظف';

  @override
  String get adminActionsCardTitle => '🧭 إجراءات المدير';

  @override
  String get manageLicensesCardTitle => '🛠 إدارة الصلاحيات';

  @override
  String get noPermissionForUser => 'لا توجد صلاحية لإدارة هذا المستخدم';

  @override
  String get newWorkerPendingApproval => 'موظف جديد بانتظار الموافقة';

  @override
  String get approveEmailLabel => 'البريد الإلكتروني';

  @override
  String get approveConfirmContent =>
      'هل أنت متأكد أنك تريد الموافقة على هذا الموظف؟';

  @override
  String get rejectConfirmContent =>
      'سيبقى الموظف قيد الانتظار ويمكنه إعادة التقديم. هل ترفض؟';

  @override
  String get roleSectionTitle => 'الدور';

  @override
  String get managerRoleUpgradeNote => 'ترقية دور المدير مخصصة للمالكين فقط';

  @override
  String get departmentsSectionHint =>
      'اختر الأقسام التي يُصرح للموظف العمل فيها';

  @override
  String get roleChangedTitle => 'تم تحديث دورك';

  @override
  String roleChangedBody(String fromRole, String toRole) {
    return 'تم تغيير دورك من $fromRole إلى $toRole';
  }

  @override
  String get searchByNameOrRoleHint => 'البحث بالاسم أو الدور';

  @override
  String get workerAddedToShift => 'تمت إضافة الموظف إلى الوردية بنجاح';

  @override
  String get workerRemovedFromShift => 'تمت إزالة الموظف من الوردية';

  @override
  String get noWorkersFound => 'لم يتم العثور على موظفين';

  @override
  String addWorkersCount(int count) {
    return 'إضافة $count موظفين';
  }

  @override
  String get workerShiftsListSubtitle => 'قائمة ورديات الموظف';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterUpcoming => 'القادمة';

  @override
  String get filterPast => 'الماضية';

  @override
  String get filterToday => 'اليوم';

  @override
  String get filterThisWeek => 'هذا الأسبوع';

  @override
  String shiftNoteLabel(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String get ownerRoleShort => 'مالك';

  @override
  String get coOwnerRoleShort => 'شريك';

  @override
  String get newsfeedTitle => 'لوحة الإعلانات';

  @override
  String get newPostButton => 'منشور جديد';

  @override
  String get searchPostHint => 'البحث عن منشور...';

  @override
  String get categoryAll => 'الكل';

  @override
  String get categoryAnnouncements => 'إعلانات';

  @override
  String get categoryUpdates => 'تحديثات';

  @override
  String get categoryEvents => 'فعاليات';

  @override
  String get categoryGeneral => 'عام';

  @override
  String get categoryLabelAnnouncement => 'إعلان';

  @override
  String get categoryLabelUpdate => 'تحديث';

  @override
  String get categoryLabelEvent => 'فعالية';

  @override
  String get categoryLabelGeneral => 'عام';

  @override
  String get pinnedPostLabel => 'منشور مثبت';

  @override
  String get pinPostAction => 'تثبيت المنشور';

  @override
  String get unpinPostAction => 'إلغاء التثبيت';

  @override
  String get deletePostMessage =>
      'هل أنت متأكد أنك تريد حذف هذا المنشور؟\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteCommentMessage => 'هل أنت متأكد أنك تريد حذف هذا التعليق؟';

  @override
  String get deleteLabel => 'حذف';

  @override
  String get postDeletedSuccess => 'تم حذف المنشور بنجاح';

  @override
  String postDeleteError(String error) {
    return 'خطأ في حذف المنشور: $error';
  }

  @override
  String get postPinnedSuccess => 'تم تثبيت المنشور';

  @override
  String get postUnpinnedSuccess => 'تم إلغاء تثبيت المنشور';

  @override
  String errorPrefix(String error) {
    return 'خطأ: $error';
  }

  @override
  String get noPostsEmpty => 'لا توجد منشورات بعد';

  @override
  String get noPostsManagerHint => 'اضغط على \"منشور جديد\" لنشر أول منشور';

  @override
  String get noPostsWorkerHint => 'سينشر المديرون التحديثات هنا قريباً';

  @override
  String get noPostsSearchEmpty => 'لم يتم العثور على منشورات تطابق بحثك';

  @override
  String get noPostsCategoryEmpty => 'لا توجد منشورات في هذه الفئة';

  @override
  String get feedLoadError => 'خطأ في تحميل المنشورات';

  @override
  String get checkConnectionHint => 'تحقق من اتصالك بالإنترنت وحاول مجدداً';

  @override
  String get defaultUserName => 'مستخدم';

  @override
  String get createPostTitle => 'منشور جديد';

  @override
  String get createPostSubtitle => 'شارك التحديثات مع فريقك';

  @override
  String get selectCategoryLabel => 'اختر فئة';

  @override
  String get postTitleLabel => 'العنوان';

  @override
  String get postTitleRequired => 'يرجى إدخال عنوان';

  @override
  String get postContentLabel => 'محتوى المنشور';

  @override
  String get postContentRequired => 'يرجى إدخال محتوى';

  @override
  String mediaLabel(int count, int max) {
    return 'الوسائط ($count/$max)';
  }

  @override
  String get addMediaButton => 'أضف صوراً أو مقاطع فيديو';

  @override
  String get addMoreMediaButton => 'أضف المزيد';

  @override
  String get mediaPickerTitle => 'إضافة وسائط';

  @override
  String get pickImagesOption => 'اختر صوراً';

  @override
  String get pickImagesSubtitle => 'اختر صوراً من المعرض';

  @override
  String get pickVideoOption => 'اختر فيديو';

  @override
  String get pickVideoSubtitle => 'اختر فيديو من المعرض';

  @override
  String get takePhotoOption => 'التقط صورة';

  @override
  String get takePhotoSubtitle => 'افتح الكاميرا';

  @override
  String maxMediaError(int max) {
    return 'يمكنك تحميل ما يصل إلى $max ملفات';
  }

  @override
  String get videoLabel => 'فيديو';

  @override
  String get publishPostButton => 'نشر المنشور';

  @override
  String get publishingPostStatus => 'جارٍ نشر المنشور...';

  @override
  String get preparingUploadStatus => 'جارٍ التحضير للرفع...';

  @override
  String get postPublishedSuccess => 'تم نشر المنشور بنجاح';

  @override
  String postPublishError(String error) {
    return 'خطأ في نشر المنشور: $error';
  }

  @override
  String get movWarningMessage =>
      'قد تستخدم مقاطع .MOV من iPhone تنسيق Dolby Vision غير المدعوم على بعض الأجهزة. يُنصح باستخدام MP4.';

  @override
  String get postDetailTitle => 'تفاصيل المنشور';

  @override
  String get tapToWatchVideo => 'اضغط لمشاهدة الفيديو';

  @override
  String get commentsTitle => 'التعليقات';

  @override
  String get beFirstToComment => 'كن أول من يعلق!';

  @override
  String get beFirstToCommentOnPost => 'كن أول من يعلق على هذا المنشور!';

  @override
  String get addCommentHint => 'أضف تعليقاً...';

  @override
  String get writeCommentHint => 'اكتب تعليقاً...';

  @override
  String get commentAddedSuccess => 'تمت إضافة التعليق';

  @override
  String get commentAddError => 'خطأ في إضافة التعليق';

  @override
  String get commentDeletedSuccess => 'تم حذف التعليق';

  @override
  String get commentDeleteError => 'خطأ في حذف التعليق';

  @override
  String get commentUpdatedSuccess => 'تم تحديث التعليق';

  @override
  String get commentUpdateError => 'خطأ في تحديث التعليق';

  @override
  String get editPostTitle => 'تعديل المنشور';

  @override
  String get postUpdatedSuccess => 'تم تحديث المنشور';

  @override
  String get postUpdateError => 'خطأ في تحديث المنشور';

  @override
  String get likersTitle => 'تفاعلات المنشور';

  @override
  String likersCount(int count) {
    return '$count أشخاص';
  }

  @override
  String get noLikersEmpty => 'لا توجد إعجابات بعد';

  @override
  String get beFirstToLike => 'كن أول من يعجب بهذا المنشور!';

  @override
  String get likersLoadError => 'خطأ في تحميل البيانات';

  @override
  String get roleManager => 'مدير';

  @override
  String get roleWorker => 'موظف';

  @override
  String get roleAdmin => 'مدير النظام';

  @override
  String get videoFormatNotSupported => 'تنسيق الفيديو غير مدعوم';

  @override
  String get videoLoadError => 'خطأ في تحميل الفيديو';

  @override
  String get videoFormatErrorDetail =>
      'الفيديو مشفر بتنسيق Dolby Vision / HEVC غير مدعوم\nعلى هذا الجهاز. جرّب رفع فيديو H.264 (MP4 عادي).';

  @override
  String get videoPlaybackErrorDetail =>
      'حدث خطأ أثناء تشغيل الفيديو.\nتحقق من اتصالك وحاول مجدداً.';

  @override
  String get videoLoadingLabel => 'جارٍ تحميل الفيديو...';

  @override
  String get noPostsMatchSearch => 'لم يتم العثور على منشورات تطابق البحث';

  @override
  String get noPostsInCategory => 'لا توجد منشورات في هذه الفئة';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد';

  @override
  String get loadPostsError => 'خطأ في تحميل المنشورات';

  @override
  String deletePostError(String error) {
    return 'خطأ في حذف المنشور: $error';
  }

  @override
  String genericError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get taskStatusPending => 'في الانتظار';

  @override
  String get taskStatusInProgress => 'قيد التنفيذ';

  @override
  String get taskStatusDone => 'منجز';

  @override
  String get taskStatusPendingReview => 'في انتظار الموافقة';

  @override
  String get taskPriorityHigh => 'عالية';

  @override
  String get taskPriorityMedium => 'متوسطة';

  @override
  String get taskPriorityLow => 'منخفضة';

  @override
  String get noTasksEmpty => 'لا توجد مهام';

  @override
  String get noTasksForDay => 'لا توجد مهام لهذا اليوم';

  @override
  String get noTasksNow => 'لا توجد مهام حالياً';

  @override
  String get newTasksWillAppear => 'ستظهر المهام الجديدة هنا';

  @override
  String get useCreateTaskButton =>
      'استخدم زر \'إنشاء مهمة\' لإضافة مهمة جديدة';

  @override
  String get taskManagementTitle => 'إدارة المهام';

  @override
  String get allTasksTitle => 'جميع المهام';

  @override
  String get allTasksSubtitle => 'عرض شامل لجميع المهام';

  @override
  String get myTasksTitle => 'مهامي';

  @override
  String get myTasksTabLabel => 'مهامي';

  @override
  String get createdByMeTabLabel => 'المهام التي أنشأتها';

  @override
  String get taskDetailsTitle => 'تفاصيل المهمة';

  @override
  String get taskDescriptionLabel => 'الوصف';

  @override
  String get taskDescriptionSectionTitle => 'وصف المهمة';

  @override
  String get noTaskDescription => 'لا يوجد وصف لهذه المهمة';

  @override
  String get taskInfoSectionTitle => 'التفاصيل';

  @override
  String get taskDeadlineLabel => 'تاريخ الاستحقاق';

  @override
  String get taskPriorityLabel => 'الأولوية';

  @override
  String get taskDepartmentLabel => 'القسم';

  @override
  String get taskCreatedAtLabel => 'تم الإنشاء';

  @override
  String get taskAssigneesLabel => 'الموظفون';

  @override
  String taskAssigneesCount(int count) {
    return 'الموظفون ($count)';
  }

  @override
  String get taskOverviewTabLabel => 'نظرة عامة';

  @override
  String get taskDiscussionTabLabel => 'النقاش';

  @override
  String get editTaskMenuItem => 'تعديل المهمة';

  @override
  String get deleteTaskMenuItem => 'حذف المهمة';

  @override
  String get createTaskButton => 'إنشاء مهمة';

  @override
  String get deleteTaskTitle => 'حذف المهمة';

  @override
  String deleteTaskConfirmation(String title) {
    return 'هل تريد حذف \"$title\"؟';
  }

  @override
  String get deleteTaskButton => 'حذف';

  @override
  String taskDeletedSnackbar(String title) {
    return 'تم حذف المهمة \"$title\"';
  }

  @override
  String get confirmDeleteTitle => 'تأكيد الحذف';

  @override
  String confirmDeleteTaskMessage(String title) {
    return 'هل أنت متأكد أنك تريد حذف المهمة \'$title\'؟';
  }

  @override
  String get taskOverdueSection => 'متأخرة';

  @override
  String get taskTodaySection => 'اليوم';

  @override
  String get taskUpcomingSection => 'القادمة';

  @override
  String get taskCompletedSection => 'مكتملة';

  @override
  String taskDeadlineOverdue(int days, String unit) {
    return 'متأخر $days $unit';
  }

  @override
  String taskDeadlineToday(String time) {
    return 'اليوم، $time';
  }

  @override
  String taskDeadlineTomorrow(String time) {
    return 'غداً، $time';
  }

  @override
  String taskDeadlineInDays(int days) {
    return 'خلال $days أيام';
  }

  @override
  String get dayUnit => 'يوم';

  @override
  String get daysUnit => 'أيام';

  @override
  String todayTasksProgress(int completed, int total) {
    return '$completed من $total مكتملة اليوم';
  }

  @override
  String get noTasksToday => 'لا توجد مهام لليوم';

  @override
  String taskCountOverdue(int count, int overdue) {
    return '$count مهام • $overdue متأخرة';
  }

  @override
  String get pendingManagerApproval => 'في انتظار موافقة المدير';

  @override
  String get pendingApprovalLabel => 'في انتظار الموافقة:';

  @override
  String get startTaskButton => 'ابدأ العمل';

  @override
  String get startTaskAction => 'ابدأ المهمة';

  @override
  String get finishTaskButton => 'أنهِ المهمة';

  @override
  String get submitForApprovalButton => 'أرسل لموافقة المدير';

  @override
  String get approveButton => 'موافقة';

  @override
  String get rejectButton => 'رفض';

  @override
  String get taskApprovedSnackbar => 'تمت الموافقة على المهمة بنجاح';

  @override
  String get taskRejectedSnackbar => 'تم إعادة المهمة إلى قيد التنفيذ';

  @override
  String get startWorkButton => 'ابدأ العمل';

  @override
  String get sendCommentButton => 'إرسال التعليق';

  @override
  String get addCommentHintTask => 'أضف تعليقاً...';

  @override
  String get writeCommentHintTask => 'اكتب تعليقاً...';

  @override
  String get commentSendError => 'خطأ في إرسال التعليق';

  @override
  String get attachedFilesTitle => 'الملفات المرفقة';

  @override
  String get attachedFileDefault => 'مرفق';

  @override
  String get cannotOpenFile => 'تعذر فتح الملف';

  @override
  String get filterStatusPending => 'معلق';

  @override
  String get filterStatusInProgress => 'قيد التنفيذ';

  @override
  String get filterStatusDone => 'مكتمل';

  @override
  String get searchTaskHint => 'بحث عن مهمة...';

  @override
  String get searchTaskByNameHint => 'بحث عن مهمة بالاسم...';

  @override
  String taskErrorPrefix(String error) {
    return 'خطأ: $error';
  }

  @override
  String get taskTitleLabel => 'العنوان';

  @override
  String get taskTitleHint => 'اسم المهمة';

  @override
  String get taskDescriptionFieldLabel => 'الوصف';

  @override
  String get taskDescriptionHint => 'وصف تفصيلي';

  @override
  String get taskDescriptionOptionalHint => 'وصف تفصيلي (اختياري)';

  @override
  String get taskFieldRequired => 'حقل مطلوب';

  @override
  String get taskFillAllFields => 'يرجى ملء جميع الحقول واختيار موظفين';

  @override
  String get taskDateLabel => 'التاريخ';

  @override
  String get taskTimeLabel => 'الوقت';

  @override
  String get taskSelectDate => 'اختر التاريخ';

  @override
  String get taskSelectTime => 'اختر الوقت';

  @override
  String get taskDeadlineSectionTitle => 'الموعد النهائي';

  @override
  String get taskDeadlineHint => 'حدد تاريخ ووقت انتهاء المهمة';

  @override
  String get taskWorkersSectionTitle => 'الموظفون المعيّنون';

  @override
  String get taskAssignWorkersTitle => 'تعيين موظفين';

  @override
  String taskSelectedWorkersCount(int count) {
    return 'اختر $count موظفين';
  }

  @override
  String get taskSearchWorkerHint => 'بحث عن موظف...';

  @override
  String get taskSearchWorkerByNameHint => 'بحث بالاسم أو الدور...';

  @override
  String get taskSummaryTitle => 'ملخص وإنشاء';

  @override
  String get taskSummarySubtitle => 'راجع التفاصيل قبل إنشاء المهمة';

  @override
  String get taskBasicInfoTitle => 'تفاصيل المهمة';

  @override
  String get taskBasicInfoSubtitle => 'أدخل التفاصيل الأساسية للمهمة';

  @override
  String get taskStepDetails => 'التفاصيل';

  @override
  String get taskStepWorkers => 'الموظفون';

  @override
  String get taskStepDeadline => 'الموعد';

  @override
  String get taskStepSummary => 'الملخص';

  @override
  String get taskReviewWorkersLabel => 'الموظفون';

  @override
  String get taskReviewDeadlineLabel => 'الموعد النهائي';

  @override
  String get createTaskActionButton => 'إنشاء المهمة';

  @override
  String get nextButton => 'التالي';

  @override
  String get backStepButton => 'رجوع';

  @override
  String get saveChangesTaskButton => 'حفظ التغييرات';

  @override
  String get taskCreateError => 'خطأ في إنشاء المهمة';

  @override
  String get taskUpdateError => 'خطأ في تحديث المهمة';

  @override
  String get taskLogEdited => 'تم تحديث المهمة';

  @override
  String get userFallbackName => 'مستخدم';

  @override
  String get showLessButton => 'عرض أقل';

  @override
  String get showAllButton => 'عرض الكل';

  @override
  String get tasksTitleValidation => 'يرجى إدخال عنوان المهمة';

  @override
  String get tasksWorkersValidation => 'يرجى اختيار موظف واحد على الأقل';

  @override
  String get tasksDeadlineValidation => 'يرجى اختيار التاريخ والوقت';

  @override
  String get userIdentificationError => 'خطأ في تحديد المستخدم.';

  @override
  String get taskReturnedSnackbar => 'تم إعادة المهمة إلى قيد التنفيذ';

  @override
  String tasksOverdueCount(int total, int overdue) {
    return '$total مهام • $overdue متأخرة';
  }

  @override
  String get noShiftsAvailableEmpty => 'لا توجد ورديات متاحة الآن';

  @override
  String get shiftsComingSoonSubtitle => 'ستُضاف ورديات جديدة قريبًا';

  @override
  String get noShiftsForDay => 'لا توجد ورديات لهذا اليوم';

  @override
  String get selectOtherDayHint => 'اختر يومًا آخر أو انتظر ورديات جديدة';

  @override
  String get tryReconnectHint => 'حاول إعادة الاتصال';

  @override
  String get shiftStatusActive => 'نشطة';

  @override
  String get shiftStatusCancelled => 'ملغاة';

  @override
  String pendingRequestsCount(int count) {
    return '$count طلبات';
  }

  @override
  String get newShiftFab => 'وردية جديدة';

  @override
  String get managerShiftDashboardTitle => 'إدارة الورديات';

  @override
  String get shiftRequestCancelledSnackbar => 'تم إلغاء طلب الوردية';

  @override
  String get shiftConflictTitle => 'تعارض الورديات';

  @override
  String shiftConflictMessage(String startTime, String endTime) {
    return 'أنت معيّن بالفعل في وردية في هذا التاريخ بساعات متداخلة ($startTime–$endTime). هل تريد المتابعة على أي حال؟';
  }

  @override
  String get proceedAnywayButton => 'المتابعة على أي حال';

  @override
  String get cancelShiftRequestLabel => 'إلغاء طلب الوردية';

  @override
  String get joinShiftLabel => 'الانضمام إلى الوردية';

  @override
  String get joinButton => 'انضمام';

  @override
  String get shiftWorkedLabel => 'عملت';

  @override
  String get shiftEndedLabel => 'انتهى';

  @override
  String get shiftAssignedLabel => 'معيّن';

  @override
  String get shiftFullLabel => 'ممتلئة';

  @override
  String get shiftCancelledChip => 'الوردية ملغاة';

  @override
  String get shiftOutdatedChip => 'انتهى الموعد';

  @override
  String get youAreAssignedChip => 'أنت معيّن';

  @override
  String get waitingApprovalChip => 'في انتظار الموافقة';

  @override
  String get shiftFullChip => 'الوردية ممتلئة';

  @override
  String get openForRegistrationChip => 'مفتوحة للتسجيل';

  @override
  String get assignedWorkersSection => 'الموظفون المعيّنون';

  @override
  String get noAssignedWorkersYet => 'لا يوجد موظفون معيّنون بعد';

  @override
  String get messagesSection => 'الرسائل';

  @override
  String get loadingMessages => 'جارٍ تحميل الرسائل...';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get createNewShiftTitle => 'إنشاء وردية جديدة';

  @override
  String get createShiftSubtitle => 'أدخل التفاصيل لإنشاء وردية';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get departmentLabel => 'القسم';

  @override
  String get startTimeLabel => 'البداية';

  @override
  String get endTimeLabel => 'النهاية';

  @override
  String get maxWorkersLabel => 'الحد الأقصى للموظفين';

  @override
  String get weeklyRecurrenceLabel => 'التكرار الأسبوعي';

  @override
  String get shiftRepeatsWeekly => 'الوردية تتكرر كل أسبوع';

  @override
  String get createRecurringShift => 'إنشاء وردية متكررة';

  @override
  String get numberOfWeeksLabel => 'عدد الأسابيع:';

  @override
  String get shiftsToBeCreatedLabel => 'الورديات التي ستُنشأ:';

  @override
  String get createShiftButton => 'إنشاء الوردية';

  @override
  String shiftsCreatedSuccess(int count) {
    return 'تم إنشاء $count ورديات بنجاح!';
  }

  @override
  String get shiftCreatedSuccess => 'تم إنشاء الوردية بنجاح!';

  @override
  String createShiftError(String error) {
    return 'خطأ في إنشاء الوردية: $error';
  }

  @override
  String get clearButton => 'مسح';

  @override
  String get editShiftTitle => 'تعديل الوردية';

  @override
  String get unsavedChangesHeaderSubtitle => 'توجد تغييرات غير محفوظة';

  @override
  String get updateShiftDetailsSubtitle => 'تحديث تفاصيل الوردية';

  @override
  String get saveChangesDialogTitle => 'حفظ التغييرات';

  @override
  String get followingChangesSavedLabel => 'سيتم حفظ التغييرات التالية:';

  @override
  String get workersNotifiedOfChanges =>
      'سيتلقى جميع الموظفين المعيّنين والمنتظرين إشعاراً بالتغييرات';

  @override
  String get shiftUpdatedSuccess => 'تم تحديث الوردية بنجاح!';

  @override
  String updateShiftError(String error) {
    return 'خطأ في تحديث الوردية: $error';
  }

  @override
  String get continueEditingButton => 'متابعة التعديل';

  @override
  String get departmentChangedLabel => 'القسم (تم التغيير)';

  @override
  String get hoursChangedLabel => 'الساعات (تم التغيير)';

  @override
  String get maxWorkersChangedLabel => 'الحد الأقصى للموظفين (تم التغيير)';

  @override
  String get changedBadge => 'تم التغيير';

  @override
  String tooManyWorkersWarning(int count) {
    return 'يوجد حالياً $count موظفين معيّنين، أكثر من الحد الأقصى الجديد';
  }

  @override
  String get statusLabel => 'الحالة';

  @override
  String get statusChangedLabel => 'الحالة (تم التغيير)';

  @override
  String get shiftStatusCancelledMasc => 'ملغى';

  @override
  String get shiftStatusCompleted => 'مكتملة';

  @override
  String get noChangesLabel => 'لا توجد تغييرات';

  @override
  String weekRangeLabel(String start, String end) {
    return 'أسبوع $start - $end';
  }

  @override
  String get myShiftsTitle => 'ورديّاتي';

  @override
  String get nextWeekTooltip => 'الأسبوع القادم';

  @override
  String get prevWeekTooltip => 'الأسبوع الماضي';

  @override
  String get loadShiftsError => 'خطأ في تحميل الورديات';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get pastLabel => 'ماضٍ';

  @override
  String get noShiftsDay => 'لا توجد ورديات';

  @override
  String get loadingShifts => 'جارٍ تحميل الورديات...';

  @override
  String get loginToViewShifts => 'يرجى تسجيل الدخول لعرض الورديات';

  @override
  String get viewShiftDetailsButton => 'عرض تفاصيل الوردية';

  @override
  String get allShiftsTabLabel => 'جميع الورديات';

  @override
  String get weeklyScheduleTitle => 'جدول العمل الأسبوعي';

  @override
  String get noWorkersAssigned => 'لم يتم تعيين موظفين';

  @override
  String get noWorkersAssignedForShift => 'لم يتم تعيين موظفين لهذه الوردية';

  @override
  String get managerRoleShort => 'مدير';

  @override
  String get workerRoleShort => 'موظف';

  @override
  String get noShiftsThisWeek => 'لا توجد ورديات هذا الأسبوع';

  @override
  String get notAssignedThisWeek => 'لم يتم تعيينك في ورديات هذا الأسبوع';

  @override
  String get changesSavedSuccess => 'تم حفظ التغييرات بنجاح!';

  @override
  String saveChangesError(String error) {
    return 'خطأ في حفظ التغييرات: $error';
  }

  @override
  String unsavedChangesCountMessage(int count) {
    return 'لديك $count تغييرات غير محفوظة. هل أنت متأكد أنك تريد الخروج؟';
  }

  @override
  String get cancelAllButton => 'إلغاء الكل';

  @override
  String saveChangesWithCount(int count) {
    return 'حفظ التغييرات ($count)';
  }

  @override
  String get workersLabel => 'الموظفون';

  @override
  String get requestsTabLabel => 'الطلبات';

  @override
  String get approvedTabLabel => 'المعتمدون';

  @override
  String get messagesTabLabel => 'الرسائل';

  @override
  String get detailsTabLabel => 'التفاصيل';

  @override
  String get noPendingRequests => 'لا توجد طلبات معلقة';

  @override
  String get newRequestsWillAppear => 'ستظهر الطلبات الجديدة هنا';

  @override
  String get willBeApprovedLabel => 'سيتم القبول';

  @override
  String get willBeRejectedLabel => 'سيتم الرفض';

  @override
  String get addWorkersButton => 'إضافة موظفين';

  @override
  String get noAssignedWorkersEmpty => 'لا يوجد موظفون معيّنون';

  @override
  String get clickAddWorkersHint => 'انقر على \"إضافة موظفين\" للإضافة يدوياً';

  @override
  String get willBeAddedLabel => 'سيتم الإضافة';

  @override
  String get willBeRemovedLabel => 'سيتم الإزالة';

  @override
  String get willBeRestoredLabel => 'سيتم الاستعادة';

  @override
  String get sendFirstMessage => 'أرسل أول رسالة';

  @override
  String get writeMessageHint => 'اكتب رسالة...';

  @override
  String get createdByLabel => 'تم الإنشاء بواسطة';

  @override
  String get creationDateLabel => 'تاريخ الإنشاء';

  @override
  String get lastUpdatedByLabel => 'آخر تحديث بواسطة';

  @override
  String get shiftManagerLabel => 'مسؤول الوردية';

  @override
  String pendingChangesBanner(int count) {
    return '$count تغييرات في انتظار الحفظ';
  }

  @override
  String workersWillBeApproved(int count) {
    return 'سيتم قبول $count عامل';
  }

  @override
  String requestsWillBeRejected(int count) {
    return 'سيتم رفض $count طلب';
  }

  @override
  String workersWillBeRemoved(int count) {
    return 'سيتم إزالة $count عامل';
  }

  @override
  String workersWillBeRestored(int count) {
    return 'سيتم إعادة $count عامل إلى قائمة الانتظار';
  }

  @override
  String workersWillBeAdded(int count) {
    return 'سيتم إضافة $count عامل';
  }

  @override
  String commentsCountLabel(int count) {
    return '$count تعليق';
  }

  @override
  String get editCommentTitle => 'تعديل التعليق';

  @override
  String get editCommentHint => 'عدّل تعليقك...';

  @override
  String get postTypeAnnouncementDesc => 'إعلانات مهمة لجميع العمال';

  @override
  String get postTypeUpdateDesc => 'تحديثات وتغييرات';

  @override
  String get postTypeEventDesc => 'فعاليات وأنشطة';

  @override
  String get postTypeGeneralDesc => 'معلومات عامة';

  @override
  String get dateRangeButton => 'نطاق التواريخ';

  @override
  String get selectDateRange => 'حدد نطاق التواريخ';

  @override
  String get noAttendanceDataMonth => 'لا توجد بيانات حضور لهذا الشهر';

  @override
  String chartTooltipDayHours(int day, String hours) {
    return 'يوم $day\n$hours ساعات';
  }

  @override
  String get missingClockOutLabel => 'خروج مفقود';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hoursس $minutesد';
  }

  @override
  String clockInPrefix(String time) {
    return 'دخول: $time';
  }

  @override
  String clockOutPrefix(String time) {
    return 'خروج: $time';
  }

  @override
  String get exportingLabel => 'جارٍ التصدير...';

  @override
  String get exportPdfButton => 'تصدير PDF';

  @override
  String get allWorkersValidClockout =>
      'جميع العمال سجّلوا خروجهم بشكل صحيح هذا الشهر';

  @override
  String get noShiftsMonth => 'لا توجد وردیات لهذا الشهر';

  @override
  String shiftCountAndSlotsFormat(int count, int filled, int total) {
    return '$count ورديات · $filled/$total أماكن ممتلئة';
  }

  @override
  String shiftCountTooltip(int count) {
    return '$count ورديات';
  }

  @override
  String get taskDistributionTitle => 'توزيع المهام';

  @override
  String get noTasksMonth => 'لا توجد مهام لهذا الشهر';

  @override
  String get totalTasksLabel => 'إجمالي المهام';

  @override
  String get workersWithTasksLabel => 'عمال لديهم مهام';

  @override
  String get completionRateLabel => 'معدل الإنجاز';

  @override
  String get completionRateByWorkerTitle => 'معدل الإنجاز حسب العامل';

  @override
  String get topTenLabel => '(أفضل 10)';

  @override
  String get workerDetailsTitle => 'تفاصيل العمال';

  @override
  String get executionLabel => 'إنجاز';

  @override
  String get statusDistributionTitle => 'توزيع الحالة';

  @override
  String get taskDetailsListTitle => 'تفاصيل المهام';

  @override
  String taskGoalPrefix(String date) {
    return 'الموعد: $date';
  }

  @override
  String get taskTimelineSubmitted => 'قُدِّمت';

  @override
  String get taskTimelineStarted => 'بدأت';

  @override
  String get taskTimelineEnded => 'انتهت';

  @override
  String get workersHoursTitle => 'ساعات العمل';

  @override
  String get activeWorkersLabel => 'عمال نشطون';

  @override
  String get totalHoursLabel => 'إجمالي الساعات';

  @override
  String get avgPerWorkerLabel => 'متوسط للعامل';

  @override
  String get hoursByWorkerTitle => 'ساعات حسب العامل';

  @override
  String workerDaysAndAvgFormat(int days, String avg) {
    return '$days أيام · متوسط $avg س/يوم';
  }

  @override
  String get generalReportsTabLabel => 'التقارير العامة';

  @override
  String get personalReportsSubtitle =>
      'عرض بيانات الحضور والمهام والورديات الشخصية';

  @override
  String get attendanceReportDescription =>
      'ساعات العمل وأيام الحضور والملخص الشهري';

  @override
  String get taskReportDescription => 'حالة المهام والتقدم ونسب الإنجاز';

  @override
  String get shiftReportDescription => 'سجل الورديات والموافقات والقرارات';

  @override
  String get generalReportsTitle => 'التقارير العامة';

  @override
  String get generalReportsSubtitle => 'بيانات مجمّعة لجميع العمال';

  @override
  String get workersHoursDescription => 'ملخص شهري لساعات العمل حسب العامل';

  @override
  String get taskDistributionDescription =>
      'المهام حسب العامل ونسب الإنجاز والترتيب';

  @override
  String get shiftCoverageDescription =>
      'الورديات حسب القسم ونسبة الامتلاء والتفاصيل';

  @override
  String get missingClockoutsDescription =>
      'العمال الذين نسوا تسجيل الخروج حسب الشهر';

  @override
  String reportsOfWorker(String name) {
    return 'تقارير $name';
  }

  @override
  String get workerReportsSubtitle => 'عرض بيانات الحضور والمهام والورديات';

  @override
  String get performanceSummaryTitle => 'ملخص الأداء — هذا الشهر';

  @override
  String hoursWithValue(String hours) {
    return '$hours ساعات';
  }

  @override
  String daysWithValue(int days) {
    return '$days أيام';
  }

  @override
  String get presenceLabel => 'الحضور';

  @override
  String get atWorkLabel => 'في العمل';

  @override
  String get tasksCompletedLabel => 'مهام منجزة';

  @override
  String shiftDecisionApproved(int count) {
    return 'موافق ($count)';
  }

  @override
  String shiftDecisionRejected(int count) {
    return 'مرفوض ($count)';
  }

  @override
  String shiftDecisionOther(int count) {
    return 'أخرى ($count)';
  }

  @override
  String get showDetailsLabel => 'عرض التفاصيل';

  @override
  String get hideDetailsLabel => 'إخفاء التفاصيل';

  @override
  String get approvedByLabel => 'موافق من قِبَل';

  @override
  String get roleAtAssignmentLabel => 'الدور عند التعيين';

  @override
  String get requestTimeLabel => 'وقت الطلب';

  @override
  String get removedByLabel => 'أُزيل بواسطة';

  @override
  String get removalTimeLabel => 'وقت الإزالة';

  @override
  String get cancelledByLabel => 'أُلغي بواسطة';

  @override
  String get cancellationTimeLabel => 'وقت الإلغاء';

  @override
  String get shiftStatusActiveFem => 'نشطة';

  @override
  String get shiftStatusCancelledFem => 'ملغاة';

  @override
  String get shiftStatusPendingFem => 'معلقة';

  @override
  String get decisionAcceptedLabel => 'مقبول';

  @override
  String get decisionRejectedLabel => 'مرفوض';

  @override
  String get decisionRemovedLabel => 'محذوف';

  @override
  String get decisionPendingLabel => 'قيد الانتظار';

  @override
  String get shiftManagerRoleLabel => 'مدير الوردية';

  @override
  String get deptManagerRoleLabel => 'مدير القسم';

  @override
  String hoursAbbrFormat(String hours) {
    return '$hours س';
  }

  @override
  String get pickPhotoOption => 'اختر صوراً';

  @override
  String get pickPhotoSubtitle => 'اختر صوراً من المعرض';

  @override
  String get adminRoleLabel => 'مدير النظام';

  @override
  String reactorsPeopleCount(int count) {
    return '$count أشخاص';
  }

  @override
  String get deptGeneral => 'عام';

  @override
  String get deptPaintball => 'بينتبول';

  @override
  String get deptRopes => 'حديقة الحبال';

  @override
  String get deptCarting => 'كارتينج';

  @override
  String get deptWaterPark => 'حديقة مائية';

  @override
  String get deptJimbory => 'جيمبوري';

  @override
  String get deptOperations => 'العمليات';

  @override
  String get preparingUploadShort => 'جاري التحضير...';

  @override
  String get clockReminder10hTitle => 'هل نسيت تسجيل الخروج؟ ⏰';

  @override
  String get clockReminder10hBody =>
      'أنت في الوردية منذ 10 ساعات. تذكر تسجيل الخروج.';

  @override
  String get clockReminder12hTitle => 'وردية طويلة جداً! 🚨';

  @override
  String get clockReminder12hBody =>
      'أنت في الوردية منذ 12 ساعة. سجّل الخروج في أقرب وقت.';

  @override
  String get taskDeadlineReminderTitle => 'تذكير بالمهمة ⏰';

  @override
  String taskDeadlineReminderBody(String title) {
    return '$title — أقل من 24 ساعة متبقية للإنجاز';
  }

  @override
  String pendingApprovalCount(int count) {
    return '$count عمال في انتظار الموافقة';
  }

  @override
  String understaffedShiftsCount(int count) {
    return '$count وردية اليوم تفتقر للعمال';
  }

  @override
  String get hoursAbbreviation => 'س';

  @override
  String get minutesAbbreviation => 'د';

  @override
  String daysThisMonth(int count) {
    return '$count أيام هذا الشهر';
  }

  @override
  String totalHoursCount(String count) {
    return '$count ساعات';
  }

  @override
  String activeDepartmentsPercent(int percent) {
    return '$percent% من الأقسام نشطة';
  }

  @override
  String get autoClockoutTitle => 'تسجيل خروج تلقائي من الوردية';

  @override
  String get autoClockoutBody =>
      'لم تُبلّغ عن الخروج بعد 16 ساعة – أنهى النظام الوردية تلقائياً. تواصل مع مديرك.';

  @override
  String get postCategoryAnnouncement => 'إعلان';

  @override
  String get postCategoryUpdate => 'تحديث';

  @override
  String get postCategoryEvent => 'حدث';

  @override
  String get postCategoryGeneral => 'عام';

  @override
  String get locationRationaleTitle => 'الوصول إلى الموقع';

  @override
  String get locationRationaleMessage =>
      'يحتاج التطبيق إلى الوصول إلى موقعك للسماح بتسجيل الدخول والخروج داخل نطاق الحديقة.\n\nيُستخدم الموقع فقط للتحقق من الحضور ولا يُخزَّن أو يُشارَك.';

  @override
  String get locationRationaleConfirm => 'السماح بالوصول';

  @override
  String get locationRationaleCancel => 'ليس الآن';

  @override
  String get biometricLoginReason => 'تحقق من هويتك لتسجيل الدخول إلى التطبيق';

  @override
  String get shiftApprovedTitle => 'تمت الموافقة على طلبك للوردية';

  @override
  String shiftApprovedBody(String date, String startTime, String endTime) {
    return 'تم تعيينك في الوردية بتاريخ $date، $startTime–$endTime';
  }

  @override
  String get shiftRejectedTitle => 'تم رفض طلبك للوردية';

  @override
  String shiftRejectedBody(String date, String startTime, String endTime) {
    return 'لم تتم الموافقة على طلبك للوردية بتاريخ $date، $startTime–$endTime';
  }

  @override
  String uploadingVideoProgress(int current, int total) {
    return 'جارٍ رفع الفيديو $current من $total...';
  }

  @override
  String uploadingImageProgress(int current, int total) {
    return 'جارٍ رفع الصورة $current من $total...';
  }

  @override
  String uploadingProgress(int current, int total) {
    return 'جارٍ الرفع $current من $total...';
  }

  @override
  String get generatingThumbnailStatus => 'جارٍ إنشاء الصورة المصغرة...';

  @override
  String fileUploadedStatus(int current) {
    return 'تم رفع الملف $current';
  }

  @override
  String get agreeToPrivacyPrefix => 'لقد قرأت وأوافق على';

  @override
  String get andConnector => 'و';

  @override
  String get privacyPolicyRequiredError =>
      'يجب الموافقة على سياسة الخصوصية للمتابعة';
}
