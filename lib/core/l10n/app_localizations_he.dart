// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'פארק ג׳ננה';

  @override
  String get loginButton => 'כניסה';

  @override
  String get newWorkerButton => 'עובד חדש?';

  @override
  String get logoutLabel => 'התנתק';

  @override
  String get logoutTitle => 'התנתקות';

  @override
  String get logoutConfirmation => 'האם אתה בטוח שברצונך להתנתק?';

  @override
  String get errorGeneral => 'אירעה שגיאה, נסה שוב';

  @override
  String get retryButton => 'נסה שוב';

  @override
  String get profileScreenTitle => 'האזור האישי שלך';

  @override
  String get forgotPassword => 'שכחתי סיסמה';

  @override
  String get shiftsTitle => 'משמרות זמינות';

  @override
  String get managerDashboardTitle => 'לוח ניהול משמרות';

  @override
  String get newShiftButton => 'צור משמרת חדשה';

  @override
  String get profileUpdateSuccess => 'התמונה עודכנה בהצלחה';

  @override
  String get shiftRequestSuccess => 'בקשתך נשלחה למשמרת';

  @override
  String get shiftCancelSuccess => 'הבקשה למשמרת בוטלה';

  @override
  String get confirmButton => 'אישור';

  @override
  String get cancelButton => 'ביטול';

  @override
  String get saveButton => 'שמור';

  @override
  String get closeButton => 'סגור';

  @override
  String get noInternetError =>
      'לא ניתן להתחבר לשרתי האפליקציה. אנא בדוק את החיבור לאינטרנט ונסה שוב.';

  @override
  String get languageLabel => 'שפה';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get appInitializationError => 'שגיאה באתחול האפליקציה';

  @override
  String get contactSupportMessage => 'אם הבעיה נמשכת, אנא צור קשר עם התמיכה';

  @override
  String get offlineStatusText => 'אין חיבור לאינטרנט';

  @override
  String get onlineStatusText => 'החיבור לאינטרנט שוחזר ✓';

  @override
  String get offlineModeLabel => 'פועל במצב לא מקוון';

  @override
  String get managerRole => 'מנהל';

  @override
  String get messageUpdateError => 'שגיאה בעדכון ההודעה';

  @override
  String get messageDeletionError => 'שגיאה במחיקת ההודעה';

  @override
  String get passwordRecoveryTitle => 'שחזור סיסמה';

  @override
  String get enterEmailAddressPrompt => 'אנא הזן את כתובת האימייל שלך';

  @override
  String get emailRequiredValidation => 'אנא הכנס כתובת אימייל';

  @override
  String get emailInvalidValidation => 'אנא הכנס כתובת אימייל תקינה';

  @override
  String get resetLinkSent => 'קישור לאיפוס הסיסמה נשלח למייל שלך';

  @override
  String get resetLinkError => 'שגיאה בשליחת קישור לאיפוס סיסמה';

  @override
  String get sendResetLinkButton => 'שלח קישור לאיפוס';

  @override
  String get backButton => 'חזור';

  @override
  String get welcomeTitle => 'שלום, ברוכים הבאים';

  @override
  String get loginCredentialsPrompt => 'אנא הכנס את פרטי הכניסה שלך';

  @override
  String get emailFieldLabel => 'אימייל';

  @override
  String get emailFieldHint => 'הכנס את כתובת האימייל שלך';

  @override
  String get passwordFieldLabel => 'סיסמה';

  @override
  String get passwordFieldHint => 'הכנס את הסיסמה שלך';

  @override
  String get passwordRequiredError => 'אנא הכנס סיסמה';

  @override
  String get passwordLengthError => 'הסיסמה חייבת להכיל לפחות 6 תווים';

  @override
  String get orDividerText => 'או';

  @override
  String get biometricLoginTitle => 'כניסה ביומטרית';

  @override
  String get biometricSetupPrompt =>
      'האם לאפשר כניסה עתידית באמצעות טביעת אצבע / זיהוי פנים?';

  @override
  String get enableBiometricButton => 'אפשר';

  @override
  String get declineBiometricButton => 'לא, תודה';

  @override
  String get biometricAuthFailed => 'אימות ביומטרי נכשל. אנא נסה שוב.';

  @override
  String get noBiometricCredentials =>
      'לא נמצאו פרטי כניסה שמורים. אנא כנס עם אימייל וסיסמה.';

  @override
  String get applicationRejectedTitle => 'הבקשה נדחתה';

  @override
  String get applicationRejectedMessage =>
      'בקשתך לאישור נדחתה על ידי ההנהלה.\nניתן לשלוח בקשת אישור חדשה.';

  @override
  String get reApplyButton => 'שלח בקשה מחדש';

  @override
  String get reApplySuccess => 'הבקשה נשלחה מחדש. ההנהלה תעדכן אותך בהחלטה.';

  @override
  String get registrationTitle => 'הרשמה לפארק גננה';

  @override
  String get registrationSubtitle => 'מלא את הפרטים לשליחת בקשת הצטרפות';

  @override
  String get nameRequiredValidation => 'יש להזין שם מלא';

  @override
  String get nameInvalidCharsValidation => 'יש להזין שם בתווים תקינים בלבד';

  @override
  String get fullNameLabel => 'שם מלא';

  @override
  String get fullNameHint => 'לדוגמה: ישראל ישראלי';

  @override
  String get phoneDigitsValidation => 'מספר טלפון חייב להכיל בדיוק 10 ספרות';

  @override
  String get phoneFormatValidation => 'מספר טלפון ישראלי חייב להתחיל ב-05';

  @override
  String get phoneLabel => 'מספר טלפון';

  @override
  String get phoneHint => '05XXXXXXXX';

  @override
  String get idDigitsValidation => 'תעודת זהות חייבת להכיל בדיוק 9 ספרות';

  @override
  String get idCheckDigitValidation => 'מספר תעודת הזהות אינו תקין';

  @override
  String get idLabel => 'תעודת זהות';

  @override
  String get idHint => '9 ספרות';

  @override
  String get emailLabel => 'כתובת אימייל';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordMinLengthValidation => 'הסיסמה חייבת להכיל לפחות 6 תווים';

  @override
  String get passwordLabel => 'סיסמה';

  @override
  String get passwordHint => 'לפחות 6 תווים';

  @override
  String get passwordMismatchValidation => 'הסיסמאות אינן תואמות';

  @override
  String get confirmPasswordLabel => 'אישור סיסמה';

  @override
  String get confirmPasswordHint => 'הזן שוב את הסיסמה';

  @override
  String get personalDetailsSection => 'פרטים אישיים';

  @override
  String get loginDetailsSection => 'פרטי כניסה';

  @override
  String validationErrorsBanner(int count, String noun) {
    return 'יש לתקן $count $noun לפני שליחה';
  }

  @override
  String get validationErrorSingular => 'שגיאה';

  @override
  String get validationErrorPlural => 'שגיאות';

  @override
  String get registrationApprovalNotice =>
      'לאחר שליחת הבקשה, ההנהלה תאשר את חשבונך ותוכל להתחבר לאפליקציה.';

  @override
  String get submitRegistrationButton => 'שלח בקשת הצטרפות';

  @override
  String get registrationSuccessTitle => 'הבקשה נשלחה בהצלחה!';

  @override
  String get registrationSuccessMessage =>
      'הנהלת הפארק תבדוק את פרטיך ותיצור איתך קשר בהקדם האפשרי.';

  @override
  String get registrationApprovalInfo =>
      'לאחר אישור ההנהלה תקבל גישה לאפליקציה ותוכל להתחבר.';

  @override
  String get backToHomeButton => 'חזור לדף הראשי';

  @override
  String get newWorkerWelcomeTitle => 'עובד חדש? ברוך הבא!';

  @override
  String get registrationStepsSubtitle =>
      'הצטרף לצוות פארק גננה בכמה צעדים פשוטים';

  @override
  String get howItWorksSection => 'איך זה עובד?';

  @override
  String get step1Title => 'מלא טופס הרשמה';

  @override
  String get step1Subtitle => 'הזן את פרטיך האישיים ובחר סיסמה';

  @override
  String get step2Title => 'אישור ההנהלה';

  @override
  String get step2Subtitle => 'הנהלת הפארק תבדוק את פרטיך ותאשר את חשבונך';

  @override
  String get step3Title => 'הצטרף לצוות';

  @override
  String get step3Subtitle => 'לאחר האישור תוכל להתחבר ולהתחיל לעבוד';

  @override
  String get welcomeSubtitle => 'ברוכים הבאים';

  @override
  String get shiftsNavLabel => 'משמרות';

  @override
  String get weeklyScheduleNavLabel => 'סידור עבודה';

  @override
  String get tasksNavLabel => 'משימות';

  @override
  String get reportsNavLabel => 'דוחות';

  @override
  String get newsfeedNavLabel => 'לוח מודעות';

  @override
  String get manageWorkersNavLabel => 'ניהול עובדים';

  @override
  String get weeklySchedulingNavLabel => 'סידור שבועי';

  @override
  String get dashboardNavLabel => 'לוח בקרה';

  @override
  String get totalTeamLabel => 'צוות כולל';

  @override
  String get monthlyHoursLabel => 'שעות החודש';

  @override
  String get openTasksLabel => 'משימות פתוחות';

  @override
  String get presentTodayLabel => 'נוכחים היום';

  @override
  String get createShiftAction => 'צור משמרת';

  @override
  String get createTaskAction => 'צור משימה';

  @override
  String get publishPostAction => 'פרסם הודעה';

  @override
  String get hoursReportAction => 'דוח שעות';

  @override
  String get workersTabLabel => 'עובדים';

  @override
  String get managersTabLabel => 'מנהלים';

  @override
  String get todayTabLabel => 'היום';

  @override
  String get thisWeekTabLabel => 'השבוע';

  @override
  String get openTasksTabLabel => 'פתוחות';

  @override
  String get urgentTasksTabLabel => 'דחוף';

  @override
  String get cropImageTitle => 'חתוך תמונה';

  @override
  String get profilePictureUpdated => 'תמונת הפרופיל עודכנה בהצלחה';

  @override
  String uploadError(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get takePhotoAction => 'צלם תמונה';

  @override
  String get takePhrotoSubtitle => 'השתמש במצלמה';

  @override
  String get chooseFromGalleryAction => 'בחר מהגלריה';

  @override
  String get uploadFromGallerySubtitle => 'העלה מהתמונות שלך';

  @override
  String get noDataFound => 'לא נמצאו נתונים';

  @override
  String get authorizedDepartmentsLabel => 'מחלקות מורשות';

  @override
  String get departmentPermissionsSection => 'הרשאות מחלקה';

  @override
  String get workerRoleLabel => 'עובד';

  @override
  String get ownerRoleLabel => 'בעלים';

  @override
  String get coOwnerRoleLabel => 'בעלים משותף';

  @override
  String get attendanceSaved => 'הנוכחות נשמרה בהצלחה';

  @override
  String get attendanceSaveError => 'שגיאה בשמירת הנוכחות';

  @override
  String get endShiftDialogTitle => 'סיום משמרת';

  @override
  String get recordCheckoutConfirmation => 'לרשום יציאה עכשיו עבור משמרת זו?';

  @override
  String get endShiftButton => 'סיים משמרת';

  @override
  String get checkoutRecordedReminder => 'שעת יציאה נרשמה — זכור לשמור';

  @override
  String get recordUpdatedReminder => 'הרשומה עודכנה — זכור לשמור';

  @override
  String get recordAddedReminder => 'רשומה נוספה — זכור לשמור';

  @override
  String recordDeleted(int recordNumber) {
    return 'רשומה מס׳ $recordNumber נמחקה';
  }

  @override
  String get undoButton => 'בטל';

  @override
  String get unsavedChangesTitle => 'שינויים לא נשמרו';

  @override
  String get stayButton => 'הישאר';

  @override
  String get exitWithoutSavingButton => 'צא ללא שמירה';

  @override
  String get workDaysLabel => 'ימי עבודה';

  @override
  String get hoursLabel => 'שעות';

  @override
  String get hoursShortLabel => 'שע׳';

  @override
  String get recordsLabel => 'רשומות';

  @override
  String get missingCheckoutLabel => 'חסר יציאה';

  @override
  String get addRecordButton => 'הוסף רשומה';

  @override
  String get checkInFieldLabel => 'כניסה';

  @override
  String get checkOutFieldLabel => 'יציאה';

  @override
  String attendanceReportError(String error) {
    return 'שגיאה בדיווח נוכחות: $error';
  }

  @override
  String get outsideParkBoundsMessage => 'אינך נמצא בגבולות הפארק';

  @override
  String get draftRestoredSnackbar => 'טיוטה שוחזרה';

  @override
  String get clearDraftAction => 'נקה';

  @override
  String get taskTitleRequiredValidation => 'נא להזין כותרת למשימה';

  @override
  String get selectAtLeastOneWorkerValidation => 'נא לבחור לפחות עובד אחד';

  @override
  String get selectDeadlineValidation => 'נא לבחור תאריך ושעה';

  @override
  String get noCommentsEmpty => 'אין תגובות עדיין';

  @override
  String get callDialogTitle => 'שיחה יוצאת';

  @override
  String callConfirmation(String name, String phone) {
    return 'להתקשר אל $name?\n$phone';
  }

  @override
  String dialFailed(String phone) {
    return 'לא ניתן לחייג אל $phone';
  }

  @override
  String get noPendingWorkersEmpty => 'אין עובדים שממתינים לאישור';

  @override
  String get callTooltip => 'התקשר';

  @override
  String get noActiveWorkersEmpty => 'אין עובדים פעילים במערכת';

  @override
  String get workerApproved => 'העובד אושר בהצלחה';

  @override
  String get applicationRejectedSnackbar => 'הבקשה נדחתה. העובד קיבל הודעה.';

  @override
  String get approveWorkerButton => 'אשר עובד';

  @override
  String get approveWorkerTitle => 'אישור עובד';

  @override
  String get rejectApplicationButton => 'דחה בקשה';

  @override
  String get rejectApplicationTitle => 'דחיית בקשה';

  @override
  String get showShiftsButton => 'הצג משמרות';

  @override
  String get assignTaskButton => 'שייך משימה';

  @override
  String get viewPerformanceButton => 'הצג ביצועים';

  @override
  String get correctAttendanceButton => 'תיקון נוכחות';

  @override
  String get managePermissionsButton => 'ניהול הרשאות ותפקיד';

  @override
  String get revokeApprovalButton => 'בטל אישור עובד';

  @override
  String get revokeApprovalTitle => 'ביטול אישור עובד';

  @override
  String get revokeApprovalMessage =>
      'העובד יועבר חזרה לרשימת הממתינים לאישור. הפעולה ניתנת לביטול.';

  @override
  String get approvalRevoked => 'אישור העובד בוטל';

  @override
  String get licensesUpdated => 'ההרשאות עודכנו בהצלחה';

  @override
  String get saveLicensesError => 'שגיאה בשמירת הנתונים';

  @override
  String get attendanceReportTitle => 'דו״ח נוכחות';

  @override
  String get daysLabel => 'ימים';

  @override
  String get averagePerDayLabel => 'ממוצע/יום';

  @override
  String get hoursPerDayChartTitle => 'שעות עבודה לפי יום';

  @override
  String get attendanceDetailsTitle => 'פירוט נוכחות';

  @override
  String get shiftReportTitle => 'דו״ח משמרות';

  @override
  String get totalLabel => 'סה״כ';

  @override
  String get approvedLabel => 'אושרו';

  @override
  String get rejectedOtherLabel => 'נדחו/אחר';

  @override
  String get decisionsDistributionTitle => 'התפלגות החלטות';

  @override
  String get shiftsDetailsTitle => 'פירוט משמרות';

  @override
  String get shiftCoverageTitle => 'כיסוי משמרות';

  @override
  String get totalShiftsLabel => 'סה\"כ משמרות';

  @override
  String get staffingRateLabel => 'מילוי משרות';

  @override
  String get activeDepartmentsLabel => 'מחלקות פעילות';

  @override
  String get shiftsByDepartmentTitle => 'משמרות לפי מחלקה';

  @override
  String get departmentDetailsTitle => 'פירוט מחלקות';

  @override
  String get missingCheckoutsTitle => 'יציאות חסרות';

  @override
  String get noMissingCheckoutsEmpty => 'אין יציאות חסרות';

  @override
  String get detailsByWorkerTitle => 'פירוט לפי עובד';

  @override
  String get myReportsTitle => 'הדוחות שלי';

  @override
  String get taskReportCard => 'דו״ח משימות';

  @override
  String get selectPhotosAction => 'בחר תמונות';

  @override
  String get selectPhotosFromGallery => 'בחר תמונות מהגלריה';

  @override
  String get selectVideoAction => 'בחר סרטון';

  @override
  String get selectVideoFromGallery => 'בחר סרטון מהגלריה';

  @override
  String get openCameraSubtitle => 'פתח את המצלמה';

  @override
  String get postTitleHint => 'הזן כותרת לפוסט...';

  @override
  String get postContentHint => 'מה תרצה לשתף?';

  @override
  String get deleteCommentTitle => 'מחיקת תגובה';

  @override
  String get deleteCommentConfirmation =>
      'האם אתה בטוח שברצונך למחוק את התגובה?';

  @override
  String get deletePostTitle => 'מחיקת פוסט';

  @override
  String get deletePostConfirmation =>
      'האם אתה בטוח שברצונך למחוק את הפוסט?\nפעולה זו לא ניתנת לביטול.';

  @override
  String get editPostAction => 'ערוך פוסט';

  @override
  String get deletePostAction => 'מחק פוסט';

  @override
  String get editingPostTitle => 'עריכת פוסט';

  @override
  String get notificationsTitle => 'התראות';

  @override
  String get markAllAsReadButton => 'סמן הכל כנקרא';

  @override
  String get loadNotificationsError => 'שגיאה בטעינת ההתראות';

  @override
  String get openShiftError => 'שגיאה בפתיחת המשמרת';

  @override
  String get openTaskError => 'שגיאה בפתיחת המשימה';

  @override
  String get noNotificationsEmpty => 'אין התראות';

  @override
  String get newNotificationsWillAppear => 'התראות חדשות יופיעו כאן';

  @override
  String get cannotOpenLink => 'לא ניתן לפתוח את הקישור';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get changePasswordTitle => 'שינוי סיסמה';

  @override
  String get biometricMethodsSubtitle => 'טביעת אצבע / זיהוי פנים';

  @override
  String get pushNotificationsTitle => 'התראות פוש';

  @override
  String get pushNotificationsSubtitle => 'קבלת עדכונים על משמרות ומשימות';

  @override
  String get privacyPolicyTitle => 'מדיניות פרטיות';

  @override
  String get termsOfServiceTitle => 'תנאי שימוש';

  @override
  String get crashReportsTitle => 'שלח דוחות קריסה';

  @override
  String get crashReportsSubtitle => 'עוזר לנו לשפר את יציבות האפליקציה';

  @override
  String get appVersionTitle => 'גרסת האפליקציה';

  @override
  String get deleteAccountTitle => 'מחיקת חשבון';

  @override
  String get deleteAccountSubtitle => 'פעולה בלתי הפיכה — כל הנתונים יימחקו';

  @override
  String get passwordChanged => 'הסיסמה עודכנה בהצלחה';

  @override
  String get biometricAuthFailedSnackbar => 'האימות הביומטרי נכשל';

  @override
  String get enableBiometricError => 'שגיאה בהפעלת הכניסה הביומטרית';

  @override
  String get enableBiometricTitle => 'הפעלת כניסה ביומטרית';

  @override
  String get permanentDeletionTitle => 'מחיקה סופית';

  @override
  String get optionsTooltip => 'אפשרויות';

  @override
  String get settingsMenu => 'הגדרות';

  @override
  String get noButton => 'לא';

  @override
  String get yesButton => 'כן';

  @override
  String get longPressHint => 'לחץ לחיצה ארוכה';

  @override
  String get weatherLabel => 'מזג אוויר';

  @override
  String get loadDataError => 'לא ניתן לטעון נתונים. בדוק חיבור או אינדקס.';

  @override
  String get noShiftsEmpty => 'אין משמרות להצגה';

  @override
  String shiftHoursFormat(String startTime, String endTime) {
    return 'שעות: $startTime - $endTime';
  }

  @override
  String departmentPrefix(String department) {
    return 'מחלקה: $department';
  }

  @override
  String get unsavedChangesMessage =>
      'יש לך שינויים שלא נשמרו. האם אתה בטוח שברצונך לצאת?';

  @override
  String get noAttendanceRecords => 'אין רשומות נוכחות לחודש זה';

  @override
  String get addManualRecordHint => 'הוסף רשומה ידנית או בחר חודש אחר';

  @override
  String get missingLabel => 'חסר';

  @override
  String get activeLabel => 'פעיל';

  @override
  String get saveChangesButton => 'שמור שינויים';

  @override
  String get editAttendanceRecordTitle => 'עריכת רשומת נוכחות';

  @override
  String get locationPermissionTitle => 'נדרשת גישה למיקום';

  @override
  String get locationPermissionMessage =>
      'כדי לדווח כניסה או יציאה ממשמרת יש לאפשר שירותי מיקום במכשיר.';

  @override
  String get enableLocationButton => 'הפעל מיקום';

  @override
  String get clockInOutsideParkMessage =>
      'אתה מנסה להתחבר מחוץ לאזור המותר. האם ברצונך להמשיך בכל זאת?';

  @override
  String get clockOutOutsideParkMessage =>
      'אתה מנסה להתנתק מחוץ לאזור המותר. האם ברצונך להמשיך בכל זאת?';

  @override
  String get longPressToEndShift => 'לחיצה ארוכה לסיום משמרת';

  @override
  String get longPressToStartShift => 'לחיצה ארוכה להתחיל משמרת';

  @override
  String clockedInSince(String time) {
    return 'מאז $time';
  }

  @override
  String datePrefix(String date) {
    return 'תאריך: $date';
  }

  @override
  String clockInTimePrefix(String time) {
    return 'שעת כניסה: $time';
  }

  @override
  String clockOutTimePrefix(String time) {
    return 'שעת יציאה: $time';
  }

  @override
  String workDurationLabel(int hours, int minutes) {
    return 'משך העבודה: $hoursש׳ $minutesד׳';
  }

  @override
  String get greetingNight => 'לילה טוב,';

  @override
  String get greetingMorning => 'בוקר טוב,';

  @override
  String get greetingAfternoon => 'צהריים טובים,';

  @override
  String get greetingEvening => 'ערב טוב,';

  @override
  String get motivationalMsg1 => 'אתה חלק חשוב בצוות שלנו 💪';

  @override
  String get motivationalMsg2 => 'כל משמרת היא הזדמנות להשפיע ✨';

  @override
  String get motivationalMsg3 => 'תשמור על חיוך – זה מדבק 😄';

  @override
  String get thisMonthLabel => 'החודש';

  @override
  String get nowLabel => 'עכשיו';

  @override
  String minutesAgoLabel(int n) {
    return 'לפני $n דק\'';
  }

  @override
  String hoursAgoLabel(int n) {
    return 'לפני $n שע\'';
  }

  @override
  String get yesterdayLabel => 'אתמול';

  @override
  String daysAgoLabel(int n) {
    return 'לפני $n ימים';
  }

  @override
  String get latestUpdateLabel => 'עדכון אחרון';

  @override
  String get readMoreLabel => 'קרא עוד';

  @override
  String get whatIsImportantNow => 'מה חשוב עכשיו';

  @override
  String get allUpToDate => 'הכל מעודכן — אין פריטים דחופים';

  @override
  String get shiftChangesWaiting => 'שינויים במשמרות ממתינים';

  @override
  String get tasksWaitingApproval => 'משימות ממתינות לאישור';

  @override
  String get newPostsInBoard => 'פוסטים חדשים בלוח המודעות';

  @override
  String get newUpdatesInBoard => 'עדכונים חדשים בלוח המודעות';

  @override
  String get newBusinessActivity => 'פעילות עסקית חדשה לבדיקה';

  @override
  String get newShiftsAssigned => 'משמרות חדשות שהוקצו לך';

  @override
  String get openTasksWaiting => 'משימות פתוחות ממתינות לך';

  @override
  String get clickToResetClockOut => 'לחץ לאיפוס שעון יציאה';

  @override
  String get clickToRegisterClockIn => 'לחץ לרישום שעון כניסה';

  @override
  String get completedLabel => 'הושלמו';

  @override
  String get presentNowLabel => 'נוכחים כעת';

  @override
  String get noWorkersConnected => 'אין עובדים מחוברים כרגע';

  @override
  String get topWorkersThisMonth => 'מובילי החודש';

  @override
  String get workHoursThisMonth => 'שעות עבודה — החודש';

  @override
  String averageHoursPerWorker(String hours) {
    return 'ממוצע $hours שעות לעובד';
  }

  @override
  String get ownerDashboardTitle => 'לוח בקרה — בעלים';

  @override
  String helloName(String name) {
    return 'שלום, $name';
  }

  @override
  String get quickActionsLabel => 'פעולות מהירות';

  @override
  String get staffLabel => 'כוח אדם';

  @override
  String staffCountSummary(int count) {
    return 'סה\"כ $count אנשים בצוות • לחץ לניהול';
  }

  @override
  String get employeeManagementSystem => 'מערכת ניהול עובדים';

  @override
  String get myProfileTitle => 'הפרופיל שלי';

  @override
  String get gpsUnavailableTitle => 'לא ניתן לאמת מיקום';

  @override
  String get gpsUnavailableMessage =>
      'שירות המיקום אינו זמין או שהרשאות GPS לא אושרו. האם ברצונך להמשיך בכל זאת?';

  @override
  String get searchingLocationLabel => '...מחפש מיקום';

  @override
  String get networkErrorLoadMessage =>
      'לא ניתן לטעון את הנתונים.\nבדוק את החיבור ונסה שוב.';

  @override
  String get profileTooltip => 'פרופיל';

  @override
  String get notificationsTooltip => 'התראות';

  @override
  String get permissionsCoverageLabel => 'כיסוי הרשאות';

  @override
  String get noActivePermissions => 'אין הרשאות פעילות';

  @override
  String get updateProfilePictureTitle => 'עדכון תמונת פרופיל';

  @override
  String get chooseImageSourceTitle => 'בחר מקור לתמונה';

  @override
  String get setAsProfilePictureConfirm =>
      'להגדיר תמונה זו כתמונת הפרופיל שלך?';

  @override
  String get ctaOpenButton => 'פתח';

  @override
  String get clickForWeeklySchedule => 'לחץ לסידור שבועי';

  @override
  String get clickForManageWorkers => 'לחץ לניהול עובדים';

  @override
  String get daysWorkedLabel => 'ימים שעבדת';

  @override
  String get hoursWorkedLabel => 'שעות שעבדת';

  @override
  String clockInFromLabel(String clockIn, String duration) {
    return 'מ-$clockIn · $duration';
  }

  @override
  String get accountSectionHeader => 'חשבון';

  @override
  String get languageSectionHeader => 'שפה';

  @override
  String get languageSubtitle => 'בחר את שפת הממשק';

  @override
  String get notificationsSectionHeader => 'התראות';

  @override
  String get infoSectionHeader => 'מידע';

  @override
  String get signOutSectionHeader => 'יציאה';

  @override
  String get dangerZoneSectionHeader => 'אזור סכנה';

  @override
  String get requiresRecentLoginError => 'יש להתחבר מחדש לפני שינוי הסיסמה';

  @override
  String get updatePasswordError => 'שגיאה בעדכון הסיסמה';

  @override
  String get newPasswordLabel => 'סיסמה חדשה';

  @override
  String get passwordRequiredValidator => 'נא להזין סיסמה';

  @override
  String get updatePasswordButton => 'עדכן סיסמה';

  @override
  String get biometricEnableDescription =>
      'הזן את הסיסמה הנוכחית שלך כדי לאפשר כניסה עם טביעת אצבע / זיהוי פנים.';

  @override
  String get currentPasswordLabel => 'סיסמה נוכחית';

  @override
  String get biometricVerifyReason => 'אמת את זהותך כדי להפעיל כניסה ביומטרית';

  @override
  String get activateBiometricButton => 'הפעל כניסה ביומטרית';

  @override
  String get permanentDeletionMessage =>
      'פעולה זו בלתי הפיכה לחלוטין.\nכל הנתונים האישיים שלך יימחקו לצמיתות.';

  @override
  String get deleteAccountButton => 'מחק חשבון';

  @override
  String get wrongPasswordError => 'הסיסמה שגויה. אנא נסה שוב.';

  @override
  String get requiresRecentLoginDeleteError =>
      'נדרשת כניסה מחדש לפני מחיקת החשבון';

  @override
  String get deleteAccountError => 'שגיאה במחיקת החשבון. אנא נסה שוב.';

  @override
  String get deleteAccountWarning =>
      'פעולה זו תמחק את כל הנתונים האישיים שלך לצמיתות ולא ניתן לבטלה.\nאנא הזן את הסיסמה שלך לאישור.';

  @override
  String get deleteMyAccountButton => 'מחק את חשבוני לצמיתות';

  @override
  String get newBadgeLabel => 'חדש';

  @override
  String get newWorkersTabLabel => 'עובדים חדשים';

  @override
  String get activeWorkersTabLabel => 'עובדים פעילים';

  @override
  String get searchWorkerHint => 'חיפוש עובד לפי שם...';

  @override
  String get noSearchResultsEmpty => 'לא נמצאו תוצאות';

  @override
  String workersMissingClockOutBanner(int count, String workers) {
    return '$count $workers עם שעת יציאה חסרה החודש';
  }

  @override
  String get workerLabelSingular => 'עובד';

  @override
  String get workerLabelPlural => 'עובדים';

  @override
  String get missingClockOutWarning => 'חסר שעת יציאה — לחץ לתיקון';

  @override
  String get workerSubtitleInPark => 'עובד בפארק ג׳ננה';

  @override
  String get workerEmailInfoLabel => 'אימייל';

  @override
  String get workerPhoneInfoLabel => 'טלפון';

  @override
  String get workerDetailsCardTitle => '🧾 פרטי העובד';

  @override
  String get adminActionsCardTitle => '🧭 פעולות מנהל';

  @override
  String get manageLicensesCardTitle => '🛠 ניהול משא';

  @override
  String get noPermissionForUser => 'אין הרשאה לניהול משתמש זה';

  @override
  String get newWorkerPendingApproval => 'עובד חדש ממתין לאישור';

  @override
  String get approveEmailLabel => 'דוא\"ל';

  @override
  String get approveConfirmContent => 'האם אתה בטוח שברצונך לאשר את העובד הזה?';

  @override
  String get rejectConfirmContent =>
      'העובד ישאר בהמתנה ויוכל להגיש בקשה שוב. האם לדחות?';

  @override
  String get roleSectionTitle => 'תפקיד';

  @override
  String get managerRoleUpgradeNote => 'שדרוג לתפקיד מנהל מותר לבעלים בלבד';

  @override
  String get departmentsSectionHint => 'בחר את המחלקות בהן מורשה העובד לעבוד';

  @override
  String get roleChangedTitle => 'התפקיד שלך עודכן';

  @override
  String roleChangedBody(String fromRole, String toRole) {
    return 'תפקידך שונה מ$fromRole ל$toRole';
  }

  @override
  String get searchByNameOrRoleHint => 'חיפוש לפי שם או תפקיד';

  @override
  String get workerAddedToShift => 'עובד נוסף למשמרת בהצלחה';

  @override
  String get workerRemovedFromShift => 'עובד הוסר מהמשמרת';

  @override
  String get noWorkersFound => 'לא נמצאו עובדים';

  @override
  String addWorkersCount(int count) {
    return 'הוסף $count עובדים';
  }

  @override
  String get workerShiftsListSubtitle => 'רשימת המשמרות של העובד';

  @override
  String get filterAll => 'הכל';

  @override
  String get filterUpcoming => 'קרובות';

  @override
  String get filterPast => 'עבר';

  @override
  String get filterToday => 'היום';

  @override
  String get filterThisWeek => 'השבוע';

  @override
  String shiftNoteLabel(String note) {
    return 'הערה: $note';
  }

  @override
  String get ownerRoleShort => 'בעלים';

  @override
  String get coOwnerRoleShort => 'שותף';

  @override
  String get newsfeedTitle => 'לוח מודעות';

  @override
  String get newPostButton => 'פוסט חדש';

  @override
  String get searchPostHint => 'חיפוש פוסט...';

  @override
  String get categoryAll => 'הכל';

  @override
  String get categoryAnnouncements => 'הודעות';

  @override
  String get categoryUpdates => 'עדכונים';

  @override
  String get categoryEvents => 'אירועים';

  @override
  String get categoryGeneral => 'כללי';

  @override
  String get categoryLabelAnnouncement => 'הודעה';

  @override
  String get categoryLabelUpdate => 'עדכון';

  @override
  String get categoryLabelEvent => 'אירוע';

  @override
  String get categoryLabelGeneral => 'כללי';

  @override
  String get pinnedPostLabel => 'פוסט נעוץ';

  @override
  String get pinPostAction => 'נעץ פוסט';

  @override
  String get unpinPostAction => 'בטל נעיצה';

  @override
  String get deletePostMessage =>
      'האם אתה בטוח שברצונך למחוק את הפוסט?\nפעולה זו לא ניתנת לביטול.';

  @override
  String get deleteCommentMessage => 'האם אתה בטוח שברצונך למחוק את התגובה?';

  @override
  String get deleteLabel => 'מחק';

  @override
  String get postDeletedSuccess => 'הפוסט נמחק בהצלחה';

  @override
  String postDeleteError(String error) {
    return 'שגיאה במחיקת הפוסט: $error';
  }

  @override
  String get postPinnedSuccess => 'הפוסט ננעץ';

  @override
  String get postUnpinnedSuccess => 'הפוסט הוסר מהנעוצים';

  @override
  String errorPrefix(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get noPostsEmpty => 'אין פוסטים עדיין';

  @override
  String get noPostsManagerHint =>
      'לחץ על \"פוסט חדש\" כדי לפרסם את הפוסט הראשון';

  @override
  String get noPostsWorkerHint => 'המנהלים יפרסמו כאן עדכונים בקרוב';

  @override
  String get noPostsSearchEmpty => 'לא נמצאו פוסטים התואמים לחיפוש';

  @override
  String get noPostsCategoryEmpty => 'אין פוסטים בקטגוריה זו';

  @override
  String get feedLoadError => 'שגיאה בטעינת הפוסטים';

  @override
  String get checkConnectionHint => 'בדוק את החיבור לאינטרנט ונסה שוב';

  @override
  String get defaultUserName => 'משתמש';

  @override
  String get createPostTitle => 'פוסט חדש';

  @override
  String get createPostSubtitle => 'שתף עדכונים עם הצוות';

  @override
  String get selectCategoryLabel => 'בחר קטגוריה';

  @override
  String get postTitleLabel => 'כותרת';

  @override
  String get postTitleRequired => 'יש להזין כותרת';

  @override
  String get postContentLabel => 'תוכן הפוסט';

  @override
  String get postContentRequired => 'יש להזין תוכן';

  @override
  String mediaLabel(int count, int max) {
    return 'מדיה ($count/$max)';
  }

  @override
  String get addMediaButton => 'הוסף תמונות או סרטונים';

  @override
  String get addMoreMediaButton => 'הוסף עוד';

  @override
  String get mediaPickerTitle => 'הוסף מדיה';

  @override
  String get pickImagesOption => 'בחר תמונות';

  @override
  String get pickImagesSubtitle => 'בחר תמונות מהגלריה';

  @override
  String get pickVideoOption => 'בחר סרטון';

  @override
  String get pickVideoSubtitle => 'בחר סרטון מהגלריה';

  @override
  String get takePhotoOption => 'צלם תמונה';

  @override
  String get takePhotoSubtitle => 'פתח את המצלמה';

  @override
  String maxMediaError(int max) {
    return 'ניתן להעלות עד $max קבצים';
  }

  @override
  String get videoLabel => 'וידאו';

  @override
  String get publishPostButton => 'פרסם פוסט';

  @override
  String get publishingPostStatus => 'מפרסם פוסט...';

  @override
  String get preparingUploadStatus => 'מכין להעלאה...';

  @override
  String get postPublishedSuccess => 'הפוסט פורסם בהצלחה';

  @override
  String postPublishError(String error) {
    return 'שגיאה בפרסום הפוסט: $error';
  }

  @override
  String get movWarningMessage =>
      'סרטוני .MOV מאייפון עשויים להיות בפורמט Dolby Vision שלא נתמך בחלק מהמכשירים. מומלץ להשתמש ב-MP4.';

  @override
  String get postDetailTitle => 'פרטי הפוסט';

  @override
  String get tapToWatchVideo => 'הקש לצפייה בסרטון';

  @override
  String get commentsTitle => 'תגובות';

  @override
  String get beFirstToComment => 'היה הראשון להגיב!';

  @override
  String get beFirstToCommentOnPost => 'היה הראשון להגיב על הפוסט!';

  @override
  String get addCommentHint => 'הוסף תגובה...';

  @override
  String get writeCommentHint => 'כתוב תגובה...';

  @override
  String get commentAddedSuccess => 'התגובה נוספה';

  @override
  String get commentAddError => 'שגיאה בהוספת תגובה';

  @override
  String get commentDeletedSuccess => 'התגובה נמחקה';

  @override
  String get commentDeleteError => 'שגיאה במחיקת תגובה';

  @override
  String get commentUpdatedSuccess => 'התגובה עודכנה';

  @override
  String get commentUpdateError => 'שגיאה בעדכון תגובה';

  @override
  String get editPostTitle => 'עריכת פוסט';

  @override
  String get postUpdatedSuccess => 'הפוסט עודכן';

  @override
  String get postUpdateError => 'שגיאה בעדכון הפוסט';

  @override
  String get likersTitle => 'תגובות לפוסט';

  @override
  String likersCount(int count) {
    return '$count אנשים';
  }

  @override
  String get noLikersEmpty => 'עדיין אין לייקים';

  @override
  String get beFirstToLike => 'היה הראשון לאהוב את הפוסט!';

  @override
  String get likersLoadError => 'שגיאה בטעינת הנתונים';

  @override
  String get roleManager => 'מנהל';

  @override
  String get roleWorker => 'עובד';

  @override
  String get roleAdmin => 'מנהל מערכת';

  @override
  String get videoFormatNotSupported => 'פורמט סרטון לא נתמך';

  @override
  String get videoLoadError => 'שגיאה בטעינת הסרטון';

  @override
  String get videoFormatErrorDetail =>
      'הסרטון מקודד בפורמט Dolby Vision / HEVC שלא נתמך\nבמכשיר זה. נסה להעלות סרטון ב-H.264 (MP4 רגיל).';

  @override
  String get videoPlaybackErrorDetail =>
      'אירעה שגיאה בהפעלת הסרטון.\nבדוק את החיבור ונסה שוב.';

  @override
  String get videoLoadingLabel => 'טוען סרטון...';

  @override
  String get noPostsMatchSearch => 'לא נמצאו פוסטים התואמים לחיפוש';

  @override
  String get noPostsInCategory => 'אין פוסטים בקטגוריה זו';

  @override
  String get noPostsYet => 'אין פוסטים עדיין';

  @override
  String get loadPostsError => 'שגיאה בטעינת הפוסטים';

  @override
  String deletePostError(String error) {
    return 'שגיאה במחיקת הפוסט: $error';
  }

  @override
  String genericError(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get taskStatusPending => 'ממתין';

  @override
  String get taskStatusInProgress => 'בביצוע';

  @override
  String get taskStatusDone => 'הושלם';

  @override
  String get taskStatusPendingReview => 'ממתין לאישור';

  @override
  String get taskPriorityHigh => 'גבוהה';

  @override
  String get taskPriorityMedium => 'בינונית';

  @override
  String get taskPriorityLow => 'נמוכה';

  @override
  String get noTasksEmpty => 'אין משימות';

  @override
  String get noTasksForDay => 'אין משימות ליום זה';

  @override
  String get noTasksNow => 'אין משימות כרגע';

  @override
  String get newTasksWillAppear => 'משימות חדשות יופיעו כאן';

  @override
  String get useCreateTaskButton =>
      'השתמש בכפתור \'יצירת משימה\' כדי להוסיף אחת חדשה';

  @override
  String get taskManagementTitle => 'ניהול משימות';

  @override
  String get allTasksTitle => 'כל המשימות';

  @override
  String get allTasksSubtitle => 'תצוגה כוללת לכל המשימות';

  @override
  String get myTasksTitle => 'המשימות שלי';

  @override
  String get myTasksTabLabel => 'המשימות שלי';

  @override
  String get createdByMeTabLabel => 'משימות שיצרתי';

  @override
  String get taskDetailsTitle => 'פרטי המשימה';

  @override
  String get taskDescriptionLabel => 'תיאור';

  @override
  String get taskDescriptionSectionTitle => 'תיאור המשימה';

  @override
  String get noTaskDescription => 'אין תיאור למשימה זו';

  @override
  String get taskInfoSectionTitle => 'פרטים';

  @override
  String get taskDeadlineLabel => 'תאריך יעד';

  @override
  String get taskPriorityLabel => 'עדיפות';

  @override
  String get taskDepartmentLabel => 'מחלקה';

  @override
  String get taskCreatedAtLabel => 'נוצרה';

  @override
  String get taskAssigneesLabel => 'עובדים';

  @override
  String taskAssigneesCount(int count) {
    return 'עובדים ($count)';
  }

  @override
  String get taskOverviewTabLabel => 'סקירה';

  @override
  String get taskDiscussionTabLabel => 'דיון';

  @override
  String get editTaskMenuItem => 'ערוך משימה';

  @override
  String get deleteTaskMenuItem => 'מחק משימה';

  @override
  String get createTaskButton => 'יצירת משימה';

  @override
  String get deleteTaskTitle => 'מחיקת משימה';

  @override
  String deleteTaskConfirmation(String title) {
    return 'למחוק את \"$title\"?';
  }

  @override
  String get deleteTaskButton => 'מחק';

  @override
  String taskDeletedSnackbar(String title) {
    return 'המשימה \"$title\" נמחקה';
  }

  @override
  String get confirmDeleteTitle => 'אישור מחיקה';

  @override
  String confirmDeleteTaskMessage(String title) {
    return 'האם אתה בטוח שברצונך למחוק את המשימה \'$title\'?';
  }

  @override
  String get taskOverdueSection => 'באיחור';

  @override
  String get taskTodaySection => 'להיום';

  @override
  String get taskUpcomingSection => 'הקרובות';

  @override
  String get taskCompletedSection => 'הושלמו';

  @override
  String taskDeadlineOverdue(int days, String unit) {
    return 'באיחור $days $unit';
  }

  @override
  String taskDeadlineToday(String time) {
    return 'היום, $time';
  }

  @override
  String taskDeadlineTomorrow(String time) {
    return 'מחר, $time';
  }

  @override
  String taskDeadlineInDays(int days) {
    return 'בעוד $days ימים';
  }

  @override
  String get dayUnit => 'יום';

  @override
  String get daysUnit => 'ימים';

  @override
  String todayTasksProgress(int completed, int total) {
    return '$completed מתוך $total הושלמו היום';
  }

  @override
  String get noTasksToday => 'אין משימות להיום';

  @override
  String taskCountOverdue(int count, int overdue) {
    return '$count משימות • $overdue באיחור';
  }

  @override
  String get pendingManagerApproval => 'ממתין לאישור מנהל';

  @override
  String get pendingApprovalLabel => 'ממתינים לאישור:';

  @override
  String get startTaskButton => 'התחל לעבוד';

  @override
  String get startTaskAction => 'התחל משימה';

  @override
  String get finishTaskButton => 'סיים משימה';

  @override
  String get submitForApprovalButton => 'שלח לאישור מנהל';

  @override
  String get approveButton => 'אשר';

  @override
  String get rejectButton => 'דחה';

  @override
  String get taskApprovedSnackbar => 'המשימה אושרה בהצלחה';

  @override
  String get taskRejectedSnackbar => 'המשימה הוחזרה לביצוע';

  @override
  String get startWorkButton => 'להתחיל לעבוד';

  @override
  String get sendCommentButton => 'שלח תגובה';

  @override
  String get addCommentHintTask => 'הוסף תגובה...';

  @override
  String get writeCommentHintTask => 'כתוב תגובה...';

  @override
  String get commentSendError => 'שגיאה בשליחת תגובה';

  @override
  String get attachedFilesTitle => 'קבצים מצורפים';

  @override
  String get attachedFileDefault => 'קובץ מצורף';

  @override
  String get cannotOpenFile => 'לא ניתן לפתוח את הקובץ';

  @override
  String get filterStatusPending => 'ממתין';

  @override
  String get filterStatusInProgress => 'בביצוע';

  @override
  String get filterStatusDone => 'הושלם';

  @override
  String get searchTaskHint => 'חיפוש משימה...';

  @override
  String get searchTaskByNameHint => 'חיפוש משימה לפי שם...';

  @override
  String taskErrorPrefix(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get taskTitleLabel => 'כותרת';

  @override
  String get taskTitleHint => 'שם המשימה';

  @override
  String get taskDescriptionFieldLabel => 'תיאור';

  @override
  String get taskDescriptionHint => 'תיאור מפורט';

  @override
  String get taskDescriptionOptionalHint => 'תיאור מפורט (אופציונלי)';

  @override
  String get taskFieldRequired => 'שדה חובה';

  @override
  String get taskFillAllFields => 'יש למלא את כל השדות ולבחור עובדים';

  @override
  String get taskDateLabel => 'תאריך';

  @override
  String get taskTimeLabel => 'שעה';

  @override
  String get taskSelectDate => 'בחר תאריך';

  @override
  String get taskSelectTime => 'בחר שעה';

  @override
  String get taskDeadlineSectionTitle => 'מועד יעד';

  @override
  String get taskDeadlineHint => 'הגדר תאריך ושעת סיום למשימה';

  @override
  String get taskWorkersSectionTitle => 'עובדים משובצים';

  @override
  String get taskAssignWorkersTitle => 'שיבוץ עובדים';

  @override
  String taskSelectedWorkersCount(int count) {
    return 'בחר $count עובדים';
  }

  @override
  String get taskSearchWorkerHint => 'חיפוש עובד...';

  @override
  String get taskSearchWorkerByNameHint => 'חיפוש לפי שם או תפקיד...';

  @override
  String get taskSummaryTitle => 'סיכום ויצירה';

  @override
  String get taskSummarySubtitle => 'בדוק את הפרטים לפני יצירת המשימה';

  @override
  String get taskBasicInfoTitle => 'פרטי המשימה';

  @override
  String get taskBasicInfoSubtitle => 'מלא את הפרטים הבסיסיים של המשימה';

  @override
  String get taskStepDetails => 'פרטים';

  @override
  String get taskStepWorkers => 'עובדים';

  @override
  String get taskStepDeadline => 'מועד';

  @override
  String get taskStepSummary => 'סיכום';

  @override
  String get taskReviewWorkersLabel => 'עובדים';

  @override
  String get taskReviewDeadlineLabel => 'מועד יעד';

  @override
  String get createTaskActionButton => 'צור משימה';

  @override
  String get nextButton => 'המשך';

  @override
  String get backStepButton => 'חזור';

  @override
  String get saveChangesTaskButton => 'שמור שינויים';

  @override
  String get taskCreateError => 'שגיאה ביצירת המשימה';

  @override
  String get taskUpdateError => 'שגיאה בעדכון המשימה';

  @override
  String get taskLogEdited => 'המשימה עודכנה';

  @override
  String get userFallbackName => 'משתמש';

  @override
  String get showLessButton => 'הצג פחות';

  @override
  String get showAllButton => 'הצג הכל';

  @override
  String get tasksTitleValidation => 'נא להזין כותרת למשימה';

  @override
  String get tasksWorkersValidation => 'נא לבחור לפחות עובד אחד';

  @override
  String get tasksDeadlineValidation => 'נא לבחור תאריך ושעה';

  @override
  String get userIdentificationError => 'שגיאה בזיהוי המשתמש.';

  @override
  String get taskReturnedSnackbar => 'המשימה הוחזרה לביצוע';

  @override
  String tasksOverdueCount(int total, int overdue) {
    return '$total משימות • $overdue באיחור';
  }

  @override
  String get noShiftsAvailableEmpty => 'אין משמרות זמינות כרגע';

  @override
  String get shiftsComingSoonSubtitle => 'בקרוב יתווספו משמרות חדשות';

  @override
  String get noShiftsForDay => 'אין משמרות ליום זה';

  @override
  String get selectOtherDayHint => 'בחר יום אחר או המתן למשמרות חדשות';

  @override
  String get tryReconnectHint => 'נסה להתחבר מחדש';

  @override
  String get shiftStatusActive => 'פעיל';

  @override
  String get shiftStatusCancelled => 'בוטלה';

  @override
  String pendingRequestsCount(int count) {
    return '$count בקשות';
  }

  @override
  String get newShiftFab => 'משמרת חדשה';

  @override
  String get managerShiftDashboardTitle => 'ניהול משמרות';

  @override
  String get shiftRequestCancelledSnackbar => 'הבקשה למשמרת בוטלה';

  @override
  String get shiftConflictTitle => 'התנגשות משמרות';

  @override
  String shiftConflictMessage(String startTime, String endTime) {
    return 'כבר משובץ למשמרת בתאריך זה בשעות החופפות ($startTime–$endTime). האם להמשיך בכל זאת?';
  }

  @override
  String get proceedAnywayButton => 'המשך בכל זאת';

  @override
  String get cancelShiftRequestLabel => 'בטל בקשה למשמרת';

  @override
  String get joinShiftLabel => 'הצטרף למשמרת';

  @override
  String get joinButton => 'הצטרף';

  @override
  String get shiftWorkedLabel => 'עבדת';

  @override
  String get shiftEndedLabel => 'הסתיים';

  @override
  String get shiftAssignedLabel => 'משובץ';

  @override
  String get shiftFullLabel => 'מלא';

  @override
  String get shiftCancelledChip => 'המשמרת בוטלה';

  @override
  String get shiftOutdatedChip => 'עבר התאריך';

  @override
  String get youAreAssignedChip => 'אתה משובץ';

  @override
  String get waitingApprovalChip => 'ממתין לאישור';

  @override
  String get shiftFullChip => 'המשמרת מלאה';

  @override
  String get openForRegistrationChip => 'פתוח להרשמה';

  @override
  String get assignedWorkersSection => 'עובדים משובצים';

  @override
  String get noAssignedWorkersYet => 'אין עובדים משובצים עדיין';

  @override
  String get messagesSection => 'הודעות';

  @override
  String get loadingMessages => 'טוען הודעות...';

  @override
  String get noMessagesYet => 'אין הודעות עדיין';

  @override
  String get createNewShiftTitle => 'יצירת משמרת חדשה';

  @override
  String get createShiftSubtitle => 'מלא את הפרטים ליצירת משמרת';

  @override
  String get dateLabel => 'בתאריך';

  @override
  String get departmentLabel => 'מחלקה';

  @override
  String get startTimeLabel => 'התחלה';

  @override
  String get endTimeLabel => 'סיום';

  @override
  String get maxWorkersLabel => 'מספר עובדים מקסימלי';

  @override
  String get weeklyRecurrenceLabel => 'חזרה שבועית';

  @override
  String get shiftRepeatsWeekly => 'משמרת חוזרת כל שבוע';

  @override
  String get createRecurringShift => 'צור משמרת חוזרת';

  @override
  String get numberOfWeeksLabel => 'מספר שבועות:';

  @override
  String get shiftsToBeCreatedLabel => 'משמרות שייווצרו:';

  @override
  String get createShiftButton => 'צור משמרת';

  @override
  String shiftsCreatedSuccess(int count) {
    return '$count משמרות נוצרו בהצלחה!';
  }

  @override
  String get shiftCreatedSuccess => 'משמרת נוצרה בהצלחה!';

  @override
  String createShiftError(String error) {
    return 'שגיאה ביצירת משמרת: $error';
  }

  @override
  String get clearButton => 'נקה';

  @override
  String get editShiftTitle => 'עריכת משמרת';

  @override
  String get unsavedChangesHeaderSubtitle => 'יש שינויים לא שמורים';

  @override
  String get updateShiftDetailsSubtitle => 'עדכן את פרטי המשמרת';

  @override
  String get saveChangesDialogTitle => 'שמירת שינויים';

  @override
  String get followingChangesSavedLabel => 'השינויים הבאים יישמרו:';

  @override
  String get workersNotifiedOfChanges =>
      'כל העובדים המשובצים והממתינים יקבלו התראה על השינויים';

  @override
  String get shiftUpdatedSuccess => 'המשמרת עודכנה בהצלחה!';

  @override
  String updateShiftError(String error) {
    return 'שגיאה בעדכון המשמרת: $error';
  }

  @override
  String get continueEditingButton => 'המשך לערוך';

  @override
  String get departmentChangedLabel => 'מחלקה (שונה)';

  @override
  String get hoursChangedLabel => 'שעות (שונה)';

  @override
  String get maxWorkersChangedLabel => 'מספר עובדים מקסימלי (שונה)';

  @override
  String get changedBadge => 'שונה';

  @override
  String tooManyWorkersWarning(int count) {
    return 'יש כרגע $count עובדים משובצים, יותר מהמקסימום החדש';
  }

  @override
  String get statusLabel => 'סטטוס';

  @override
  String get statusChangedLabel => 'סטטוס (שונה)';

  @override
  String get shiftStatusCancelledMasc => 'בוטל';

  @override
  String get shiftStatusCompleted => 'הושלם';

  @override
  String get noChangesLabel => 'אין שינויים';

  @override
  String weekRangeLabel(String start, String end) {
    return 'שבוע $start - $end';
  }

  @override
  String get myShiftsTitle => 'המשמרות שלי';

  @override
  String get nextWeekTooltip => 'שבוע הבא';

  @override
  String get prevWeekTooltip => 'שבוע קודם';

  @override
  String get loadShiftsError => 'שגיאה בטעינת המשמרות';

  @override
  String get todayLabel => 'היום';

  @override
  String get pastLabel => 'עבר';

  @override
  String get noShiftsDay => 'אין משמרות';

  @override
  String get loadingShifts => 'טוען משמרות...';

  @override
  String get loginToViewShifts => 'יש להתחבר כדי לצפות במשמרות';

  @override
  String get viewShiftDetailsButton => 'צפה בפרטי המשמרת';

  @override
  String get allShiftsTabLabel => 'כל המשמרות';

  @override
  String get weeklyScheduleTitle => 'סידור עבודה שבועי';

  @override
  String get noWorkersAssigned => 'לא שובצו עובדים';

  @override
  String get noWorkersAssignedForShift => 'לא שובצו עובדים למשמרת זו';

  @override
  String get managerRoleShort => 'מנהל';

  @override
  String get workerRoleShort => 'עובד';

  @override
  String get noShiftsThisWeek => 'אין משמרות השבוע';

  @override
  String get notAssignedThisWeek => 'לא שובצת למשמרות בשבוע זה';

  @override
  String get changesSavedSuccess => 'השינויים נשמרו בהצלחה!';

  @override
  String saveChangesError(String error) {
    return 'שגיאה בשמירת השינויים: $error';
  }

  @override
  String unsavedChangesCountMessage(int count) {
    return 'יש לך $count שינויים שלא נשמרו. האם אתה בטוח שברצונך לצאת?';
  }

  @override
  String get cancelAllButton => 'בטל הכל';

  @override
  String saveChangesWithCount(int count) {
    return 'שמור שינויים ($count)';
  }

  @override
  String get workersLabel => 'עובדים';

  @override
  String get requestsTabLabel => 'בקשות';

  @override
  String get approvedTabLabel => 'מאושרים';

  @override
  String get messagesTabLabel => 'הודעות';

  @override
  String get detailsTabLabel => 'פרטים';

  @override
  String get noPendingRequests => 'אין בקשות ממתינות';

  @override
  String get newRequestsWillAppear => 'בקשות חדשות יופיעו כאן';

  @override
  String get willBeApprovedLabel => 'יאושר';

  @override
  String get willBeRejectedLabel => 'יידחה';

  @override
  String get addWorkersButton => 'הוסף עובדים';

  @override
  String get noAssignedWorkersEmpty => 'אין עובדים משובצים';

  @override
  String get clickAddWorkersHint => 'לחץ על \"הוסף עובדים\" להוספה ידנית';

  @override
  String get willBeAddedLabel => 'יתווסף';

  @override
  String get willBeRemovedLabel => 'יוסר';

  @override
  String get willBeRestoredLabel => 'יוחזר';

  @override
  String get sendFirstMessage => 'שלח הודעה ראשונה';

  @override
  String get writeMessageHint => 'כתוב הודעה...';

  @override
  String get createdByLabel => 'נוצר על ידי';

  @override
  String get creationDateLabel => 'תאריך יצירה';

  @override
  String get lastUpdatedByLabel => 'עודכן לאחרונה על ידי';

  @override
  String get shiftManagerLabel => 'אחראי משמרת';

  @override
  String pendingChangesBanner(int count) {
    return '$count שינויים ממתינים לשמירה';
  }

  @override
  String workersWillBeApproved(int count) {
    return '$count עובדים יאושרו';
  }

  @override
  String requestsWillBeRejected(int count) {
    return '$count בקשות יידחו';
  }

  @override
  String workersWillBeRemoved(int count) {
    return '$count עובדים יוסרו';
  }

  @override
  String workersWillBeRestored(int count) {
    return '$count עובדים יוחזרו לרשימת הממתינים';
  }

  @override
  String workersWillBeAdded(int count) {
    return '$count עובדים יתווספו';
  }

  @override
  String commentsCountLabel(int count) {
    return '$count תגובות';
  }

  @override
  String get editCommentTitle => 'עריכת תגובה';

  @override
  String get editCommentHint => 'ערוך את תגובתך...';

  @override
  String get postTypeAnnouncementDesc => 'הודעות חשובות לכלל העובדים';

  @override
  String get postTypeUpdateDesc => 'עדכונים ושינויים';

  @override
  String get postTypeEventDesc => 'אירועים ופעילויות';

  @override
  String get postTypeGeneralDesc => 'מידע כללי';

  @override
  String get dateRangeButton => 'טווח תאריכים';

  @override
  String get selectDateRange => 'בחר טווח תאריכים';

  @override
  String get noAttendanceDataMonth => 'אין נתוני נוכחות לחודש זה';

  @override
  String chartTooltipDayHours(int day, String hours) {
    return 'יום $day\n$hours שעות';
  }

  @override
  String get missingClockOutLabel => 'יציאה חסרה';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hoursש׳ $minutesד׳';
  }

  @override
  String clockInPrefix(String time) {
    return 'כניסה: $time';
  }

  @override
  String clockOutPrefix(String time) {
    return 'יציאה: $time';
  }

  @override
  String get exportingLabel => 'מייצא...';

  @override
  String get exportPdfButton => 'ייצוא PDF';

  @override
  String get allWorkersValidClockout =>
      'כל העובדים שמרו על יציאה תקינה בחודש זה';

  @override
  String get noShiftsMonth => 'אין משמרות לחודש זה';

  @override
  String shiftCountAndSlotsFormat(int count, int filled, int total) {
    return '$count משמרות · $filled/$total מקומות מלאים';
  }

  @override
  String shiftCountTooltip(int count) {
    return '$count משמרות';
  }

  @override
  String get taskDistributionTitle => 'התפלגות משימות';

  @override
  String get noTasksMonth => 'אין משימות לחודש זה';

  @override
  String get totalTasksLabel => 'סה\"כ משימות';

  @override
  String get workersWithTasksLabel => 'עובדים עם משימות';

  @override
  String get completionRateLabel => 'שיעור השלמה';

  @override
  String get completionRateByWorkerTitle => 'שיעור השלמה לפי עובד';

  @override
  String get topTenLabel => '(10 מובילים)';

  @override
  String get workerDetailsTitle => 'פירוט עובדים';

  @override
  String get executionLabel => 'ביצוע';

  @override
  String get statusDistributionTitle => 'התפלגות סטטוס';

  @override
  String get taskDetailsListTitle => 'פירוט משימות';

  @override
  String taskGoalPrefix(String date) {
    return 'יעד: $date';
  }

  @override
  String get taskTimelineSubmitted => 'הוגשה';

  @override
  String get taskTimelineStarted => 'התחילה';

  @override
  String get taskTimelineEnded => 'הסתיימה';

  @override
  String get workersHoursTitle => 'שעות עבודה';

  @override
  String get activeWorkersLabel => 'עובדים פעילים';

  @override
  String get totalHoursLabel => 'סה״כ שעות';

  @override
  String get avgPerWorkerLabel => 'ממוצע לעובד';

  @override
  String get hoursByWorkerTitle => 'שעות לפי עובד';

  @override
  String workerDaysAndAvgFormat(int days, String avg) {
    return '$days ימים · ממוצע $avg ש׳/יום';
  }

  @override
  String get generalReportsTabLabel => 'דוחות כלליים';

  @override
  String get personalReportsSubtitle =>
      'צפייה בנתוני נוכחות, משימות ומשמרות אישיים';

  @override
  String get attendanceReportDescription =>
      'שעות עבודה, ימי נוכחות וסיכום חודשי';

  @override
  String get taskReportDescription => 'סטטוס משימות, התקדמות ואחוזי ביצוע';

  @override
  String get shiftReportDescription => 'היסטוריית משמרות, אישורים והחלטות';

  @override
  String get generalReportsTitle => 'דוחות כלליים';

  @override
  String get generalReportsSubtitle => 'נתונים מצטברים על כלל העובדים';

  @override
  String get workersHoursDescription => 'סיכום שעות עבודה חודשי לפי עובד';

  @override
  String get taskDistributionDescription =>
      'משימות לפי עובד, אחוזי ביצוע ודירוג';

  @override
  String get shiftCoverageDescription => 'משמרות לפי מחלקה, אחוז מילוי ופירוט';

  @override
  String get missingClockoutsDescription => 'עובדים שלא שכחו לצאת לפי חודש';

  @override
  String reportsOfWorker(String name) {
    return 'הדוחות של $name';
  }

  @override
  String get workerReportsSubtitle => 'צפייה בנתוני נוכחות, משימות ומשמרות';

  @override
  String get performanceSummaryTitle => 'סיכום ביצועים — החודש';

  @override
  String hoursWithValue(String hours) {
    return '$hours שעות';
  }

  @override
  String daysWithValue(int days) {
    return '$days ימים';
  }

  @override
  String get presenceLabel => 'נוכחות';

  @override
  String get atWorkLabel => 'בעבודה';

  @override
  String get tasksCompletedLabel => 'משימות הושלמו';

  @override
  String shiftDecisionApproved(int count) {
    return 'מאושר ($count)';
  }

  @override
  String shiftDecisionRejected(int count) {
    return 'נדחה ($count)';
  }

  @override
  String shiftDecisionOther(int count) {
    return 'אחר ($count)';
  }

  @override
  String get showDetailsLabel => 'הצג פרטים';

  @override
  String get hideDetailsLabel => 'הסתר פרטים';

  @override
  String get approvedByLabel => 'אושר ע״י';

  @override
  String get roleAtAssignmentLabel => 'תפקיד בעת השיבוץ';

  @override
  String get requestTimeLabel => 'זמן בקשה';

  @override
  String get removedByLabel => 'הוסר ע״י';

  @override
  String get removalTimeLabel => 'זמן הסרה';

  @override
  String get cancelledByLabel => 'בוטל ע״י';

  @override
  String get cancellationTimeLabel => 'זמן ביטול';

  @override
  String get shiftStatusActiveFem => 'פעילה';

  @override
  String get shiftStatusCancelledFem => 'מבוטלת';

  @override
  String get shiftStatusPendingFem => 'ממתינה';

  @override
  String get decisionAcceptedLabel => 'מאושר';

  @override
  String get decisionRejectedLabel => 'נדחה';

  @override
  String get decisionRemovedLabel => 'הוסר';

  @override
  String get decisionPendingLabel => 'ממתין';

  @override
  String get shiftManagerRoleLabel => 'מנהל משמרת';

  @override
  String get deptManagerRoleLabel => 'מנהל מחלקה';

  @override
  String hoursAbbrFormat(String hours) {
    return '$hours ש׳';
  }

  @override
  String get pickPhotoOption => 'בחר תמונות';

  @override
  String get pickPhotoSubtitle => 'בחר תמונות מהגלריה';

  @override
  String get adminRoleLabel => 'מנהל מערכת';

  @override
  String reactorsPeopleCount(int count) {
    return '$count אנשים';
  }

  @override
  String get deptGeneral => 'כללי';

  @override
  String get deptPaintball => 'פיינטבול';

  @override
  String get deptRopes => 'פארק חבלים';

  @override
  String get deptCarting => 'קרטינג';

  @override
  String get deptWaterPark => 'פארק מים';

  @override
  String get deptJimbory => 'ג\'ימבורי';

  @override
  String get deptOperations => 'תפעול';

  @override
  String get preparingUploadShort => 'מכין...';

  @override
  String get clockReminder10hTitle => 'שכחת לצאת? ⏰';

  @override
  String get clockReminder10hBody =>
      'אתה במשמרת כבר 10 שעות. זכור לדווח יציאה.';

  @override
  String get clockReminder12hTitle => 'משמרת ארוכה מאוד! 🚨';

  @override
  String get clockReminder12hBody =>
      'אתה במשמרת כבר 12 שעות. דווח יציאה בהקדם.';

  @override
  String get taskDeadlineReminderTitle => 'תזכורת משימה ⏰';

  @override
  String taskDeadlineReminderBody(String title) {
    return '$title — נותרו פחות מ-24 שעות לסיום';
  }

  @override
  String pendingApprovalCount(int count) {
    return '$count עובדים ממתינים לאישור';
  }

  @override
  String understaffedShiftsCount(int count) {
    return '$count משמרות היום חסרות עובדים';
  }

  @override
  String get hoursAbbreviation => 'ש׳';

  @override
  String get minutesAbbreviation => 'דק׳';

  @override
  String daysThisMonth(int count) {
    return '$count ימים החודש';
  }

  @override
  String totalHoursCount(String count) {
    return '$count שעות';
  }

  @override
  String activeDepartmentsPercent(int percent) {
    return '$percent% מהמחלקות פעילות';
  }

  @override
  String get autoClockoutTitle => 'יציאה אוטומטית ממשמרת';

  @override
  String get autoClockoutBody =>
      'לא דיווחת יציאה לאחר 16 שעות – המערכת סיימה את המשמרת אוטומטית. פנה למנהל שלך.';

  @override
  String get postCategoryAnnouncement => 'הודעה';

  @override
  String get postCategoryUpdate => 'עדכון';

  @override
  String get postCategoryEvent => 'אירוע';

  @override
  String get postCategoryGeneral => 'כללי';

  @override
  String get locationRationaleTitle => 'גישה למיקום';

  @override
  String get locationRationaleMessage =>
      'האפליקציה זקוקה לגישה למיקומך כדי לאפשר כניסה ויציאה מהעבודה בתחום הפארק.\n\nהמיקום משמש אך ורק לאימות נוכחות ואינו נשמר או משותף.';

  @override
  String get locationRationaleConfirm => 'אשר גישה';

  @override
  String get locationRationaleCancel => 'לא עכשיו';

  @override
  String get biometricLoginReason => 'אמת את זהותך כדי להיכנס לאפליקציה';

  @override
  String get shiftApprovedTitle => 'בקשתך למשמרת אושרה';

  @override
  String shiftApprovedBody(String date, String startTime, String endTime) {
    return 'אושרת למשמרת $date, $startTime–$endTime';
  }

  @override
  String get shiftRejectedTitle => 'בקשתך למשמרת נדחתה';

  @override
  String shiftRejectedBody(String date, String startTime, String endTime) {
    return 'בקשתך למשמרת $date, $startTime–$endTime לא אושרה';
  }

  @override
  String uploadingVideoProgress(int current, int total) {
    return 'מעלה סרטון $current מתוך $total...';
  }

  @override
  String uploadingImageProgress(int current, int total) {
    return 'מעלה תמונה $current מתוך $total...';
  }

  @override
  String uploadingProgress(int current, int total) {
    return 'מעלה $current מתוך $total...';
  }

  @override
  String get generatingThumbnailStatus => 'מייצר תמונה מקדימה...';

  @override
  String fileUploadedStatus(int current) {
    return 'קובץ $current הועלה';
  }

  @override
  String get agreeToPrivacyPrefix => 'קראתי ואני מסכים/ה ל';

  @override
  String get andConnector => ' ול';

  @override
  String get privacyPolicyRequiredError => 'יש לאשר את מדיניות הפרטיות להמשך';
}
