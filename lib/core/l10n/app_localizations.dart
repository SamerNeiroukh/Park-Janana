import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('en'),
    Locale('he'),
  ];

  /// The name of the application
  ///
  /// In he, this message translates to:
  /// **'פארק ג׳ננה'**
  String get appTitle;

  /// Login button label
  ///
  /// In he, this message translates to:
  /// **'כניסה'**
  String get loginButton;

  /// Registration prompt for new workers
  ///
  /// In he, this message translates to:
  /// **'עובד חדש?'**
  String get newWorkerButton;

  /// Logout label
  ///
  /// In he, this message translates to:
  /// **'התנתק'**
  String get logoutLabel;

  /// Logout dialog/screen title
  ///
  /// In he, this message translates to:
  /// **'התנתקות'**
  String get logoutTitle;

  /// Logout confirmation dialog message
  ///
  /// In he, this message translates to:
  /// **'האם אתה בטוח שברצונך להתנתק?'**
  String get logoutConfirmation;

  /// Generic error message
  ///
  /// In he, this message translates to:
  /// **'אירעה שגיאה, נסה שוב'**
  String get errorGeneral;

  /// Retry button label
  ///
  /// In he, this message translates to:
  /// **'נסה שוב'**
  String get retryButton;

  /// Personal area screen title
  ///
  /// In he, this message translates to:
  /// **'האזור האישי שלך'**
  String get profileScreenTitle;

  /// Forgot password label
  ///
  /// In he, this message translates to:
  /// **'שכחתי סיסמה'**
  String get forgotPassword;

  /// Available shifts screen title
  ///
  /// In he, this message translates to:
  /// **'משמרות זמינות'**
  String get shiftsTitle;

  /// Manager shift dashboard title
  ///
  /// In he, this message translates to:
  /// **'לוח ניהול משמרות'**
  String get managerDashboardTitle;

  /// Create new shift button label
  ///
  /// In he, this message translates to:
  /// **'צור משמרת חדשה'**
  String get newShiftButton;

  /// Profile picture update success message
  ///
  /// In he, this message translates to:
  /// **'התמונה עודכנה בהצלחה'**
  String get profileUpdateSuccess;

  /// Shift request sent success message
  ///
  /// In he, this message translates to:
  /// **'בקשתך נשלחה למשמרת'**
  String get shiftRequestSuccess;

  /// Shift request cancelled message
  ///
  /// In he, this message translates to:
  /// **'הבקשה למשמרת בוטלה'**
  String get shiftCancelSuccess;

  /// Confirm button label
  ///
  /// In he, this message translates to:
  /// **'אישור'**
  String get confirmButton;

  /// Cancel button label
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get cancelButton;

  /// Save button label
  ///
  /// In he, this message translates to:
  /// **'שמור'**
  String get saveButton;

  /// Close button label
  ///
  /// In he, this message translates to:
  /// **'סגור'**
  String get closeButton;

  /// Firebase/network connection error shown at startup
  ///
  /// In he, this message translates to:
  /// **'לא ניתן להתחבר לשרתי האפליקציה. אנא בדוק את החיבור לאינטרנט ונסה שוב.'**
  String get noInternetError;

  /// Language selector label
  ///
  /// In he, this message translates to:
  /// **'שפה'**
  String get languageLabel;

  /// Hebrew language option
  ///
  /// In he, this message translates to:
  /// **'עברית'**
  String get languageHebrew;

  /// English language option
  ///
  /// In he, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Arabic language option
  ///
  /// In he, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// App initialization error title
  ///
  /// In he, this message translates to:
  /// **'שגיאה באתחול האפליקציה'**
  String get appInitializationError;

  /// Contact support prompt shown on error screen
  ///
  /// In he, this message translates to:
  /// **'אם הבעיה נמשכת, אנא צור קשר עם התמיכה'**
  String get contactSupportMessage;

  /// Offline banner text
  ///
  /// In he, this message translates to:
  /// **'אין חיבור לאינטרנט'**
  String get offlineStatusText;

  /// Connection restored banner text
  ///
  /// In he, this message translates to:
  /// **'החיבור לאינטרנט שוחזר ✓'**
  String get onlineStatusText;

  /// Offline mode label in banner
  ///
  /// In he, this message translates to:
  /// **'פועל במצב לא מקוון'**
  String get offlineModeLabel;

  /// Manager role label
  ///
  /// In he, this message translates to:
  /// **'מנהל'**
  String get managerRole;

  /// Message update error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון ההודעה'**
  String get messageUpdateError;

  /// Message deletion error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה במחיקת ההודעה'**
  String get messageDeletionError;

  /// Forgot password screen title
  ///
  /// In he, this message translates to:
  /// **'שחזור סיסמה'**
  String get passwordRecoveryTitle;

  /// Email input prompt on forgot password screen
  ///
  /// In he, this message translates to:
  /// **'אנא הזן את כתובת האימייל שלך'**
  String get enterEmailAddressPrompt;

  /// Email required validation message
  ///
  /// In he, this message translates to:
  /// **'אנא הכנס כתובת אימייל'**
  String get emailRequiredValidation;

  /// Email format validation message
  ///
  /// In he, this message translates to:
  /// **'אנא הכנס כתובת אימייל תקינה'**
  String get emailInvalidValidation;

  /// Password reset link sent snackbar
  ///
  /// In he, this message translates to:
  /// **'קישור לאיפוס הסיסמה נשלח למייל שלך'**
  String get resetLinkSent;

  /// Password reset link error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בשליחת קישור לאיפוס סיסמה'**
  String get resetLinkError;

  /// Send reset link button label
  ///
  /// In he, this message translates to:
  /// **'שלח קישור לאיפוס'**
  String get sendResetLinkButton;

  /// Back button label
  ///
  /// In he, this message translates to:
  /// **'חזור'**
  String get backButton;

  /// Welcome/greeting title on login screen
  ///
  /// In he, this message translates to:
  /// **'שלום, ברוכים הבאים'**
  String get welcomeTitle;

  /// Login credentials prompt subtitle
  ///
  /// In he, this message translates to:
  /// **'אנא הכנס את פרטי הכניסה שלך'**
  String get loginCredentialsPrompt;

  /// Email field label
  ///
  /// In he, this message translates to:
  /// **'אימייל'**
  String get emailFieldLabel;

  /// Email field hint text
  ///
  /// In he, this message translates to:
  /// **'הכנס את כתובת האימייל שלך'**
  String get emailFieldHint;

  /// Password field label
  ///
  /// In he, this message translates to:
  /// **'סיסמה'**
  String get passwordFieldLabel;

  /// Password field hint text
  ///
  /// In he, this message translates to:
  /// **'הכנס את הסיסמה שלך'**
  String get passwordFieldHint;

  /// Password required error message
  ///
  /// In he, this message translates to:
  /// **'אנא הכנס סיסמה'**
  String get passwordRequiredError;

  /// Password minimum length error
  ///
  /// In he, this message translates to:
  /// **'הסיסמה חייבת להכיל לפחות 6 תווים'**
  String get passwordLengthError;

  /// Or divider between login methods
  ///
  /// In he, this message translates to:
  /// **'או'**
  String get orDividerText;

  /// Biometric login title
  ///
  /// In he, this message translates to:
  /// **'כניסה ביומטרית'**
  String get biometricLoginTitle;

  /// Biometric setup prompt message
  ///
  /// In he, this message translates to:
  /// **'האם לאפשר כניסה עתידית באמצעות טביעת אצבע / זיהוי פנים?'**
  String get biometricSetupPrompt;

  /// Enable biometric button label
  ///
  /// In he, this message translates to:
  /// **'אפשר'**
  String get enableBiometricButton;

  /// Decline biometric setup button label
  ///
  /// In he, this message translates to:
  /// **'לא, תודה'**
  String get declineBiometricButton;

  /// Biometric authentication failed message
  ///
  /// In he, this message translates to:
  /// **'אימות ביומטרי נכשל. אנא נסה שוב.'**
  String get biometricAuthFailed;

  /// No saved biometric credentials message
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו פרטי כניסה שמורים. אנא כנס עם אימייל וסיסמה.'**
  String get noBiometricCredentials;

  /// Application rejected dialog title
  ///
  /// In he, this message translates to:
  /// **'הבקשה נדחתה'**
  String get applicationRejectedTitle;

  /// Application rejected dialog message
  ///
  /// In he, this message translates to:
  /// **'בקשתך לאישור נדחתה על ידי ההנהלה.\nניתן לשלוח בקשת אישור חדשה.'**
  String get applicationRejectedMessage;

  /// Re-apply button label
  ///
  /// In he, this message translates to:
  /// **'שלח בקשה מחדש'**
  String get reApplyButton;

  /// Re-apply success snackbar
  ///
  /// In he, this message translates to:
  /// **'הבקשה נשלחה מחדש. ההנהלה תעדכן אותך בהחלטה.'**
  String get reApplySuccess;

  /// Registration screen title
  ///
  /// In he, this message translates to:
  /// **'הרשמה לפארק גננה'**
  String get registrationTitle;

  /// Registration screen subtitle
  ///
  /// In he, this message translates to:
  /// **'מלא את הפרטים לשליחת בקשת הצטרפות'**
  String get registrationSubtitle;

  /// Name required validation message
  ///
  /// In he, this message translates to:
  /// **'יש להזין שם מלא'**
  String get nameRequiredValidation;

  /// Name contains invalid characters validation
  ///
  /// In he, this message translates to:
  /// **'יש להזין שם בתווים תקינים בלבד'**
  String get nameInvalidCharsValidation;

  /// Full name field label
  ///
  /// In he, this message translates to:
  /// **'שם מלא'**
  String get fullNameLabel;

  /// Full name field hint
  ///
  /// In he, this message translates to:
  /// **'לדוגמה: ישראל ישראלי'**
  String get fullNameHint;

  /// Phone number digits validation message
  ///
  /// In he, this message translates to:
  /// **'מספר טלפון חייב להכיל בדיוק 10 ספרות'**
  String get phoneDigitsValidation;

  /// Phone number format validation message
  ///
  /// In he, this message translates to:
  /// **'מספר טלפון ישראלי חייב להתחיל ב-05'**
  String get phoneFormatValidation;

  /// Phone number field label
  ///
  /// In he, this message translates to:
  /// **'מספר טלפון'**
  String get phoneLabel;

  /// Phone number field hint
  ///
  /// In he, this message translates to:
  /// **'05XXXXXXXX'**
  String get phoneHint;

  /// ID number digits validation message
  ///
  /// In he, this message translates to:
  /// **'תעודת זהות חייבת להכיל בדיוק 9 ספרות'**
  String get idDigitsValidation;

  /// ID check digit validation message
  ///
  /// In he, this message translates to:
  /// **'מספר תעודת הזהות אינו תקין'**
  String get idCheckDigitValidation;

  /// ID number field label
  ///
  /// In he, this message translates to:
  /// **'תעודת זהות'**
  String get idLabel;

  /// ID number field hint
  ///
  /// In he, this message translates to:
  /// **'9 ספרות'**
  String get idHint;

  /// Email address field label
  ///
  /// In he, this message translates to:
  /// **'כתובת אימייל'**
  String get emailLabel;

  /// Email address field hint
  ///
  /// In he, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// Password minimum length validation
  ///
  /// In he, this message translates to:
  /// **'הסיסמה חייבת להכיל לפחות 6 תווים'**
  String get passwordMinLengthValidation;

  /// Password field label
  ///
  /// In he, this message translates to:
  /// **'סיסמה'**
  String get passwordLabel;

  /// Password field hint
  ///
  /// In he, this message translates to:
  /// **'לפחות 6 תווים'**
  String get passwordHint;

  /// Password mismatch validation message
  ///
  /// In he, this message translates to:
  /// **'הסיסמאות אינן תואמות'**
  String get passwordMismatchValidation;

  /// Confirm password field label
  ///
  /// In he, this message translates to:
  /// **'אישור סיסמה'**
  String get confirmPasswordLabel;

  /// Confirm password field hint
  ///
  /// In he, this message translates to:
  /// **'הזן שוב את הסיסמה'**
  String get confirmPasswordHint;

  /// Personal details section header
  ///
  /// In he, this message translates to:
  /// **'פרטים אישיים'**
  String get personalDetailsSection;

  /// Login details section header
  ///
  /// In he, this message translates to:
  /// **'פרטי כניסה'**
  String get loginDetailsSection;

  /// Validation errors banner with count
  ///
  /// In he, this message translates to:
  /// **'יש לתקן {count} {noun} לפני שליחה'**
  String validationErrorsBanner(int count, String noun);

  /// Singular form of error
  ///
  /// In he, this message translates to:
  /// **'שגיאה'**
  String get validationErrorSingular;

  /// Plural form of errors
  ///
  /// In he, this message translates to:
  /// **'שגיאות'**
  String get validationErrorPlural;

  /// Registration approval notice text
  ///
  /// In he, this message translates to:
  /// **'לאחר שליחת הבקשה, ההנהלה תאשר את חשבונך ותוכל להתחבר לאפליקציה.'**
  String get registrationApprovalNotice;

  /// Submit registration button label
  ///
  /// In he, this message translates to:
  /// **'שלח בקשת הצטרפות'**
  String get submitRegistrationButton;

  /// Registration success dialog title
  ///
  /// In he, this message translates to:
  /// **'הבקשה נשלחה בהצלחה!'**
  String get registrationSuccessTitle;

  /// Registration success dialog message
  ///
  /// In he, this message translates to:
  /// **'הנהלת הפארק תבדוק את פרטיך ותיצור איתך קשר בהקדם האפשרי.'**
  String get registrationSuccessMessage;

  /// Registration approval info text
  ///
  /// In he, this message translates to:
  /// **'לאחר אישור ההנהלה תקבל גישה לאפליקציה ותוכל להתחבר.'**
  String get registrationApprovalInfo;

  /// Back to home button label
  ///
  /// In he, this message translates to:
  /// **'חזור לדף הראשי'**
  String get backToHomeButton;

  /// New worker welcome screen title
  ///
  /// In he, this message translates to:
  /// **'עובד חדש? ברוך הבא!'**
  String get newWorkerWelcomeTitle;

  /// Registration steps subtitle
  ///
  /// In he, this message translates to:
  /// **'הצטרף לצוות פארק גננה בכמה צעדים פשוטים'**
  String get registrationStepsSubtitle;

  /// How it works section header
  ///
  /// In he, this message translates to:
  /// **'איך זה עובד?'**
  String get howItWorksSection;

  /// Registration step 1 title
  ///
  /// In he, this message translates to:
  /// **'מלא טופס הרשמה'**
  String get step1Title;

  /// Registration step 1 subtitle
  ///
  /// In he, this message translates to:
  /// **'הזן את פרטיך האישיים ובחר סיסמה'**
  String get step1Subtitle;

  /// Registration step 2 title
  ///
  /// In he, this message translates to:
  /// **'אישור ההנהלה'**
  String get step2Title;

  /// Registration step 2 subtitle
  ///
  /// In he, this message translates to:
  /// **'הנהלת הפארק תבדוק את פרטיך ותאשר את חשבונך'**
  String get step2Subtitle;

  /// Registration step 3 title
  ///
  /// In he, this message translates to:
  /// **'הצטרף לצוות'**
  String get step3Title;

  /// Registration step 3 subtitle
  ///
  /// In he, this message translates to:
  /// **'לאחר האישור תוכל להתחבר ולהתחיל לעבוד'**
  String get step3Subtitle;

  /// Welcome subtitle on welcome screen
  ///
  /// In he, this message translates to:
  /// **'ברוכים הבאים'**
  String get welcomeSubtitle;

  /// Shifts navigation label
  ///
  /// In he, this message translates to:
  /// **'משמרות'**
  String get shiftsNavLabel;

  /// Weekly work schedule navigation label
  ///
  /// In he, this message translates to:
  /// **'סידור עבודה'**
  String get weeklyScheduleNavLabel;

  /// Tasks navigation label
  ///
  /// In he, this message translates to:
  /// **'משימות'**
  String get tasksNavLabel;

  /// Reports navigation label
  ///
  /// In he, this message translates to:
  /// **'דוחות'**
  String get reportsNavLabel;

  /// Newsfeed/bulletin board navigation label
  ///
  /// In he, this message translates to:
  /// **'לוח מודעות'**
  String get newsfeedNavLabel;

  /// Worker management navigation label
  ///
  /// In he, this message translates to:
  /// **'ניהול עובדים'**
  String get manageWorkersNavLabel;

  /// Weekly scheduling navigation label
  ///
  /// In he, this message translates to:
  /// **'סידור שבועי'**
  String get weeklySchedulingNavLabel;

  /// Dashboard navigation label
  ///
  /// In he, this message translates to:
  /// **'לוח בקרה'**
  String get dashboardNavLabel;

  /// Total team size metric label
  ///
  /// In he, this message translates to:
  /// **'צוות כולל'**
  String get totalTeamLabel;

  /// Monthly hours metric label
  ///
  /// In he, this message translates to:
  /// **'שעות החודש'**
  String get monthlyHoursLabel;

  /// Open tasks metric label
  ///
  /// In he, this message translates to:
  /// **'משימות פתוחות'**
  String get openTasksLabel;

  /// Present today metric label
  ///
  /// In he, this message translates to:
  /// **'נוכחים היום'**
  String get presentTodayLabel;

  /// Create shift action button
  ///
  /// In he, this message translates to:
  /// **'צור משמרת'**
  String get createShiftAction;

  /// Create task action button
  ///
  /// In he, this message translates to:
  /// **'צור משימה'**
  String get createTaskAction;

  /// Publish post action button
  ///
  /// In he, this message translates to:
  /// **'פרסם הודעה'**
  String get publishPostAction;

  /// Hours report action button
  ///
  /// In he, this message translates to:
  /// **'דוח שעות'**
  String get hoursReportAction;

  /// Workers tab label
  ///
  /// In he, this message translates to:
  /// **'עובדים'**
  String get workersTabLabel;

  /// Managers tab label
  ///
  /// In he, this message translates to:
  /// **'מנהלים'**
  String get managersTabLabel;

  /// Today tab label
  ///
  /// In he, this message translates to:
  /// **'היום'**
  String get todayTabLabel;

  /// This week tab label
  ///
  /// In he, this message translates to:
  /// **'השבוע'**
  String get thisWeekTabLabel;

  /// Open tasks tab label
  ///
  /// In he, this message translates to:
  /// **'פתוחות'**
  String get openTasksTabLabel;

  /// Urgent tasks tab label
  ///
  /// In he, this message translates to:
  /// **'דחוף'**
  String get urgentTasksTabLabel;

  /// Image cropper dialog title
  ///
  /// In he, this message translates to:
  /// **'חתוך תמונה'**
  String get cropImageTitle;

  /// Profile picture updated snackbar
  ///
  /// In he, this message translates to:
  /// **'תמונת הפרופיל עודכנה בהצלחה'**
  String get profilePictureUpdated;

  /// Upload error snackbar with error detail
  ///
  /// In he, this message translates to:
  /// **'שגיאה: {error}'**
  String uploadError(String error);

  /// Take photo action label
  ///
  /// In he, this message translates to:
  /// **'צלם תמונה'**
  String get takePhotoAction;

  /// Take photo subtitle
  ///
  /// In he, this message translates to:
  /// **'השתמש במצלמה'**
  String get takePhrotoSubtitle;

  /// Choose from gallery action label
  ///
  /// In he, this message translates to:
  /// **'בחר מהגלריה'**
  String get chooseFromGalleryAction;

  /// Upload from gallery subtitle
  ///
  /// In he, this message translates to:
  /// **'העלה מהתמונות שלך'**
  String get uploadFromGallerySubtitle;

  /// No data found placeholder
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו נתונים'**
  String get noDataFound;

  /// Authorized departments section label
  ///
  /// In he, this message translates to:
  /// **'מחלקות מורשות'**
  String get authorizedDepartmentsLabel;

  /// Department permissions section header
  ///
  /// In he, this message translates to:
  /// **'הרשאות מחלקה'**
  String get departmentPermissionsSection;

  /// Worker role label
  ///
  /// In he, this message translates to:
  /// **'עובד'**
  String get workerRoleLabel;

  /// Owner role label
  ///
  /// In he, this message translates to:
  /// **'בעלים'**
  String get ownerRoleLabel;

  /// Co-owner role label
  ///
  /// In he, this message translates to:
  /// **'בעלים משותף'**
  String get coOwnerRoleLabel;

  /// Attendance saved success snackbar
  ///
  /// In he, this message translates to:
  /// **'הנוכחות נשמרה בהצלחה'**
  String get attendanceSaved;

  /// Attendance save error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בשמירת הנוכחות'**
  String get attendanceSaveError;

  /// End shift dialog title
  ///
  /// In he, this message translates to:
  /// **'סיום משמרת'**
  String get endShiftDialogTitle;

  /// Record checkout confirmation message
  ///
  /// In he, this message translates to:
  /// **'לרשום יציאה עכשיו עבור משמרת זו?'**
  String get recordCheckoutConfirmation;

  /// End shift button label
  ///
  /// In he, this message translates to:
  /// **'סיים משמרת'**
  String get endShiftButton;

  /// Checkout recorded reminder snackbar
  ///
  /// In he, this message translates to:
  /// **'שעת יציאה נרשמה — זכור לשמור'**
  String get checkoutRecordedReminder;

  /// Record updated reminder snackbar
  ///
  /// In he, this message translates to:
  /// **'הרשומה עודכנה — זכור לשמור'**
  String get recordUpdatedReminder;

  /// Record added reminder snackbar
  ///
  /// In he, this message translates to:
  /// **'רשומה נוספה — זכור לשמור'**
  String get recordAddedReminder;

  /// Record deleted snackbar with record number
  ///
  /// In he, this message translates to:
  /// **'רשומה מס׳ {recordNumber} נמחקה'**
  String recordDeleted(int recordNumber);

  /// Undo button label
  ///
  /// In he, this message translates to:
  /// **'בטל'**
  String get undoButton;

  /// Unsaved changes dialog title
  ///
  /// In he, this message translates to:
  /// **'שינויים לא נשמרו'**
  String get unsavedChangesTitle;

  /// Stay button label in unsaved changes dialog
  ///
  /// In he, this message translates to:
  /// **'הישאר'**
  String get stayButton;

  /// Exit without saving button label
  ///
  /// In he, this message translates to:
  /// **'צא ללא שמירה'**
  String get exitWithoutSavingButton;

  /// Work days metric label
  ///
  /// In he, this message translates to:
  /// **'ימי עבודה'**
  String get workDaysLabel;

  /// Hours label
  ///
  /// In he, this message translates to:
  /// **'שעות'**
  String get hoursLabel;

  /// Hours abbreviated label
  ///
  /// In he, this message translates to:
  /// **'שע׳'**
  String get hoursShortLabel;

  /// Records label
  ///
  /// In he, this message translates to:
  /// **'רשומות'**
  String get recordsLabel;

  /// Missing checkout label
  ///
  /// In he, this message translates to:
  /// **'חסר יציאה'**
  String get missingCheckoutLabel;

  /// Add record button label
  ///
  /// In he, this message translates to:
  /// **'הוסף רשומה'**
  String get addRecordButton;

  /// Check-in field label
  ///
  /// In he, this message translates to:
  /// **'כניסה'**
  String get checkInFieldLabel;

  /// Check-out field label
  ///
  /// In he, this message translates to:
  /// **'יציאה'**
  String get checkOutFieldLabel;

  /// Attendance report error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בדיווח נוכחות: {error}'**
  String attendanceReportError(String error);

  /// Outside park bounds dialog message
  ///
  /// In he, this message translates to:
  /// **'אינך נמצא בגבולות הפארק'**
  String get outsideParkBoundsMessage;

  /// Draft restored snackbar
  ///
  /// In he, this message translates to:
  /// **'טיוטה שוחזרה'**
  String get draftRestoredSnackbar;

  /// Clear draft action label
  ///
  /// In he, this message translates to:
  /// **'נקה'**
  String get clearDraftAction;

  /// Task title required validation message
  ///
  /// In he, this message translates to:
  /// **'נא להזין כותרת למשימה'**
  String get taskTitleRequiredValidation;

  /// Select at least one worker validation message
  ///
  /// In he, this message translates to:
  /// **'נא לבחור לפחות עובד אחד'**
  String get selectAtLeastOneWorkerValidation;

  /// Select deadline validation message
  ///
  /// In he, this message translates to:
  /// **'נא לבחור תאריך ושעה'**
  String get selectDeadlineValidation;

  /// Empty state title in comments
  ///
  /// In he, this message translates to:
  /// **'אין תגובות עדיין'**
  String get noCommentsEmpty;

  /// Outgoing call dialog title
  ///
  /// In he, this message translates to:
  /// **'שיחה יוצאת'**
  String get callDialogTitle;

  /// Call confirmation dialog message
  ///
  /// In he, this message translates to:
  /// **'להתקשר אל {name}?\n{phone}'**
  String callConfirmation(String name, String phone);

  /// Dial failed snackbar
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לחייג אל {phone}'**
  String dialFailed(String phone);

  /// No pending workers empty state
  ///
  /// In he, this message translates to:
  /// **'אין עובדים שממתינים לאישור'**
  String get noPendingWorkersEmpty;

  /// Call tooltip label
  ///
  /// In he, this message translates to:
  /// **'התקשר'**
  String get callTooltip;

  /// No active workers empty state
  ///
  /// In he, this message translates to:
  /// **'אין עובדים פעילים במערכת'**
  String get noActiveWorkersEmpty;

  /// Worker approved snackbar
  ///
  /// In he, this message translates to:
  /// **'העובד אושר בהצלחה'**
  String get workerApproved;

  /// Application rejected snackbar
  ///
  /// In he, this message translates to:
  /// **'הבקשה נדחתה. העובד קיבל הודעה.'**
  String get applicationRejectedSnackbar;

  /// Approve worker button label
  ///
  /// In he, this message translates to:
  /// **'אשר עובד'**
  String get approveWorkerButton;

  /// Approve worker screen title
  ///
  /// In he, this message translates to:
  /// **'אישור עובד'**
  String get approveWorkerTitle;

  /// Reject application button label
  ///
  /// In he, this message translates to:
  /// **'דחה בקשה'**
  String get rejectApplicationButton;

  /// Reject application screen title
  ///
  /// In he, this message translates to:
  /// **'דחיית בקשה'**
  String get rejectApplicationTitle;

  /// Show shifts button label
  ///
  /// In he, this message translates to:
  /// **'הצג משמרות'**
  String get showShiftsButton;

  /// Assign task button label
  ///
  /// In he, this message translates to:
  /// **'שייך משימה'**
  String get assignTaskButton;

  /// View performance button label
  ///
  /// In he, this message translates to:
  /// **'הצג ביצועים'**
  String get viewPerformanceButton;

  /// Correct attendance button label
  ///
  /// In he, this message translates to:
  /// **'תיקון נוכחות'**
  String get correctAttendanceButton;

  /// Manage permissions and role button label
  ///
  /// In he, this message translates to:
  /// **'ניהול הרשאות ותפקיד'**
  String get managePermissionsButton;

  /// Revoke worker approval button label
  ///
  /// In he, this message translates to:
  /// **'בטל אישור עובד'**
  String get revokeApprovalButton;

  /// Revoke approval dialog title
  ///
  /// In he, this message translates to:
  /// **'ביטול אישור עובד'**
  String get revokeApprovalTitle;

  /// Revoke approval dialog message
  ///
  /// In he, this message translates to:
  /// **'העובד יועבר חזרה לרשימת הממתינים לאישור. הפעולה ניתנת לביטול.'**
  String get revokeApprovalMessage;

  /// Approval revoked snackbar
  ///
  /// In he, this message translates to:
  /// **'אישור העובד בוטל'**
  String get approvalRevoked;

  /// Licenses/permissions updated snackbar
  ///
  /// In he, this message translates to:
  /// **'ההרשאות עודכנו בהצלחה'**
  String get licensesUpdated;

  /// Save licenses error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בשמירת הנתונים'**
  String get saveLicensesError;

  /// Attendance report screen title
  ///
  /// In he, this message translates to:
  /// **'דו״ח נוכחות'**
  String get attendanceReportTitle;

  /// Days label
  ///
  /// In he, this message translates to:
  /// **'ימים'**
  String get daysLabel;

  /// Average per day label
  ///
  /// In he, this message translates to:
  /// **'ממוצע/יום'**
  String get averagePerDayLabel;

  /// Hours per day chart title
  ///
  /// In he, this message translates to:
  /// **'שעות עבודה לפי יום'**
  String get hoursPerDayChartTitle;

  /// Attendance details section title
  ///
  /// In he, this message translates to:
  /// **'פירוט נוכחות'**
  String get attendanceDetailsTitle;

  /// Shift report screen title
  ///
  /// In he, this message translates to:
  /// **'דו״ח משמרות'**
  String get shiftReportTitle;

  /// Total label
  ///
  /// In he, this message translates to:
  /// **'סה״כ'**
  String get totalLabel;

  /// Approved label
  ///
  /// In he, this message translates to:
  /// **'אושרו'**
  String get approvedLabel;

  /// Rejected/other label
  ///
  /// In he, this message translates to:
  /// **'נדחו/אחר'**
  String get rejectedOtherLabel;

  /// Decisions distribution chart title
  ///
  /// In he, this message translates to:
  /// **'התפלגות החלטות'**
  String get decisionsDistributionTitle;

  /// Shifts details section title
  ///
  /// In he, this message translates to:
  /// **'פירוט משמרות'**
  String get shiftsDetailsTitle;

  /// Shift coverage report title
  ///
  /// In he, this message translates to:
  /// **'כיסוי משמרות'**
  String get shiftCoverageTitle;

  /// Total shifts label
  ///
  /// In he, this message translates to:
  /// **'סה\"כ משמרות'**
  String get totalShiftsLabel;

  /// Staffing rate label
  ///
  /// In he, this message translates to:
  /// **'מילוי משרות'**
  String get staffingRateLabel;

  /// Active departments label
  ///
  /// In he, this message translates to:
  /// **'מחלקות פעילות'**
  String get activeDepartmentsLabel;

  /// Shifts by department chart title
  ///
  /// In he, this message translates to:
  /// **'משמרות לפי מחלקה'**
  String get shiftsByDepartmentTitle;

  /// Department details section title
  ///
  /// In he, this message translates to:
  /// **'פירוט מחלקות'**
  String get departmentDetailsTitle;

  /// Missing checkouts report title
  ///
  /// In he, this message translates to:
  /// **'יציאות חסרות'**
  String get missingCheckoutsTitle;

  /// No missing checkouts empty state
  ///
  /// In he, this message translates to:
  /// **'אין יציאות חסרות'**
  String get noMissingCheckoutsEmpty;

  /// Details by worker section title
  ///
  /// In he, this message translates to:
  /// **'פירוט לפי עובד'**
  String get detailsByWorkerTitle;

  /// My reports screen title
  ///
  /// In he, this message translates to:
  /// **'הדוחות שלי'**
  String get myReportsTitle;

  /// Task report card label
  ///
  /// In he, this message translates to:
  /// **'דו״ח משימות'**
  String get taskReportCard;

  /// Select photos action label
  ///
  /// In he, this message translates to:
  /// **'בחר תמונות'**
  String get selectPhotosAction;

  /// Select photos from gallery subtitle
  ///
  /// In he, this message translates to:
  /// **'בחר תמונות מהגלריה'**
  String get selectPhotosFromGallery;

  /// Select video action label
  ///
  /// In he, this message translates to:
  /// **'בחר סרטון'**
  String get selectVideoAction;

  /// Select video from gallery subtitle
  ///
  /// In he, this message translates to:
  /// **'בחר סרטון מהגלריה'**
  String get selectVideoFromGallery;

  /// Open camera subtitle
  ///
  /// In he, this message translates to:
  /// **'פתח את המצלמה'**
  String get openCameraSubtitle;

  /// Title field hint in create post dialog
  ///
  /// In he, this message translates to:
  /// **'הזן כותרת לפוסט...'**
  String get postTitleHint;

  /// Content field hint in create post dialog
  ///
  /// In he, this message translates to:
  /// **'מה תרצה לשתף?'**
  String get postContentHint;

  /// Delete comment confirmation dialog title
  ///
  /// In he, this message translates to:
  /// **'מחיקת תגובה'**
  String get deleteCommentTitle;

  /// Delete comment confirmation message
  ///
  /// In he, this message translates to:
  /// **'האם אתה בטוח שברצונך למחוק את התגובה?'**
  String get deleteCommentConfirmation;

  /// Delete post confirmation dialog title
  ///
  /// In he, this message translates to:
  /// **'מחיקת פוסט'**
  String get deletePostTitle;

  /// Delete post confirmation message
  ///
  /// In he, this message translates to:
  /// **'האם אתה בטוח שברצונך למחוק את הפוסט?\nפעולה זו לא ניתנת לביטול.'**
  String get deletePostConfirmation;

  /// Edit post menu action
  ///
  /// In he, this message translates to:
  /// **'ערוך פוסט'**
  String get editPostAction;

  /// Delete post menu action
  ///
  /// In he, this message translates to:
  /// **'מחק פוסט'**
  String get deletePostAction;

  /// Editing post title
  ///
  /// In he, this message translates to:
  /// **'עריכת פוסט'**
  String get editingPostTitle;

  /// Notifications screen title
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get notificationsTitle;

  /// Mark all as read button label
  ///
  /// In he, this message translates to:
  /// **'סמן הכל כנקרא'**
  String get markAllAsReadButton;

  /// Load notifications error message
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת ההתראות'**
  String get loadNotificationsError;

  /// Open shift error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בפתיחת המשמרת'**
  String get openShiftError;

  /// Open task error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בפתיחת המשימה'**
  String get openTaskError;

  /// No notifications empty state
  ///
  /// In he, this message translates to:
  /// **'אין התראות'**
  String get noNotificationsEmpty;

  /// New notifications will appear here subtitle
  ///
  /// In he, this message translates to:
  /// **'התראות חדשות יופיעו כאן'**
  String get newNotificationsWillAppear;

  /// Cannot open link snackbar
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לפתוח את הקישור'**
  String get cannotOpenLink;

  /// Settings screen title
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get settingsTitle;

  /// Change password section title
  ///
  /// In he, this message translates to:
  /// **'שינוי סיסמה'**
  String get changePasswordTitle;

  /// Biometric methods subtitle
  ///
  /// In he, this message translates to:
  /// **'טביעת אצבע / זיהוי פנים'**
  String get biometricMethodsSubtitle;

  /// Push notifications section title
  ///
  /// In he, this message translates to:
  /// **'התראות פוש'**
  String get pushNotificationsTitle;

  /// Push notifications subtitle
  ///
  /// In he, this message translates to:
  /// **'קבלת עדכונים על משמרות ומשימות'**
  String get pushNotificationsSubtitle;

  /// Privacy policy section title
  ///
  /// In he, this message translates to:
  /// **'מדיניות פרטיות'**
  String get privacyPolicyTitle;

  /// Terms of service section title
  ///
  /// In he, this message translates to:
  /// **'תנאי שימוש'**
  String get termsOfServiceTitle;

  /// Crash reports section title
  ///
  /// In he, this message translates to:
  /// **'שלח דוחות קריסה'**
  String get crashReportsTitle;

  /// Crash reports section subtitle
  ///
  /// In he, this message translates to:
  /// **'עוזר לנו לשפר את יציבות האפליקציה'**
  String get crashReportsSubtitle;

  /// App version section title
  ///
  /// In he, this message translates to:
  /// **'גרסת האפליקציה'**
  String get appVersionTitle;

  /// Delete account section title
  ///
  /// In he, this message translates to:
  /// **'מחיקת חשבון'**
  String get deleteAccountTitle;

  /// Delete account section subtitle
  ///
  /// In he, this message translates to:
  /// **'פעולה בלתי הפיכה — כל הנתונים יימחקו'**
  String get deleteAccountSubtitle;

  /// Password changed success snackbar
  ///
  /// In he, this message translates to:
  /// **'הסיסמה עודכנה בהצלחה'**
  String get passwordChanged;

  /// Biometric auth failed snackbar in settings
  ///
  /// In he, this message translates to:
  /// **'האימות הביומטרי נכשל'**
  String get biometricAuthFailedSnackbar;

  /// Enable biometric error snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בהפעלת הכניסה הביומטרית'**
  String get enableBiometricError;

  /// Enable biometric dialog title
  ///
  /// In he, this message translates to:
  /// **'הפעלת כניסה ביומטרית'**
  String get enableBiometricTitle;

  /// Permanent deletion dialog title
  ///
  /// In he, this message translates to:
  /// **'מחיקה סופית'**
  String get permanentDeletionTitle;

  /// Options tooltip
  ///
  /// In he, this message translates to:
  /// **'אפשרויות'**
  String get optionsTooltip;

  /// Settings menu item
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get settingsMenu;

  /// No button label
  ///
  /// In he, this message translates to:
  /// **'לא'**
  String get noButton;

  /// Yes button label
  ///
  /// In he, this message translates to:
  /// **'כן'**
  String get yesButton;

  /// Long press hint label
  ///
  /// In he, this message translates to:
  /// **'לחץ לחיצה ארוכה'**
  String get longPressHint;

  /// Weather label
  ///
  /// In he, this message translates to:
  /// **'מזג אוויר'**
  String get weatherLabel;

  /// Load data error message
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לטעון נתונים. בדוק חיבור או אינדקס.'**
  String get loadDataError;

  /// No shifts empty state
  ///
  /// In he, this message translates to:
  /// **'אין משמרות להצגה'**
  String get noShiftsEmpty;

  /// Shift hours format
  ///
  /// In he, this message translates to:
  /// **'שעות: {startTime} - {endTime}'**
  String shiftHoursFormat(String startTime, String endTime);

  /// Department prefix with value
  ///
  /// In he, this message translates to:
  /// **'מחלקה: {department}'**
  String departmentPrefix(String department);

  /// Unsaved changes dialog message
  ///
  /// In he, this message translates to:
  /// **'יש לך שינויים שלא נשמרו. האם אתה בטוח שברצונך לצאת?'**
  String get unsavedChangesMessage;

  /// No attendance records empty state
  ///
  /// In he, this message translates to:
  /// **'אין רשומות נוכחות לחודש זה'**
  String get noAttendanceRecords;

  /// Add manual record hint text under empty state
  ///
  /// In he, this message translates to:
  /// **'הוסף רשומה ידנית או בחר חודש אחר'**
  String get addManualRecordHint;

  /// Missing label (short, for time chip)
  ///
  /// In he, this message translates to:
  /// **'חסר'**
  String get missingLabel;

  /// Active label (short, for time chip)
  ///
  /// In he, this message translates to:
  /// **'פעיל'**
  String get activeLabel;

  /// Save changes button label
  ///
  /// In he, this message translates to:
  /// **'שמור שינויים'**
  String get saveChangesButton;

  /// Edit attendance record dialog title
  ///
  /// In he, this message translates to:
  /// **'עריכת רשומת נוכחות'**
  String get editAttendanceRecordTitle;

  /// Location permission required dialog title
  ///
  /// In he, this message translates to:
  /// **'נדרשת גישה למיקום'**
  String get locationPermissionTitle;

  /// Location permission required dialog message
  ///
  /// In he, this message translates to:
  /// **'כדי לדווח כניסה או יציאה ממשמרת יש לאפשר שירותי מיקום במכשיר.'**
  String get locationPermissionMessage;

  /// Enable location settings button label
  ///
  /// In he, this message translates to:
  /// **'הפעל מיקום'**
  String get enableLocationButton;

  /// Clock-in outside park bounds confirmation message
  ///
  /// In he, this message translates to:
  /// **'אתה מנסה להתחבר מחוץ לאזור המותר. האם ברצונך להמשיך בכל זאת?'**
  String get clockInOutsideParkMessage;

  /// Clock-out outside park bounds confirmation message
  ///
  /// In he, this message translates to:
  /// **'אתה מנסה להתנתק מחוץ לאזור המותר. האם ברצונך להמשיך בכל זאת?'**
  String get clockOutOutsideParkMessage;

  /// Long-press hint label when clocked in
  ///
  /// In he, this message translates to:
  /// **'לחיצה ארוכה לסיום משמרת'**
  String get longPressToEndShift;

  /// Long-press hint label when clocked out
  ///
  /// In he, this message translates to:
  /// **'לחיצה ארוכה להתחיל משמרת'**
  String get longPressToStartShift;

  /// Clocked in since label with time
  ///
  /// In he, this message translates to:
  /// **'מאז {time}'**
  String clockedInSince(String time);

  /// Date label with value
  ///
  /// In he, this message translates to:
  /// **'תאריך: {date}'**
  String datePrefix(String date);

  /// Clock-in time label with value
  ///
  /// In he, this message translates to:
  /// **'שעת כניסה: {time}'**
  String clockInTimePrefix(String time);

  /// Clock-out time label with value
  ///
  /// In he, this message translates to:
  /// **'שעת יציאה: {time}'**
  String clockOutTimePrefix(String time);

  /// Work duration label with hours and minutes
  ///
  /// In he, this message translates to:
  /// **'משך העבודה: {hours}ש׳ {minutes}ד׳'**
  String workDurationLabel(int hours, int minutes);

  /// Good night greeting
  ///
  /// In he, this message translates to:
  /// **'לילה טוב,'**
  String get greetingNight;

  /// Good morning greeting
  ///
  /// In he, this message translates to:
  /// **'בוקר טוב,'**
  String get greetingMorning;

  /// Good afternoon greeting
  ///
  /// In he, this message translates to:
  /// **'צהריים טובים,'**
  String get greetingAfternoon;

  /// Good evening greeting
  ///
  /// In he, this message translates to:
  /// **'ערב טוב,'**
  String get greetingEvening;

  /// Motivational message 1
  ///
  /// In he, this message translates to:
  /// **'אתה חלק חשוב בצוות שלנו 💪'**
  String get motivationalMsg1;

  /// Motivational message 2
  ///
  /// In he, this message translates to:
  /// **'כל משמרת היא הזדמנות להשפיע ✨'**
  String get motivationalMsg2;

  /// Motivational message 3
  ///
  /// In he, this message translates to:
  /// **'תשמור על חיוך – זה מדבק 😄'**
  String get motivationalMsg3;

  /// This month label
  ///
  /// In he, this message translates to:
  /// **'החודש'**
  String get thisMonthLabel;

  /// Now label (for time display)
  ///
  /// In he, this message translates to:
  /// **'עכשיו'**
  String get nowLabel;

  /// Minutes ago label
  ///
  /// In he, this message translates to:
  /// **'לפני {n} דק\''**
  String minutesAgoLabel(int n);

  /// Hours ago label
  ///
  /// In he, this message translates to:
  /// **'לפני {n} שע\''**
  String hoursAgoLabel(int n);

  /// Yesterday label
  ///
  /// In he, this message translates to:
  /// **'אתמול'**
  String get yesterdayLabel;

  /// Days ago label
  ///
  /// In he, this message translates to:
  /// **'לפני {n} ימים'**
  String daysAgoLabel(int n);

  /// Latest update label on home card
  ///
  /// In he, this message translates to:
  /// **'עדכון אחרון'**
  String get latestUpdateLabel;

  /// Read more link on truncated post content
  ///
  /// In he, this message translates to:
  /// **'קרא עוד'**
  String get readMoreLabel;

  /// Today overview card section title
  ///
  /// In he, this message translates to:
  /// **'מה חשוב עכשיו'**
  String get whatIsImportantNow;

  /// All up to date status message
  ///
  /// In he, this message translates to:
  /// **'הכל מעודכן — אין פריטים דחופים'**
  String get allUpToDate;

  /// Shift changes pending status message
  ///
  /// In he, this message translates to:
  /// **'שינויים במשמרות ממתינים'**
  String get shiftChangesWaiting;

  /// Tasks awaiting approval status message
  ///
  /// In he, this message translates to:
  /// **'משימות ממתינות לאישור'**
  String get tasksWaitingApproval;

  /// New posts in bulletin board status message
  ///
  /// In he, this message translates to:
  /// **'פוסטים חדשים בלוח המודעות'**
  String get newPostsInBoard;

  /// New updates in bulletin board status message
  ///
  /// In he, this message translates to:
  /// **'עדכונים חדשים בלוח המודעות'**
  String get newUpdatesInBoard;

  /// New business activity to review status message
  ///
  /// In he, this message translates to:
  /// **'פעילות עסקית חדשה לבדיקה'**
  String get newBusinessActivity;

  /// New shifts assigned status message
  ///
  /// In he, this message translates to:
  /// **'משמרות חדשות שהוקצו לך'**
  String get newShiftsAssigned;

  /// Open tasks waiting status message
  ///
  /// In he, this message translates to:
  /// **'משימות פתוחות ממתינות לך'**
  String get openTasksWaiting;

  /// Accessibility label: tap to reset clock-out
  ///
  /// In he, this message translates to:
  /// **'לחץ לאיפוס שעון יציאה'**
  String get clickToResetClockOut;

  /// Accessibility label: tap to register clock-in
  ///
  /// In he, this message translates to:
  /// **'לחץ לרישום שעון כניסה'**
  String get clickToRegisterClockIn;

  /// Completed label (tasks)
  ///
  /// In he, this message translates to:
  /// **'הושלמו'**
  String get completedLabel;

  /// Present now section title on owner dashboard
  ///
  /// In he, this message translates to:
  /// **'נוכחים כעת'**
  String get presentNowLabel;

  /// No workers currently connected empty state
  ///
  /// In he, this message translates to:
  /// **'אין עובדים מחוברים כרגע'**
  String get noWorkersConnected;

  /// Top workers this month section title
  ///
  /// In he, this message translates to:
  /// **'מובילי החודש'**
  String get topWorkersThisMonth;

  /// Work hours this month chart title
  ///
  /// In he, this message translates to:
  /// **'שעות עבודה — החודש'**
  String get workHoursThisMonth;

  /// Average hours per worker subtitle
  ///
  /// In he, this message translates to:
  /// **'ממוצע {hours} שעות לעובד'**
  String averageHoursPerWorker(String hours);

  /// Owner dashboard screen title
  ///
  /// In he, this message translates to:
  /// **'לוח בקרה — בעלים'**
  String get ownerDashboardTitle;

  /// Hello greeting with name
  ///
  /// In he, this message translates to:
  /// **'שלום, {name}'**
  String helloName(String name);

  /// Quick actions section label
  ///
  /// In he, this message translates to:
  /// **'פעולות מהירות'**
  String get quickActionsLabel;

  /// Staff section label
  ///
  /// In he, this message translates to:
  /// **'כוח אדם'**
  String get staffLabel;

  /// Staff count summary line
  ///
  /// In he, this message translates to:
  /// **'סה\"כ {count} אנשים בצוות • לחץ לניהול'**
  String staffCountSummary(int count);

  /// Employee management system label on splash
  ///
  /// In he, this message translates to:
  /// **'מערכת ניהול עובדים'**
  String get employeeManagementSystem;

  /// My profile screen title
  ///
  /// In he, this message translates to:
  /// **'הפרופיל שלי'**
  String get myProfileTitle;

  /// GPS unavailable dialog title
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לאמת מיקום'**
  String get gpsUnavailableTitle;

  /// GPS unavailable dialog message
  ///
  /// In he, this message translates to:
  /// **'שירות המיקום אינו זמין או שהרשאות GPS לא אושרו. האם ברצונך להמשיך בכל זאת?'**
  String get gpsUnavailableMessage;

  /// Shown while GPS location is being determined on clock-in/out
  ///
  /// In he, this message translates to:
  /// **'...מחפש מיקום'**
  String get searchingLocationLabel;

  /// Network error load message on home screen
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לטעון את הנתונים.\nבדוק את החיבור ונסה שוב.'**
  String get networkErrorLoadMessage;

  /// Profile button tooltip
  ///
  /// In he, this message translates to:
  /// **'פרופיל'**
  String get profileTooltip;

  /// Notifications button tooltip
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get notificationsTooltip;

  /// Permissions coverage label
  ///
  /// In he, this message translates to:
  /// **'כיסוי הרשאות'**
  String get permissionsCoverageLabel;

  /// No active permissions empty state
  ///
  /// In he, this message translates to:
  /// **'אין הרשאות פעילות'**
  String get noActivePermissions;

  /// Update profile picture bottom sheet title
  ///
  /// In he, this message translates to:
  /// **'עדכון תמונת פרופיל'**
  String get updateProfilePictureTitle;

  /// Choose image source bottom sheet subtitle
  ///
  /// In he, this message translates to:
  /// **'בחר מקור לתמונה'**
  String get chooseImageSourceTitle;

  /// Set as profile picture confirmation message
  ///
  /// In he, this message translates to:
  /// **'להגדיר תמונה זו כתמונת הפרופיל שלך?'**
  String get setAsProfilePictureConfirm;

  /// Default CTA open button label on action card
  ///
  /// In he, this message translates to:
  /// **'פתח'**
  String get ctaOpenButton;

  /// Hint label to tap for weekly schedule
  ///
  /// In he, this message translates to:
  /// **'לחץ לסידור שבועי'**
  String get clickForWeeklySchedule;

  /// Hint label to tap for manage workers
  ///
  /// In he, this message translates to:
  /// **'לחץ לניהול עובדים'**
  String get clickForManageWorkers;

  /// Days worked stat label on user card
  ///
  /// In he, this message translates to:
  /// **'ימים שעבדת'**
  String get daysWorkedLabel;

  /// Hours worked stat label on user card
  ///
  /// In he, this message translates to:
  /// **'שעות שעבדת'**
  String get hoursWorkedLabel;

  /// Clock-in from time and duration label
  ///
  /// In he, this message translates to:
  /// **'מ-{clockIn} · {duration}'**
  String clockInFromLabel(String clockIn, String duration);

  /// Account section header in settings
  ///
  /// In he, this message translates to:
  /// **'חשבון'**
  String get accountSectionHeader;

  /// Language section header in settings
  ///
  /// In he, this message translates to:
  /// **'שפה'**
  String get languageSectionHeader;

  /// Language tile subtitle in settings
  ///
  /// In he, this message translates to:
  /// **'בחר את שפת הממשק'**
  String get languageSubtitle;

  /// Notifications section header in settings
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get notificationsSectionHeader;

  /// Information section header in settings
  ///
  /// In he, this message translates to:
  /// **'מידע'**
  String get infoSectionHeader;

  /// Sign out section header in settings
  ///
  /// In he, this message translates to:
  /// **'יציאה'**
  String get signOutSectionHeader;

  /// Danger zone section header in settings
  ///
  /// In he, this message translates to:
  /// **'אזור סכנה'**
  String get dangerZoneSectionHeader;

  /// Requires recent login error for password change
  ///
  /// In he, this message translates to:
  /// **'יש להתחבר מחדש לפני שינוי הסיסמה'**
  String get requiresRecentLoginError;

  /// Error updating password snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון הסיסמה'**
  String get updatePasswordError;

  /// New password field label
  ///
  /// In he, this message translates to:
  /// **'סיסמה חדשה'**
  String get newPasswordLabel;

  /// Password required validator message
  ///
  /// In he, this message translates to:
  /// **'נא להזין סיסמה'**
  String get passwordRequiredValidator;

  /// Update password button label
  ///
  /// In he, this message translates to:
  /// **'עדכן סיסמה'**
  String get updatePasswordButton;

  /// Description in biometric enable sheet
  ///
  /// In he, this message translates to:
  /// **'הזן את הסיסמה הנוכחית שלך כדי לאפשר כניסה עם טביעת אצבע / זיהוי פנים.'**
  String get biometricEnableDescription;

  /// Current password field label
  ///
  /// In he, this message translates to:
  /// **'סיסמה נוכחית'**
  String get currentPasswordLabel;

  /// Reason shown in biometric prompt when enabling biometric login
  ///
  /// In he, this message translates to:
  /// **'אמת את זהותך כדי להפעיל כניסה ביומטרית'**
  String get biometricVerifyReason;

  /// Activate biometric login button label
  ///
  /// In he, this message translates to:
  /// **'הפעל כניסה ביומטרית'**
  String get activateBiometricButton;

  /// Permanent deletion confirmation dialog message
  ///
  /// In he, this message translates to:
  /// **'פעולה זו בלתי הפיכה לחלוטין.\nכל הנתונים האישיים שלך יימחקו לצמיתות.'**
  String get permanentDeletionMessage;

  /// Delete account button label in confirmation dialog
  ///
  /// In he, this message translates to:
  /// **'מחק חשבון'**
  String get deleteAccountButton;

  /// Wrong password error snackbar
  ///
  /// In he, this message translates to:
  /// **'הסיסמה שגויה. אנא נסה שוב.'**
  String get wrongPasswordError;

  /// Requires recent login error for account deletion
  ///
  /// In he, this message translates to:
  /// **'נדרשת כניסה מחדש לפני מחיקת החשבון'**
  String get requiresRecentLoginDeleteError;

  /// Error deleting account snackbar
  ///
  /// In he, this message translates to:
  /// **'שגיאה במחיקת החשבון. אנא נסה שוב.'**
  String get deleteAccountError;

  /// Warning text shown in delete account sheet
  ///
  /// In he, this message translates to:
  /// **'פעולה זו תמחק את כל הנתונים האישיים שלך לצמיתות ולא ניתן לבטלה.\nאנא הזן את הסיסמה שלך לאישור.'**
  String get deleteAccountWarning;

  /// Delete my account permanently button label
  ///
  /// In he, this message translates to:
  /// **'מחק את חשבוני לצמיתות'**
  String get deleteMyAccountButton;

  /// New badge label on unread notification tiles
  ///
  /// In he, this message translates to:
  /// **'חדש'**
  String get newBadgeLabel;

  /// New workers tab label in manage workers screen
  ///
  /// In he, this message translates to:
  /// **'עובדים חדשים'**
  String get newWorkersTabLabel;

  /// Active workers tab label in manage workers screen
  ///
  /// In he, this message translates to:
  /// **'עובדים פעילים'**
  String get activeWorkersTabLabel;

  /// Search worker text field hint
  ///
  /// In he, this message translates to:
  /// **'חיפוש עובד לפי שם...'**
  String get searchWorkerHint;

  /// No search results empty state
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו תוצאות'**
  String get noSearchResultsEmpty;

  /// Banner shown when workers have missing clock-out
  ///
  /// In he, this message translates to:
  /// **'{count} {workers} עם שעת יציאה חסרה החודש'**
  String workersMissingClockOutBanner(int count, String workers);

  /// Singular word for worker (used in banner)
  ///
  /// In he, this message translates to:
  /// **'עובד'**
  String get workerLabelSingular;

  /// Plural word for workers (used in banner)
  ///
  /// In he, this message translates to:
  /// **'עובדים'**
  String get workerLabelPlural;

  /// Missing clock-out warning row on worker card
  ///
  /// In he, this message translates to:
  /// **'חסר שעת יציאה — לחץ לתיקון'**
  String get missingClockOutWarning;

  /// Worker subtitle shown on review worker screen
  ///
  /// In he, this message translates to:
  /// **'עובד בפארק ג׳ננה'**
  String get workerSubtitleInPark;

  /// Email label in worker info row
  ///
  /// In he, this message translates to:
  /// **'אימייל'**
  String get workerEmailInfoLabel;

  /// Phone label in worker info row
  ///
  /// In he, this message translates to:
  /// **'טלפון'**
  String get workerPhoneInfoLabel;

  /// Worker details card title
  ///
  /// In he, this message translates to:
  /// **'🧾 פרטי העובד'**
  String get workerDetailsCardTitle;

  /// Admin actions card title on review worker screen
  ///
  /// In he, this message translates to:
  /// **'🧭 פעולות מנהל'**
  String get adminActionsCardTitle;

  /// Manage licenses card title on review worker screen
  ///
  /// In he, this message translates to:
  /// **'🛠 ניהול משא'**
  String get manageLicensesCardTitle;

  /// No permission to manage this user message
  ///
  /// In he, this message translates to:
  /// **'אין הרשאה לניהול משתמש זה'**
  String get noPermissionForUser;

  /// New worker pending approval subtitle
  ///
  /// In he, this message translates to:
  /// **'עובד חדש ממתין לאישור'**
  String get newWorkerPendingApproval;

  /// Email label in approve worker info card
  ///
  /// In he, this message translates to:
  /// **'דוא\"ל'**
  String get approveEmailLabel;

  /// Approve worker confirmation dialog message
  ///
  /// In he, this message translates to:
  /// **'האם אתה בטוח שברצונך לאשר את העובד הזה?'**
  String get approveConfirmContent;

  /// Reject worker confirmation dialog message
  ///
  /// In he, this message translates to:
  /// **'העובד ישאר בהמתנה ויוכל להגיש בקשה שוב. האם לדחות?'**
  String get rejectConfirmContent;

  /// Role section title in edit licenses screen
  ///
  /// In he, this message translates to:
  /// **'תפקיד'**
  String get roleSectionTitle;

  /// Note that upgrading to manager role is for owners only
  ///
  /// In he, this message translates to:
  /// **'שדרוג לתפקיד מנהל מותר לבעלים בלבד'**
  String get managerRoleUpgradeNote;

  /// Hint text under departments section title
  ///
  /// In he, this message translates to:
  /// **'בחר את המחלקות בהן מורשה העובד לעבוד'**
  String get departmentsSectionHint;

  /// In-app notification title for role change
  ///
  /// In he, this message translates to:
  /// **'התפקיד שלך עודכן'**
  String get roleChangedTitle;

  /// In-app notification body for role change
  ///
  /// In he, this message translates to:
  /// **'תפקידך שונה מ{fromRole} ל{toRole}'**
  String roleChangedBody(String fromRole, String toRole);

  /// Search field hint in users screen
  ///
  /// In he, this message translates to:
  /// **'חיפוש לפי שם או תפקיד'**
  String get searchByNameOrRoleHint;

  /// Worker added to shift success snackbar
  ///
  /// In he, this message translates to:
  /// **'עובד נוסף למשמרת בהצלחה'**
  String get workerAddedToShift;

  /// Worker removed from shift snackbar
  ///
  /// In he, this message translates to:
  /// **'עובד הוסר מהמשמרת'**
  String get workerRemovedFromShift;

  /// No workers found empty state in users screen
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו עובדים'**
  String get noWorkersFound;

  /// Add N workers button label in draft mode
  ///
  /// In he, this message translates to:
  /// **'הוסף {count} עובדים'**
  String addWorkersCount(int count);

  /// Worker shifts list subtitle in shifts button screen
  ///
  /// In he, this message translates to:
  /// **'רשימת המשמרות של העובד'**
  String get workerShiftsListSubtitle;

  /// All filter option
  ///
  /// In he, this message translates to:
  /// **'הכל'**
  String get filterAll;

  /// Filter button: upcoming shifts
  ///
  /// In he, this message translates to:
  /// **'קרובות'**
  String get filterUpcoming;

  /// Filter button: past shifts
  ///
  /// In he, this message translates to:
  /// **'עבר'**
  String get filterPast;

  /// Filter button: today shifts
  ///
  /// In he, this message translates to:
  /// **'היום'**
  String get filterToday;

  /// Filter button: this week shifts
  ///
  /// In he, this message translates to:
  /// **'השבוע'**
  String get filterThisWeek;

  /// Shift note label with content
  ///
  /// In he, this message translates to:
  /// **'הערה: {note}'**
  String shiftNoteLabel(String note);

  /// Owner role short label for worker card badge
  ///
  /// In he, this message translates to:
  /// **'בעלים'**
  String get ownerRoleShort;

  /// Co-owner role short label for worker card badge
  ///
  /// In he, this message translates to:
  /// **'שותף'**
  String get coOwnerRoleShort;

  /// Newsfeed screen title
  ///
  /// In he, this message translates to:
  /// **'לוח מודעות'**
  String get newsfeedTitle;

  /// FAB label to create a new post
  ///
  /// In he, this message translates to:
  /// **'פוסט חדש'**
  String get newPostButton;

  /// Search field hint text in newsfeed
  ///
  /// In he, this message translates to:
  /// **'חיפוש פוסט...'**
  String get searchPostHint;

  /// Category filter: all posts
  ///
  /// In he, this message translates to:
  /// **'הכל'**
  String get categoryAll;

  /// Category filter: announcements
  ///
  /// In he, this message translates to:
  /// **'הודעות'**
  String get categoryAnnouncements;

  /// Category filter: updates
  ///
  /// In he, this message translates to:
  /// **'עדכונים'**
  String get categoryUpdates;

  /// Category filter: events
  ///
  /// In he, this message translates to:
  /// **'אירועים'**
  String get categoryEvents;

  /// Category filter: general
  ///
  /// In he, this message translates to:
  /// **'כללי'**
  String get categoryGeneral;

  /// Category badge label: announcement
  ///
  /// In he, this message translates to:
  /// **'הודעה'**
  String get categoryLabelAnnouncement;

  /// Category badge label: update
  ///
  /// In he, this message translates to:
  /// **'עדכון'**
  String get categoryLabelUpdate;

  /// Category badge label: event
  ///
  /// In he, this message translates to:
  /// **'אירוע'**
  String get categoryLabelEvent;

  /// Category badge label: general
  ///
  /// In he, this message translates to:
  /// **'כללי'**
  String get categoryLabelGeneral;

  /// Label shown on pinned posts
  ///
  /// In he, this message translates to:
  /// **'פוסט נעוץ'**
  String get pinnedPostLabel;

  /// Pin post menu action
  ///
  /// In he, this message translates to:
  /// **'נעץ פוסט'**
  String get pinPostAction;

  /// Unpin post menu action
  ///
  /// In he, this message translates to:
  /// **'בטל נעיצה'**
  String get unpinPostAction;

  /// Delete post confirmation dialog message
  ///
  /// In he, this message translates to:
  /// **'האם אתה בטוח שברצונך למחוק את הפוסט?\nפעולה זו לא ניתנת לביטול.'**
  String get deletePostMessage;

  /// Delete comment confirmation dialog message
  ///
  /// In he, this message translates to:
  /// **'האם אתה בטוח שברצונך למחוק את התגובה?'**
  String get deleteCommentMessage;

  /// Delete confirm button label
  ///
  /// In he, this message translates to:
  /// **'מחק'**
  String get deleteLabel;

  /// Success snackbar after post deletion
  ///
  /// In he, this message translates to:
  /// **'הפוסט נמחק בהצלחה'**
  String get postDeletedSuccess;

  /// Error snackbar when post deletion fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה במחיקת הפוסט: {error}'**
  String postDeleteError(String error);

  /// Success snackbar when post is pinned
  ///
  /// In he, this message translates to:
  /// **'הפוסט ננעץ'**
  String get postPinnedSuccess;

  /// Success snackbar when post is unpinned
  ///
  /// In he, this message translates to:
  /// **'הפוסט הוסר מהנעוצים'**
  String get postUnpinnedSuccess;

  /// Generic error snackbar with error details
  ///
  /// In he, this message translates to:
  /// **'שגיאה: {error}'**
  String errorPrefix(String error);

  /// Empty state title in newsfeed
  ///
  /// In he, this message translates to:
  /// **'אין פוסטים עדיין'**
  String get noPostsEmpty;

  /// Empty state hint for managers
  ///
  /// In he, this message translates to:
  /// **'לחץ על \"פוסט חדש\" כדי לפרסם את הפוסט הראשון'**
  String get noPostsManagerHint;

  /// Empty state hint for workers
  ///
  /// In he, this message translates to:
  /// **'המנהלים יפרסמו כאן עדכונים בקרוב'**
  String get noPostsWorkerHint;

  /// Empty state when search returns no results
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו פוסטים התואמים לחיפוש'**
  String get noPostsSearchEmpty;

  /// Empty state when category has no posts
  ///
  /// In he, this message translates to:
  /// **'אין פוסטים בקטגוריה זו'**
  String get noPostsCategoryEmpty;

  /// Error state title in newsfeed
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת הפוסטים'**
  String get feedLoadError;

  /// Error state hint to check connection
  ///
  /// In he, this message translates to:
  /// **'בדוק את החיבור לאינטרנט ונסה שוב'**
  String get checkConnectionHint;

  /// Default fallback user name
  ///
  /// In he, this message translates to:
  /// **'משתמש'**
  String get defaultUserName;

  /// Create post dialog header title
  ///
  /// In he, this message translates to:
  /// **'פוסט חדש'**
  String get createPostTitle;

  /// Create post dialog header subtitle
  ///
  /// In he, this message translates to:
  /// **'שתף עדכונים עם הצוות'**
  String get createPostSubtitle;

  /// Category section label in create post dialog
  ///
  /// In he, this message translates to:
  /// **'בחר קטגוריה'**
  String get selectCategoryLabel;

  /// Title field label in create post dialog
  ///
  /// In he, this message translates to:
  /// **'כותרת'**
  String get postTitleLabel;

  /// Validation error when title is empty
  ///
  /// In he, this message translates to:
  /// **'יש להזין כותרת'**
  String get postTitleRequired;

  /// Content field label in create post dialog
  ///
  /// In he, this message translates to:
  /// **'תוכן הפוסט'**
  String get postContentLabel;

  /// Validation error when content is empty
  ///
  /// In he, this message translates to:
  /// **'יש להזין תוכן'**
  String get postContentRequired;

  /// Media section label showing current and max count
  ///
  /// In he, this message translates to:
  /// **'מדיה ({count}/{max})'**
  String mediaLabel(int count, int max);

  /// Add media button label when no media selected
  ///
  /// In he, this message translates to:
  /// **'הוסף תמונות או סרטונים'**
  String get addMediaButton;

  /// Add more media button label when media already selected
  ///
  /// In he, this message translates to:
  /// **'הוסף עוד'**
  String get addMoreMediaButton;

  /// Media picker bottom sheet title
  ///
  /// In he, this message translates to:
  /// **'הוסף מדיה'**
  String get mediaPickerTitle;

  /// Media picker option: pick images from gallery
  ///
  /// In he, this message translates to:
  /// **'בחר תמונות'**
  String get pickImagesOption;

  /// Media picker option subtitle: pick from gallery
  ///
  /// In he, this message translates to:
  /// **'בחר תמונות מהגלריה'**
  String get pickImagesSubtitle;

  /// Media picker option: pick video from gallery
  ///
  /// In he, this message translates to:
  /// **'בחר סרטון'**
  String get pickVideoOption;

  /// Media picker option subtitle: pick video
  ///
  /// In he, this message translates to:
  /// **'בחר סרטון מהגלריה'**
  String get pickVideoSubtitle;

  /// Media picker option: take photo with camera
  ///
  /// In he, this message translates to:
  /// **'צלם תמונה'**
  String get takePhotoOption;

  /// Media picker option subtitle: open camera
  ///
  /// In he, this message translates to:
  /// **'פתח את המצלמה'**
  String get takePhotoSubtitle;

  /// Error when user tries to add more than max media
  ///
  /// In he, this message translates to:
  /// **'ניתן להעלות עד {max} קבצים'**
  String maxMediaError(int max);

  /// Video label shown on video thumbnails
  ///
  /// In he, this message translates to:
  /// **'וידאו'**
  String get videoLabel;

  /// Submit button in create post dialog
  ///
  /// In he, this message translates to:
  /// **'פרסם פוסט'**
  String get publishPostButton;

  /// Upload status: publishing post
  ///
  /// In he, this message translates to:
  /// **'מפרסם פוסט...'**
  String get publishingPostStatus;

  /// Upload status: preparing upload
  ///
  /// In he, this message translates to:
  /// **'מכין להעלאה...'**
  String get preparingUploadStatus;

  /// Success snackbar after post is published
  ///
  /// In he, this message translates to:
  /// **'הפוסט פורסם בהצלחה'**
  String get postPublishedSuccess;

  /// Error snackbar when post publishing fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בפרסום הפוסט: {error}'**
  String postPublishError(String error);

  /// Warning shown when user picks a .MOV video
  ///
  /// In he, this message translates to:
  /// **'סרטוני .MOV מאייפון עשויים להיות בפורמט Dolby Vision שלא נתמך בחלק מהמכשירים. מומלץ להשתמש ב-MP4.'**
  String get movWarningMessage;

  /// Post detail sheet header title
  ///
  /// In he, this message translates to:
  /// **'פרטי הפוסט'**
  String get postDetailTitle;

  /// Video thumbnail label in post detail
  ///
  /// In he, this message translates to:
  /// **'הקש לצפייה בסרטון'**
  String get tapToWatchVideo;

  /// Comments section header title
  ///
  /// In he, this message translates to:
  /// **'תגובות'**
  String get commentsTitle;

  /// Empty state hint in comments sheet
  ///
  /// In he, this message translates to:
  /// **'היה הראשון להגיב!'**
  String get beFirstToComment;

  /// Empty state hint in post detail comments
  ///
  /// In he, this message translates to:
  /// **'היה הראשון להגיב על הפוסט!'**
  String get beFirstToCommentOnPost;

  /// Comment input hint in post detail sheet
  ///
  /// In he, this message translates to:
  /// **'הוסף תגובה...'**
  String get addCommentHint;

  /// Comment input hint in comments sheet
  ///
  /// In he, this message translates to:
  /// **'כתוב תגובה...'**
  String get writeCommentHint;

  /// Success snackbar after comment added
  ///
  /// In he, this message translates to:
  /// **'התגובה נוספה'**
  String get commentAddedSuccess;

  /// Error snackbar when adding comment fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בהוספת תגובה'**
  String get commentAddError;

  /// Success snackbar after comment deleted
  ///
  /// In he, this message translates to:
  /// **'התגובה נמחקה'**
  String get commentDeletedSuccess;

  /// Error snackbar when deleting comment fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה במחיקת תגובה'**
  String get commentDeleteError;

  /// Success snackbar after comment edited
  ///
  /// In he, this message translates to:
  /// **'התגובה עודכנה'**
  String get commentUpdatedSuccess;

  /// Error snackbar when editing comment fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון תגובה'**
  String get commentUpdateError;

  /// Edit post sheet title
  ///
  /// In he, this message translates to:
  /// **'עריכת פוסט'**
  String get editPostTitle;

  /// Success snackbar after post edited
  ///
  /// In he, this message translates to:
  /// **'הפוסט עודכן'**
  String get postUpdatedSuccess;

  /// Error snackbar when editing post fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון הפוסט'**
  String get postUpdateError;

  /// Likers sheet header title
  ///
  /// In he, this message translates to:
  /// **'תגובות לפוסט'**
  String get likersTitle;

  /// Number of people who reacted to a post
  ///
  /// In he, this message translates to:
  /// **'{count} אנשים'**
  String likersCount(int count);

  /// Empty state title in likers sheet
  ///
  /// In he, this message translates to:
  /// **'עדיין אין לייקים'**
  String get noLikersEmpty;

  /// Empty state hint in likers sheet
  ///
  /// In he, this message translates to:
  /// **'היה הראשון לאהוב את הפוסט!'**
  String get beFirstToLike;

  /// Error message when likers fail to load
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת הנתונים'**
  String get likersLoadError;

  /// Manager role display name in likers sheet
  ///
  /// In he, this message translates to:
  /// **'מנהל'**
  String get roleManager;

  /// Worker role display name in likers sheet
  ///
  /// In he, this message translates to:
  /// **'עובד'**
  String get roleWorker;

  /// Admin role display name in likers sheet
  ///
  /// In he, this message translates to:
  /// **'מנהל מערכת'**
  String get roleAdmin;

  /// Video player error: unsupported format
  ///
  /// In he, this message translates to:
  /// **'פורמט סרטון לא נתמך'**
  String get videoFormatNotSupported;

  /// Video player error: failed to load
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת הסרטון'**
  String get videoLoadError;

  /// Video player format error detail message
  ///
  /// In he, this message translates to:
  /// **'הסרטון מקודד בפורמט Dolby Vision / HEVC שלא נתמך\nבמכשיר זה. נסה להעלות סרטון ב-H.264 (MP4 רגיל).'**
  String get videoFormatErrorDetail;

  /// Video player playback error detail message
  ///
  /// In he, this message translates to:
  /// **'אירעה שגיאה בהפעלת הסרטון.\nבדוק את החיבור ונסה שוב.'**
  String get videoPlaybackErrorDetail;

  /// Video player loading label
  ///
  /// In he, this message translates to:
  /// **'טוען סרטון...'**
  String get videoLoadingLabel;

  /// Empty state when search returns no posts
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו פוסטים התואמים לחיפוש'**
  String get noPostsMatchSearch;

  /// Empty state when selected category has no posts
  ///
  /// In he, this message translates to:
  /// **'אין פוסטים בקטגוריה זו'**
  String get noPostsInCategory;

  /// Empty state title when no posts exist
  ///
  /// In he, this message translates to:
  /// **'אין פוסטים עדיין'**
  String get noPostsYet;

  /// Error state title when posts fail to load
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת הפוסטים'**
  String get loadPostsError;

  /// Error snackbar when post deletion fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה במחיקת הפוסט: {error}'**
  String deletePostError(String error);

  /// Generic error message with details
  ///
  /// In he, this message translates to:
  /// **'שגיאה: {error}'**
  String genericError(String error);

  /// Task status chip: pending
  ///
  /// In he, this message translates to:
  /// **'ממתין'**
  String get taskStatusPending;

  /// Task status chip: in progress
  ///
  /// In he, this message translates to:
  /// **'בביצוע'**
  String get taskStatusInProgress;

  /// Task status chip: done
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get taskStatusDone;

  /// Task status: pending manager review
  ///
  /// In he, this message translates to:
  /// **'ממתין לאישור'**
  String get taskStatusPendingReview;

  /// Task priority: high
  ///
  /// In he, this message translates to:
  /// **'גבוהה'**
  String get taskPriorityHigh;

  /// Task priority: medium
  ///
  /// In he, this message translates to:
  /// **'בינונית'**
  String get taskPriorityMedium;

  /// Task priority: low
  ///
  /// In he, this message translates to:
  /// **'נמוכה'**
  String get taskPriorityLow;

  /// Empty state when no tasks exist
  ///
  /// In he, this message translates to:
  /// **'אין משימות'**
  String get noTasksEmpty;

  /// Empty state when no tasks for the selected day
  ///
  /// In he, this message translates to:
  /// **'אין משימות ליום זה'**
  String get noTasksForDay;

  /// Empty state for worker timeline with no tasks
  ///
  /// In he, this message translates to:
  /// **'אין משימות כרגע'**
  String get noTasksNow;

  /// Subtitle for empty task state
  ///
  /// In he, this message translates to:
  /// **'משימות חדשות יופיעו כאן'**
  String get newTasksWillAppear;

  /// Hint shown in empty task state for managers
  ///
  /// In he, this message translates to:
  /// **'השתמש בכפתור \'יצירת משימה\' כדי להוסיף אחת חדשה'**
  String get useCreateTaskButton;

  /// Task management screen title
  ///
  /// In he, this message translates to:
  /// **'ניהול משימות'**
  String get taskManagementTitle;

  /// All tasks screen title
  ///
  /// In he, this message translates to:
  /// **'כל המשימות'**
  String get allTasksTitle;

  /// All tasks screen subtitle
  ///
  /// In he, this message translates to:
  /// **'תצוגה כוללת לכל המשימות'**
  String get allTasksSubtitle;

  /// Worker task header title
  ///
  /// In he, this message translates to:
  /// **'המשימות שלי'**
  String get myTasksTitle;

  /// Tab label for tasks assigned to current user
  ///
  /// In he, this message translates to:
  /// **'המשימות שלי'**
  String get myTasksTabLabel;

  /// Tab label for tasks created by current user
  ///
  /// In he, this message translates to:
  /// **'משימות שיצרתי'**
  String get createdByMeTabLabel;

  /// Task details section title
  ///
  /// In he, this message translates to:
  /// **'פרטי המשימה'**
  String get taskDetailsTitle;

  /// Task description section label
  ///
  /// In he, this message translates to:
  /// **'תיאור'**
  String get taskDescriptionLabel;

  /// Task description section heading
  ///
  /// In he, this message translates to:
  /// **'תיאור המשימה'**
  String get taskDescriptionSectionTitle;

  /// Placeholder when task has no description
  ///
  /// In he, this message translates to:
  /// **'אין תיאור למשימה זו'**
  String get noTaskDescription;

  /// Task info section title in details screen
  ///
  /// In he, this message translates to:
  /// **'פרטים'**
  String get taskInfoSectionTitle;

  /// Task deadline field label
  ///
  /// In he, this message translates to:
  /// **'תאריך יעד'**
  String get taskDeadlineLabel;

  /// Task priority field label
  ///
  /// In he, this message translates to:
  /// **'עדיפות'**
  String get taskPriorityLabel;

  /// Task department field label
  ///
  /// In he, this message translates to:
  /// **'מחלקה'**
  String get taskDepartmentLabel;

  /// Task created-at field label
  ///
  /// In he, this message translates to:
  /// **'נוצרה'**
  String get taskCreatedAtLabel;

  /// Task assignees section label
  ///
  /// In he, this message translates to:
  /// **'עובדים'**
  String get taskAssigneesLabel;

  /// Assignees section label with count
  ///
  /// In he, this message translates to:
  /// **'עובדים ({count})'**
  String taskAssigneesCount(int count);

  /// Overview tab label in task details
  ///
  /// In he, this message translates to:
  /// **'סקירה'**
  String get taskOverviewTabLabel;

  /// Discussion tab label in task details
  ///
  /// In he, this message translates to:
  /// **'דיון'**
  String get taskDiscussionTabLabel;

  /// Edit task popup menu item
  ///
  /// In he, this message translates to:
  /// **'ערוך משימה'**
  String get editTaskMenuItem;

  /// Delete task popup menu item
  ///
  /// In he, this message translates to:
  /// **'מחק משימה'**
  String get deleteTaskMenuItem;

  /// Create task floating action button label
  ///
  /// In he, this message translates to:
  /// **'יצירת משימה'**
  String get createTaskButton;

  /// Delete task confirmation dialog title
  ///
  /// In he, this message translates to:
  /// **'מחיקת משימה'**
  String get deleteTaskTitle;

  /// Delete task confirmation message
  ///
  /// In he, this message translates to:
  /// **'למחוק את \"{title}\"?'**
  String deleteTaskConfirmation(String title);

  /// Delete button label in task dialogs
  ///
  /// In he, this message translates to:
  /// **'מחק'**
  String get deleteTaskButton;

  /// Snackbar shown after task deletion
  ///
  /// In he, this message translates to:
  /// **'המשימה \"{title}\" נמחקה'**
  String taskDeletedSnackbar(String title);

  /// Confirm delete dialog title
  ///
  /// In he, this message translates to:
  /// **'אישור מחיקה'**
  String get confirmDeleteTitle;

  /// Confirm delete task message in manager dashboard
  ///
  /// In he, this message translates to:
  /// **'האם אתה בטוח שברצונך למחוק את המשימה \'{title}\'?'**
  String confirmDeleteTaskMessage(String title);

  /// Overdue tasks section title
  ///
  /// In he, this message translates to:
  /// **'באיחור'**
  String get taskOverdueSection;

  /// Today tasks section title
  ///
  /// In he, this message translates to:
  /// **'להיום'**
  String get taskTodaySection;

  /// Upcoming tasks section title
  ///
  /// In he, this message translates to:
  /// **'הקרובות'**
  String get taskUpcomingSection;

  /// Completed tasks section title
  ///
  /// In he, this message translates to:
  /// **'הושלמו'**
  String get taskCompletedSection;

  /// Task overdue by N days
  ///
  /// In he, this message translates to:
  /// **'באיחור {days} {unit}'**
  String taskDeadlineOverdue(int days, String unit);

  /// Task due today with time
  ///
  /// In he, this message translates to:
  /// **'היום, {time}'**
  String taskDeadlineToday(String time);

  /// Task due tomorrow with time
  ///
  /// In he, this message translates to:
  /// **'מחר, {time}'**
  String taskDeadlineTomorrow(String time);

  /// Task due in N days
  ///
  /// In he, this message translates to:
  /// **'בעוד {days} ימים'**
  String taskDeadlineInDays(int days);

  /// Singular day unit
  ///
  /// In he, this message translates to:
  /// **'יום'**
  String get dayUnit;

  /// Plural days unit
  ///
  /// In he, this message translates to:
  /// **'ימים'**
  String get daysUnit;

  /// Today tasks progress in worker timeline header
  ///
  /// In he, this message translates to:
  /// **'{completed} מתוך {total} הושלמו היום'**
  String todayTasksProgress(int completed, int total);

  /// No tasks for today in progress header
  ///
  /// In he, this message translates to:
  /// **'אין משימות להיום'**
  String get noTasksToday;

  /// Task board header showing total and overdue counts
  ///
  /// In he, this message translates to:
  /// **'{count} משימות • {overdue} באיחור'**
  String taskCountOverdue(int count, int overdue);

  /// Banner shown when worker task is pending manager review
  ///
  /// In he, this message translates to:
  /// **'ממתין לאישור מנהל'**
  String get pendingManagerApproval;

  /// Label for list of workers pending approval
  ///
  /// In he, this message translates to:
  /// **'ממתינים לאישור:'**
  String get pendingApprovalLabel;

  /// Start task quick action button
  ///
  /// In he, this message translates to:
  /// **'התחל לעבוד'**
  String get startTaskButton;

  /// Start task button in worker task card
  ///
  /// In he, this message translates to:
  /// **'התחל משימה'**
  String get startTaskAction;

  /// Finish task button in worker task details
  ///
  /// In he, this message translates to:
  /// **'סיים משימה'**
  String get finishTaskButton;

  /// Submit for manager approval button
  ///
  /// In he, this message translates to:
  /// **'שלח לאישור מנהל'**
  String get submitForApprovalButton;

  /// Approve button in task board
  ///
  /// In he, this message translates to:
  /// **'אשר'**
  String get approveButton;

  /// Reject button in task board
  ///
  /// In he, this message translates to:
  /// **'דחה'**
  String get rejectButton;

  /// Snackbar shown after task approval
  ///
  /// In he, this message translates to:
  /// **'המשימה אושרה בהצלחה'**
  String get taskApprovedSnackbar;

  /// Snackbar shown after task rejection
  ///
  /// In he, this message translates to:
  /// **'המשימה הוחזרה לביצוע'**
  String get taskRejectedSnackbar;

  /// Start work action button in task details
  ///
  /// In he, this message translates to:
  /// **'להתחיל לעבוד'**
  String get startWorkButton;

  /// Send comment button
  ///
  /// In he, this message translates to:
  /// **'שלח תגובה'**
  String get sendCommentButton;

  /// Add comment hint text in task details
  ///
  /// In he, this message translates to:
  /// **'הוסף תגובה...'**
  String get addCommentHintTask;

  /// Write comment hint text in task discussion tab
  ///
  /// In he, this message translates to:
  /// **'כתוב תגובה...'**
  String get writeCommentHintTask;

  /// Error snackbar when comment submission fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בשליחת תגובה'**
  String get commentSendError;

  /// Attached files section title
  ///
  /// In he, this message translates to:
  /// **'קבצים מצורפים'**
  String get attachedFilesTitle;

  /// Default label for an attachment when name cannot be determined
  ///
  /// In he, this message translates to:
  /// **'קובץ מצורף'**
  String get attachedFileDefault;

  /// Snackbar when attachment cannot be opened
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לפתוח את הקובץ'**
  String get cannotOpenFile;

  /// Pending filter label
  ///
  /// In he, this message translates to:
  /// **'ממתין'**
  String get filterStatusPending;

  /// In-progress filter label
  ///
  /// In he, this message translates to:
  /// **'בביצוע'**
  String get filterStatusInProgress;

  /// Done filter label
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get filterStatusDone;

  /// Search task hint text
  ///
  /// In he, this message translates to:
  /// **'חיפוש משימה...'**
  String get searchTaskHint;

  /// Search task by name hint text in manager dashboard
  ///
  /// In he, this message translates to:
  /// **'חיפוש משימה לפי שם...'**
  String get searchTaskByNameHint;

  /// Error prefix with details in task list
  ///
  /// In he, this message translates to:
  /// **'שגיאה: {error}'**
  String taskErrorPrefix(String error);

  /// Task title field label
  ///
  /// In he, this message translates to:
  /// **'כותרת'**
  String get taskTitleLabel;

  /// Task title field hint
  ///
  /// In he, this message translates to:
  /// **'שם המשימה'**
  String get taskTitleHint;

  /// Task description field label
  ///
  /// In he, this message translates to:
  /// **'תיאור'**
  String get taskDescriptionFieldLabel;

  /// Task description field hint
  ///
  /// In he, this message translates to:
  /// **'תיאור מפורט'**
  String get taskDescriptionHint;

  /// Task description optional hint
  ///
  /// In he, this message translates to:
  /// **'תיאור מפורט (אופציונלי)'**
  String get taskDescriptionOptionalHint;

  /// Field required validation message
  ///
  /// In he, this message translates to:
  /// **'שדה חובה'**
  String get taskFieldRequired;

  /// Validation error when required fields are missing
  ///
  /// In he, this message translates to:
  /// **'יש למלא את כל השדות ולבחור עובדים'**
  String get taskFillAllFields;

  /// Date picker label in task edit
  ///
  /// In he, this message translates to:
  /// **'תאריך'**
  String get taskDateLabel;

  /// Time picker label in task edit/create
  ///
  /// In he, this message translates to:
  /// **'שעה'**
  String get taskTimeLabel;

  /// Select date placeholder
  ///
  /// In he, this message translates to:
  /// **'בחר תאריך'**
  String get taskSelectDate;

  /// Select time placeholder
  ///
  /// In he, this message translates to:
  /// **'בחר שעה'**
  String get taskSelectTime;

  /// Deadline section title in create/edit task
  ///
  /// In he, this message translates to:
  /// **'מועד יעד'**
  String get taskDeadlineSectionTitle;

  /// Deadline section hint in create task
  ///
  /// In he, this message translates to:
  /// **'הגדר תאריך ושעת סיום למשימה'**
  String get taskDeadlineHint;

  /// Assigned workers section title in edit task
  ///
  /// In he, this message translates to:
  /// **'עובדים משובצים'**
  String get taskWorkersSectionTitle;

  /// Assign workers step title in create task
  ///
  /// In he, this message translates to:
  /// **'שיבוץ עובדים'**
  String get taskAssignWorkersTitle;

  /// How many workers are selected
  ///
  /// In he, this message translates to:
  /// **'בחר {count} עובדים'**
  String taskSelectedWorkersCount(int count);

  /// Search worker hint in edit task
  ///
  /// In he, this message translates to:
  /// **'חיפוש עובד...'**
  String get taskSearchWorkerHint;

  /// Search worker by name or role hint
  ///
  /// In he, this message translates to:
  /// **'חיפוש לפי שם או תפקיד...'**
  String get taskSearchWorkerByNameHint;

  /// Summary step title in create task flow
  ///
  /// In he, this message translates to:
  /// **'סיכום ויצירה'**
  String get taskSummaryTitle;

  /// Summary step subtitle
  ///
  /// In he, this message translates to:
  /// **'בדוק את הפרטים לפני יצירת המשימה'**
  String get taskSummarySubtitle;

  /// Basic info step title in create/edit task
  ///
  /// In he, this message translates to:
  /// **'פרטי המשימה'**
  String get taskBasicInfoTitle;

  /// Basic info step subtitle
  ///
  /// In he, this message translates to:
  /// **'מלא את הפרטים הבסיסיים של המשימה'**
  String get taskBasicInfoSubtitle;

  /// Step indicator label: details
  ///
  /// In he, this message translates to:
  /// **'פרטים'**
  String get taskStepDetails;

  /// Step indicator label: workers
  ///
  /// In he, this message translates to:
  /// **'עובדים'**
  String get taskStepWorkers;

  /// Step indicator label: deadline
  ///
  /// In he, this message translates to:
  /// **'מועד'**
  String get taskStepDeadline;

  /// Step indicator label: summary
  ///
  /// In he, this message translates to:
  /// **'סיכום'**
  String get taskStepSummary;

  /// Workers label in review card
  ///
  /// In he, this message translates to:
  /// **'עובדים'**
  String get taskReviewWorkersLabel;

  /// Deadline label in review card
  ///
  /// In he, this message translates to:
  /// **'מועד יעד'**
  String get taskReviewDeadlineLabel;

  /// Create task submit button
  ///
  /// In he, this message translates to:
  /// **'צור משימה'**
  String get createTaskActionButton;

  /// Next step button in multi-step forms
  ///
  /// In he, this message translates to:
  /// **'המשך'**
  String get nextButton;

  /// Go back step button in multi-step forms
  ///
  /// In he, this message translates to:
  /// **'חזור'**
  String get backStepButton;

  /// Save changes button in edit task screen
  ///
  /// In he, this message translates to:
  /// **'שמור שינויים'**
  String get saveChangesTaskButton;

  /// Error when task creation fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה ביצירת המשימה'**
  String get taskCreateError;

  /// Error when task update fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון המשימה'**
  String get taskUpdateError;

  /// Activity log entry for task edit
  ///
  /// In he, this message translates to:
  /// **'המשימה עודכנה'**
  String get taskLogEdited;

  /// Fallback user name when name cannot be loaded
  ///
  /// In he, this message translates to:
  /// **'משתמש'**
  String get userFallbackName;

  /// Show less button to collapse list
  ///
  /// In he, this message translates to:
  /// **'הצג פחות'**
  String get showLessButton;

  /// Show all button to expand list
  ///
  /// In he, this message translates to:
  /// **'הצג הכל'**
  String get showAllButton;

  /// Validation: task title is required
  ///
  /// In he, this message translates to:
  /// **'נא להזין כותרת למשימה'**
  String get tasksTitleValidation;

  /// Validation: at least one worker must be selected
  ///
  /// In he, this message translates to:
  /// **'נא לבחור לפחות עובד אחד'**
  String get tasksWorkersValidation;

  /// Validation: deadline date and time are required
  ///
  /// In he, this message translates to:
  /// **'נא לבחור תאריך ושעה'**
  String get tasksDeadlineValidation;

  /// Error shown when current user ID is null
  ///
  /// In he, this message translates to:
  /// **'שגיאה בזיהוי המשתמש.'**
  String get userIdentificationError;

  /// Snackbar shown after task is returned to in-progress
  ///
  /// In he, this message translates to:
  /// **'המשימה הוחזרה לביצוע'**
  String get taskReturnedSnackbar;

  /// Task count summary with overdue count
  ///
  /// In he, this message translates to:
  /// **'{total} משימות • {overdue} באיחור'**
  String tasksOverdueCount(int total, int overdue);

  /// No shifts available empty state
  ///
  /// In he, this message translates to:
  /// **'אין משמרות זמינות כרגע'**
  String get noShiftsAvailableEmpty;

  /// Subtitle shown when no shifts are available yet
  ///
  /// In he, this message translates to:
  /// **'בקרוב יתווספו משמרות חדשות'**
  String get shiftsComingSoonSubtitle;

  /// No shifts for the selected day
  ///
  /// In he, this message translates to:
  /// **'אין משמרות ליום זה'**
  String get noShiftsForDay;

  /// Hint to select another day or wait
  ///
  /// In he, this message translates to:
  /// **'בחר יום אחר או המתן למשמרות חדשות'**
  String get selectOtherDayHint;

  /// Hint to reconnect when user identification fails
  ///
  /// In he, this message translates to:
  /// **'נסה להתחבר מחדש'**
  String get tryReconnectHint;

  /// Shift status: active
  ///
  /// In he, this message translates to:
  /// **'פעיל'**
  String get shiftStatusActive;

  /// Shift status: cancelled
  ///
  /// In he, this message translates to:
  /// **'בוטלה'**
  String get shiftStatusCancelled;

  /// Number of pending shift requests
  ///
  /// In he, this message translates to:
  /// **'{count} בקשות'**
  String pendingRequestsCount(int count);

  /// New shift floating action button label
  ///
  /// In he, this message translates to:
  /// **'משמרת חדשה'**
  String get newShiftFab;

  /// Manager shifts screen header title
  ///
  /// In he, this message translates to:
  /// **'ניהול משמרות'**
  String get managerShiftDashboardTitle;

  /// Snackbar shown when shift request is cancelled
  ///
  /// In he, this message translates to:
  /// **'הבקשה למשמרת בוטלה'**
  String get shiftRequestCancelledSnackbar;

  /// Title for shift conflict dialog
  ///
  /// In he, this message translates to:
  /// **'התנגשות משמרות'**
  String get shiftConflictTitle;

  /// Message shown when shift times conflict
  ///
  /// In he, this message translates to:
  /// **'כבר משובץ למשמרת בתאריך זה בשעות החופפות ({startTime}–{endTime}). האם להמשיך בכל זאת?'**
  String shiftConflictMessage(String startTime, String endTime);

  /// Button to proceed despite conflict
  ///
  /// In he, this message translates to:
  /// **'המשך בכל זאת'**
  String get proceedAnywayButton;

  /// Semantics label for cancel shift request button
  ///
  /// In he, this message translates to:
  /// **'בטל בקשה למשמרת'**
  String get cancelShiftRequestLabel;

  /// Semantics label for join shift button
  ///
  /// In he, this message translates to:
  /// **'הצטרף למשמרת'**
  String get joinShiftLabel;

  /// Join button text
  ///
  /// In he, this message translates to:
  /// **'הצטרף'**
  String get joinButton;

  /// Label shown when worker has worked this shift
  ///
  /// In he, this message translates to:
  /// **'עבדת'**
  String get shiftWorkedLabel;

  /// Label shown when shift has ended
  ///
  /// In he, this message translates to:
  /// **'הסתיים'**
  String get shiftEndedLabel;

  /// Label shown when worker is assigned to shift
  ///
  /// In he, this message translates to:
  /// **'משובץ'**
  String get shiftAssignedLabel;

  /// Label shown when shift is full
  ///
  /// In he, this message translates to:
  /// **'מלא'**
  String get shiftFullLabel;

  /// Chip shown when shift is cancelled
  ///
  /// In he, this message translates to:
  /// **'המשמרת בוטלה'**
  String get shiftCancelledChip;

  /// Chip shown when shift date has passed
  ///
  /// In he, this message translates to:
  /// **'עבר התאריך'**
  String get shiftOutdatedChip;

  /// Chip shown when worker is assigned to shift
  ///
  /// In he, this message translates to:
  /// **'אתה משובץ'**
  String get youAreAssignedChip;

  /// Chip shown when shift request is waiting for approval
  ///
  /// In he, this message translates to:
  /// **'ממתין לאישור'**
  String get waitingApprovalChip;

  /// Chip shown when shift is full
  ///
  /// In he, this message translates to:
  /// **'המשמרת מלאה'**
  String get shiftFullChip;

  /// Chip shown when shift is open for registration
  ///
  /// In he, this message translates to:
  /// **'פתוח להרשמה'**
  String get openForRegistrationChip;

  /// Section title for assigned workers
  ///
  /// In he, this message translates to:
  /// **'עובדים משובצים'**
  String get assignedWorkersSection;

  /// Empty state for assigned workers section
  ///
  /// In he, this message translates to:
  /// **'אין עובדים משובצים עדיין'**
  String get noAssignedWorkersYet;

  /// Messages section title
  ///
  /// In he, this message translates to:
  /// **'הודעות'**
  String get messagesSection;

  /// Loading messages placeholder
  ///
  /// In he, this message translates to:
  /// **'טוען הודעות...'**
  String get loadingMessages;

  /// Empty state for messages section
  ///
  /// In he, this message translates to:
  /// **'אין הודעות עדיין'**
  String get noMessagesYet;

  /// Create new shift screen title
  ///
  /// In he, this message translates to:
  /// **'יצירת משמרת חדשה'**
  String get createNewShiftTitle;

  /// Create shift screen subtitle
  ///
  /// In he, this message translates to:
  /// **'מלא את הפרטים ליצירת משמרת'**
  String get createShiftSubtitle;

  /// Shift detail row label: date
  ///
  /// In he, this message translates to:
  /// **'בתאריך'**
  String get dateLabel;

  /// Department section label
  ///
  /// In he, this message translates to:
  /// **'מחלקה'**
  String get departmentLabel;

  /// Start time button label
  ///
  /// In he, this message translates to:
  /// **'התחלה'**
  String get startTimeLabel;

  /// End time button label
  ///
  /// In he, this message translates to:
  /// **'סיום'**
  String get endTimeLabel;

  /// Maximum workers section label
  ///
  /// In he, this message translates to:
  /// **'מספר עובדים מקסימלי'**
  String get maxWorkersLabel;

  /// Weekly recurrence section label
  ///
  /// In he, this message translates to:
  /// **'חזרה שבועית'**
  String get weeklyRecurrenceLabel;

  /// Label shown when recurring shift is enabled
  ///
  /// In he, this message translates to:
  /// **'משמרת חוזרת כל שבוע'**
  String get shiftRepeatsWeekly;

  /// Label shown when recurring shift is disabled
  ///
  /// In he, this message translates to:
  /// **'צור משמרת חוזרת'**
  String get createRecurringShift;

  /// Number of weeks label in recurring shift
  ///
  /// In he, this message translates to:
  /// **'מספר שבועות:'**
  String get numberOfWeeksLabel;

  /// Shifts to be created preview label
  ///
  /// In he, this message translates to:
  /// **'משמרות שייווצרו:'**
  String get shiftsToBeCreatedLabel;

  /// Create shift button label
  ///
  /// In he, this message translates to:
  /// **'צור משמרת'**
  String get createShiftButton;

  /// Snackbar shown when multiple shifts are created
  ///
  /// In he, this message translates to:
  /// **'{count} משמרות נוצרו בהצלחה!'**
  String shiftsCreatedSuccess(int count);

  /// Snackbar shown when a shift is created
  ///
  /// In he, this message translates to:
  /// **'משמרת נוצרה בהצלחה!'**
  String get shiftCreatedSuccess;

  /// Error snackbar when shift creation fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה ביצירת משמרת: {error}'**
  String createShiftError(String error);

  /// Clear draft action label
  ///
  /// In he, this message translates to:
  /// **'נקה'**
  String get clearButton;

  /// Edit shift screen title
  ///
  /// In he, this message translates to:
  /// **'עריכת משמרת'**
  String get editShiftTitle;

  /// Header subtitle when there are unsaved changes
  ///
  /// In he, this message translates to:
  /// **'יש שינויים לא שמורים'**
  String get unsavedChangesHeaderSubtitle;

  /// Header subtitle prompting to update shift details
  ///
  /// In he, this message translates to:
  /// **'עדכן את פרטי המשמרת'**
  String get updateShiftDetailsSubtitle;

  /// Save changes dialog title
  ///
  /// In he, this message translates to:
  /// **'שמירת שינויים'**
  String get saveChangesDialogTitle;

  /// Label above list of changes in save dialog
  ///
  /// In he, this message translates to:
  /// **'השינויים הבאים יישמרו:'**
  String get followingChangesSavedLabel;

  /// Note that workers will be notified of changes
  ///
  /// In he, this message translates to:
  /// **'כל העובדים המשובצים והממתינים יקבלו התראה על השינויים'**
  String get workersNotifiedOfChanges;

  /// Snackbar shown when shift is updated successfully
  ///
  /// In he, this message translates to:
  /// **'המשמרת עודכנה בהצלחה!'**
  String get shiftUpdatedSuccess;

  /// Error snackbar when shift update fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בעדכון המשמרת: {error}'**
  String updateShiftError(String error);

  /// Continue editing button label
  ///
  /// In he, this message translates to:
  /// **'המשך לערוך'**
  String get continueEditingButton;

  /// Department label when changed
  ///
  /// In he, this message translates to:
  /// **'מחלקה (שונה)'**
  String get departmentChangedLabel;

  /// Hours label when changed
  ///
  /// In he, this message translates to:
  /// **'שעות (שונה)'**
  String get hoursChangedLabel;

  /// Max workers label when changed
  ///
  /// In he, this message translates to:
  /// **'מספר עובדים מקסימלי (שונה)'**
  String get maxWorkersChangedLabel;

  /// Badge label indicating a value has changed
  ///
  /// In he, this message translates to:
  /// **'שונה'**
  String get changedBadge;

  /// Warning when assigned workers exceed new max
  ///
  /// In he, this message translates to:
  /// **'יש כרגע {count} עובדים משובצים, יותר מהמקסימום החדש'**
  String tooManyWorkersWarning(int count);

  /// Status section label
  ///
  /// In he, this message translates to:
  /// **'סטטוס'**
  String get statusLabel;

  /// Status label when changed
  ///
  /// In he, this message translates to:
  /// **'סטטוס (שונה)'**
  String get statusChangedLabel;

  /// Shift status: cancelled (masculine form)
  ///
  /// In he, this message translates to:
  /// **'בוטל'**
  String get shiftStatusCancelledMasc;

  /// Shift status: completed
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get shiftStatusCompleted;

  /// Label shown when there are no changes to save
  ///
  /// In he, this message translates to:
  /// **'אין שינויים'**
  String get noChangesLabel;

  /// Week range label in manager week view
  ///
  /// In he, this message translates to:
  /// **'שבוע {start} - {end}'**
  String weekRangeLabel(String start, String end);

  /// My shifts screen title
  ///
  /// In he, this message translates to:
  /// **'המשמרות שלי'**
  String get myShiftsTitle;

  /// Tooltip for next week navigation button
  ///
  /// In he, this message translates to:
  /// **'שבוע הבא'**
  String get nextWeekTooltip;

  /// Tooltip for previous week navigation button
  ///
  /// In he, this message translates to:
  /// **'שבוע קודם'**
  String get prevWeekTooltip;

  /// Error message when shifts fail to load
  ///
  /// In he, this message translates to:
  /// **'שגיאה בטעינת המשמרות'**
  String get loadShiftsError;

  /// Today label on day timeline
  ///
  /// In he, this message translates to:
  /// **'היום'**
  String get todayLabel;

  /// Past label on day timeline
  ///
  /// In he, this message translates to:
  /// **'עבר'**
  String get pastLabel;

  /// No shifts for this day on timeline
  ///
  /// In he, this message translates to:
  /// **'אין משמרות'**
  String get noShiftsDay;

  /// Loading shifts placeholder
  ///
  /// In he, this message translates to:
  /// **'טוען משמרות...'**
  String get loadingShifts;

  /// Message shown when user is not logged in
  ///
  /// In he, this message translates to:
  /// **'יש להתחבר כדי לצפות במשמרות'**
  String get loginToViewShifts;

  /// Button to view full shift details
  ///
  /// In he, this message translates to:
  /// **'צפה בפרטי המשמרת'**
  String get viewShiftDetailsButton;

  /// Tab label for all shifts
  ///
  /// In he, this message translates to:
  /// **'כל המשמרות'**
  String get allShiftsTabLabel;

  /// Weekly schedule screen title
  ///
  /// In he, this message translates to:
  /// **'סידור עבודה שבועי'**
  String get weeklyScheduleTitle;

  /// No workers assigned empty state
  ///
  /// In he, this message translates to:
  /// **'לא שובצו עובדים'**
  String get noWorkersAssigned;

  /// No workers assigned for this shift
  ///
  /// In he, this message translates to:
  /// **'לא שובצו עובדים למשמרת זו'**
  String get noWorkersAssignedForShift;

  /// Manager role short label
  ///
  /// In he, this message translates to:
  /// **'מנהל'**
  String get managerRoleShort;

  /// Worker role short label
  ///
  /// In he, this message translates to:
  /// **'עובד'**
  String get workerRoleShort;

  /// No shifts this week empty state
  ///
  /// In he, this message translates to:
  /// **'אין משמרות השבוע'**
  String get noShiftsThisWeek;

  /// Not assigned to shifts this week message
  ///
  /// In he, this message translates to:
  /// **'לא שובצת למשמרות בשבוע זה'**
  String get notAssignedThisWeek;

  /// Changes saved successfully snackbar
  ///
  /// In he, this message translates to:
  /// **'השינויים נשמרו בהצלחה!'**
  String get changesSavedSuccess;

  /// Error snackbar when saving changes fails
  ///
  /// In he, this message translates to:
  /// **'שגיאה בשמירת השינויים: {error}'**
  String saveChangesError(String error);

  /// Unsaved changes dialog message with count
  ///
  /// In he, this message translates to:
  /// **'יש לך {count} שינויים שלא נשמרו. האם אתה בטוח שברצונך לצאת?'**
  String unsavedChangesCountMessage(int count);

  /// Cancel all pending changes button
  ///
  /// In he, this message translates to:
  /// **'בטל הכל'**
  String get cancelAllButton;

  /// Save changes button with count
  ///
  /// In he, this message translates to:
  /// **'שמור שינויים ({count})'**
  String saveChangesWithCount(int count);

  /// Workers label in shift details
  ///
  /// In he, this message translates to:
  /// **'עובדים'**
  String get workersLabel;

  /// Requests tab label
  ///
  /// In he, this message translates to:
  /// **'בקשות'**
  String get requestsTabLabel;

  /// Approved tab label
  ///
  /// In he, this message translates to:
  /// **'מאושרים'**
  String get approvedTabLabel;

  /// Messages tab label
  ///
  /// In he, this message translates to:
  /// **'הודעות'**
  String get messagesTabLabel;

  /// Details tab label
  ///
  /// In he, this message translates to:
  /// **'פרטים'**
  String get detailsTabLabel;

  /// No pending requests empty state
  ///
  /// In he, this message translates to:
  /// **'אין בקשות ממתינות'**
  String get noPendingRequests;

  /// New requests will appear here subtitle
  ///
  /// In he, this message translates to:
  /// **'בקשות חדשות יופיעו כאן'**
  String get newRequestsWillAppear;

  /// Label for pending approval action
  ///
  /// In he, this message translates to:
  /// **'יאושר'**
  String get willBeApprovedLabel;

  /// Label for pending rejection action
  ///
  /// In he, this message translates to:
  /// **'יידחה'**
  String get willBeRejectedLabel;

  /// Add workers button label
  ///
  /// In he, this message translates to:
  /// **'הוסף עובדים'**
  String get addWorkersButton;

  /// Empty state for assigned workers
  ///
  /// In he, this message translates to:
  /// **'אין עובדים משובצים'**
  String get noAssignedWorkersEmpty;

  /// Hint to click add workers button
  ///
  /// In he, this message translates to:
  /// **'לחץ על \"הוסף עובדים\" להוספה ידנית'**
  String get clickAddWorkersHint;

  /// Label for pending addition action
  ///
  /// In he, this message translates to:
  /// **'יתווסף'**
  String get willBeAddedLabel;

  /// Label for pending removal action
  ///
  /// In he, this message translates to:
  /// **'יוסר'**
  String get willBeRemovedLabel;

  /// Label for pending restore action
  ///
  /// In he, this message translates to:
  /// **'יוחזר'**
  String get willBeRestoredLabel;

  /// Send first message empty state
  ///
  /// In he, this message translates to:
  /// **'שלח הודעה ראשונה'**
  String get sendFirstMessage;

  /// Write message input hint
  ///
  /// In he, this message translates to:
  /// **'כתוב הודעה...'**
  String get writeMessageHint;

  /// Created by label in shift details
  ///
  /// In he, this message translates to:
  /// **'נוצר על ידי'**
  String get createdByLabel;

  /// Creation date label in shift details
  ///
  /// In he, this message translates to:
  /// **'תאריך יצירה'**
  String get creationDateLabel;

  /// Last updated by label in shift details
  ///
  /// In he, this message translates to:
  /// **'עודכן לאחרונה על ידי'**
  String get lastUpdatedByLabel;

  /// Shift manager label in shift details
  ///
  /// In he, this message translates to:
  /// **'אחראי משמרת'**
  String get shiftManagerLabel;

  /// Banner showing count of unsaved changes
  ///
  /// In he, this message translates to:
  /// **'{count} שינויים ממתינים לשמירה'**
  String pendingChangesBanner(int count);

  /// Change summary: workers will be approved
  ///
  /// In he, this message translates to:
  /// **'{count} עובדים יאושרו'**
  String workersWillBeApproved(int count);

  /// Change summary: requests will be rejected
  ///
  /// In he, this message translates to:
  /// **'{count} בקשות יידחו'**
  String requestsWillBeRejected(int count);

  /// Change summary: workers will be removed
  ///
  /// In he, this message translates to:
  /// **'{count} עובדים יוסרו'**
  String workersWillBeRemoved(int count);

  /// Change summary: workers will be restored to pending list
  ///
  /// In he, this message translates to:
  /// **'{count} עובדים יוחזרו לרשימת הממתינים'**
  String workersWillBeRestored(int count);

  /// Change summary: workers will be added
  ///
  /// In he, this message translates to:
  /// **'{count} עובדים יתווספו'**
  String workersWillBeAdded(int count);

  /// Comment count label shown in comments sheet header
  ///
  /// In he, this message translates to:
  /// **'{count} תגובות'**
  String commentsCountLabel(int count);

  /// Title of the edit comment bottom sheet
  ///
  /// In he, this message translates to:
  /// **'עריכת תגובה'**
  String get editCommentTitle;

  /// Hint text for the edit comment text field
  ///
  /// In he, this message translates to:
  /// **'ערוך את תגובתך...'**
  String get editCommentHint;

  /// Description for announcement post type
  ///
  /// In he, this message translates to:
  /// **'הודעות חשובות לכלל העובדים'**
  String get postTypeAnnouncementDesc;

  /// Description for update post type
  ///
  /// In he, this message translates to:
  /// **'עדכונים ושינויים'**
  String get postTypeUpdateDesc;

  /// Description for event post type
  ///
  /// In he, this message translates to:
  /// **'אירועים ופעילויות'**
  String get postTypeEventDesc;

  /// Description for general post type
  ///
  /// In he, this message translates to:
  /// **'מידע כללי'**
  String get postTypeGeneralDesc;

  /// Date range toggle button label
  ///
  /// In he, this message translates to:
  /// **'טווח תאריכים'**
  String get dateRangeButton;

  /// Placeholder for date range picker
  ///
  /// In he, this message translates to:
  /// **'בחר טווח תאריכים'**
  String get selectDateRange;

  /// Empty state when no attendance data for month
  ///
  /// In he, this message translates to:
  /// **'אין נתוני נוכחות לחודש זה'**
  String get noAttendanceDataMonth;

  /// Bar chart tooltip showing day number and hours
  ///
  /// In he, this message translates to:
  /// **'יום {day}\n{hours} שעות'**
  String chartTooltipDayHours(int day, String hours);

  /// Badge label for missing clock-out on attendance card
  ///
  /// In he, this message translates to:
  /// **'יציאה חסרה'**
  String get missingClockOutLabel;

  /// Duration badge showing hours and minutes
  ///
  /// In he, this message translates to:
  /// **'{hours}ש׳ {minutes}ד׳'**
  String durationHoursMinutes(int hours, int minutes);

  /// Clock-in time row label
  ///
  /// In he, this message translates to:
  /// **'כניסה: {time}'**
  String clockInPrefix(String time);

  /// Clock-out time row label
  ///
  /// In he, this message translates to:
  /// **'יציאה: {time}'**
  String clockOutPrefix(String time);

  /// Exporting progress label on PDF export button
  ///
  /// In he, this message translates to:
  /// **'מייצא...'**
  String get exportingLabel;

  /// Export to PDF button label
  ///
  /// In he, this message translates to:
  /// **'ייצוא PDF'**
  String get exportPdfButton;

  /// Empty state subtitle for missing clockout report
  ///
  /// In he, this message translates to:
  /// **'כל העובדים שמרו על יציאה תקינה בחודש זה'**
  String get allWorkersValidClockout;

  /// Empty state when no shifts for the selected month
  ///
  /// In he, this message translates to:
  /// **'אין משמרות לחודש זה'**
  String get noShiftsMonth;

  /// Shift count and filled slots text in department card
  ///
  /// In he, this message translates to:
  /// **'{count} משמרות · {filled}/{total} מקומות מלאים'**
  String shiftCountAndSlotsFormat(int count, int filled, int total);

  /// Bar chart tooltip for shift count per department
  ///
  /// In he, this message translates to:
  /// **'{count} משמרות'**
  String shiftCountTooltip(int count);

  /// Task distribution report screen title
  ///
  /// In he, this message translates to:
  /// **'התפלגות משימות'**
  String get taskDistributionTitle;

  /// Empty state when no tasks for the selected month
  ///
  /// In he, this message translates to:
  /// **'אין משימות לחודש זה'**
  String get noTasksMonth;

  /// Total tasks stat pill label
  ///
  /// In he, this message translates to:
  /// **'סה\"כ משימות'**
  String get totalTasksLabel;

  /// Workers with tasks stat pill label
  ///
  /// In he, this message translates to:
  /// **'עובדים עם משימות'**
  String get workersWithTasksLabel;

  /// Completion rate stat pill label
  ///
  /// In he, this message translates to:
  /// **'שיעור השלמה'**
  String get completionRateLabel;

  /// Completion rate by worker bar chart title
  ///
  /// In he, this message translates to:
  /// **'שיעור השלמה לפי עובד'**
  String get completionRateByWorkerTitle;

  /// Top ten workers caption shown next to chart title
  ///
  /// In he, this message translates to:
  /// **'(10 מובילים)'**
  String get topTenLabel;

  /// Worker details section title
  ///
  /// In he, this message translates to:
  /// **'פירוט עובדים'**
  String get workerDetailsTitle;

  /// Execution percentage label in pie chart center
  ///
  /// In he, this message translates to:
  /// **'ביצוע'**
  String get executionLabel;

  /// Status distribution pie chart title
  ///
  /// In he, this message translates to:
  /// **'התפלגות סטטוס'**
  String get statusDistributionTitle;

  /// Task details list section title
  ///
  /// In he, this message translates to:
  /// **'פירוט משימות'**
  String get taskDetailsListTitle;

  /// Task goal / due date row label
  ///
  /// In he, this message translates to:
  /// **'יעד: {date}'**
  String taskGoalPrefix(String date);

  /// Timeline row label: task submitted
  ///
  /// In he, this message translates to:
  /// **'הוגשה'**
  String get taskTimelineSubmitted;

  /// Timeline row label: task started
  ///
  /// In he, this message translates to:
  /// **'התחילה'**
  String get taskTimelineStarted;

  /// Timeline row label: task ended
  ///
  /// In he, this message translates to:
  /// **'הסתיימה'**
  String get taskTimelineEnded;

  /// Workers hours report screen title
  ///
  /// In he, this message translates to:
  /// **'שעות עבודה'**
  String get workersHoursTitle;

  /// Active workers stat pill label
  ///
  /// In he, this message translates to:
  /// **'עובדים פעילים'**
  String get activeWorkersLabel;

  /// Total hours stat pill label
  ///
  /// In he, this message translates to:
  /// **'סה״כ שעות'**
  String get totalHoursLabel;

  /// Average per worker stat pill label
  ///
  /// In he, this message translates to:
  /// **'ממוצע לעובד'**
  String get avgPerWorkerLabel;

  /// Hours by worker bar chart title
  ///
  /// In he, this message translates to:
  /// **'שעות לפי עובד'**
  String get hoursByWorkerTitle;

  /// Worker card subtitle showing days worked and average hours per day
  ///
  /// In he, this message translates to:
  /// **'{days} ימים · ממוצע {avg} ש׳/יום'**
  String workerDaysAndAvgFormat(int days, String avg);

  /// General reports tab label
  ///
  /// In he, this message translates to:
  /// **'דוחות כלליים'**
  String get generalReportsTabLabel;

  /// Personal reports tab subtitle
  ///
  /// In he, this message translates to:
  /// **'צפייה בנתוני נוכחות, משימות ומשמרות אישיים'**
  String get personalReportsSubtitle;

  /// Attendance report card description
  ///
  /// In he, this message translates to:
  /// **'שעות עבודה, ימי נוכחות וסיכום חודשי'**
  String get attendanceReportDescription;

  /// Task report card description
  ///
  /// In he, this message translates to:
  /// **'סטטוס משימות, התקדמות ואחוזי ביצוע'**
  String get taskReportDescription;

  /// Shift report card description
  ///
  /// In he, this message translates to:
  /// **'היסטוריית משמרות, אישורים והחלטות'**
  String get shiftReportDescription;

  /// General reports section heading
  ///
  /// In he, this message translates to:
  /// **'דוחות כלליים'**
  String get generalReportsTitle;

  /// General reports tab subtitle
  ///
  /// In he, this message translates to:
  /// **'נתונים מצטברים על כלל העובדים'**
  String get generalReportsSubtitle;

  /// Workers hours report card description
  ///
  /// In he, this message translates to:
  /// **'סיכום שעות עבודה חודשי לפי עובד'**
  String get workersHoursDescription;

  /// Task distribution report card description
  ///
  /// In he, this message translates to:
  /// **'משימות לפי עובד, אחוזי ביצוע ודירוג'**
  String get taskDistributionDescription;

  /// Shift coverage report card description
  ///
  /// In he, this message translates to:
  /// **'משמרות לפי מחלקה, אחוז מילוי ופירוט'**
  String get shiftCoverageDescription;

  /// Missing clockouts report card description
  ///
  /// In he, this message translates to:
  /// **'עובדים שלא שכחו לצאת לפי חודש'**
  String get missingClockoutsDescription;

  /// Worker reports screen heading with worker name
  ///
  /// In he, this message translates to:
  /// **'הדוחות של {name}'**
  String reportsOfWorker(String name);

  /// Worker reports screen subtitle
  ///
  /// In he, this message translates to:
  /// **'צפייה בנתוני נוכחות, משימות ומשמרות'**
  String get workerReportsSubtitle;

  /// Performance summary card title
  ///
  /// In he, this message translates to:
  /// **'סיכום ביצועים — החודש'**
  String get performanceSummaryTitle;

  /// Performance metric: hours this month
  ///
  /// In he, this message translates to:
  /// **'{hours} שעות'**
  String hoursWithValue(String hours);

  /// Performance metric: days this month
  ///
  /// In he, this message translates to:
  /// **'{days} ימים'**
  String daysWithValue(int days);

  /// Performance metric label: presence
  ///
  /// In he, this message translates to:
  /// **'נוכחות'**
  String get presenceLabel;

  /// Performance metric label: at work
  ///
  /// In he, this message translates to:
  /// **'בעבודה'**
  String get atWorkLabel;

  /// Performance metric label: tasks completed
  ///
  /// In he, this message translates to:
  /// **'משימות הושלמו'**
  String get tasksCompletedLabel;

  /// Pie chart legend for approved shifts
  ///
  /// In he, this message translates to:
  /// **'מאושר ({count})'**
  String shiftDecisionApproved(int count);

  /// Pie chart legend for rejected shifts
  ///
  /// In he, this message translates to:
  /// **'נדחה ({count})'**
  String shiftDecisionRejected(int count);

  /// Pie chart legend for other/pending shifts
  ///
  /// In he, this message translates to:
  /// **'אחר ({count})'**
  String shiftDecisionOther(int count);

  /// Show details expand button label
  ///
  /// In he, this message translates to:
  /// **'הצג פרטים'**
  String get showDetailsLabel;

  /// Hide details collapse button label
  ///
  /// In he, this message translates to:
  /// **'הסתר פרטים'**
  String get hideDetailsLabel;

  /// Shift detail row label: approved by
  ///
  /// In he, this message translates to:
  /// **'אושר ע״י'**
  String get approvedByLabel;

  /// Shift detail row label: role at time of assignment
  ///
  /// In he, this message translates to:
  /// **'תפקיד בעת השיבוץ'**
  String get roleAtAssignmentLabel;

  /// Shift detail row label: request time
  ///
  /// In he, this message translates to:
  /// **'זמן בקשה'**
  String get requestTimeLabel;

  /// Shift detail row label: removed by
  ///
  /// In he, this message translates to:
  /// **'הוסר ע״י'**
  String get removedByLabel;

  /// Shift detail row label: removal time
  ///
  /// In he, this message translates to:
  /// **'זמן הסרה'**
  String get removalTimeLabel;

  /// Shift detail row label: cancelled by
  ///
  /// In he, this message translates to:
  /// **'בוטל ע״י'**
  String get cancelledByLabel;

  /// Shift detail row label: cancellation time
  ///
  /// In he, this message translates to:
  /// **'זמן ביטול'**
  String get cancellationTimeLabel;

  /// Shift status: active (feminine)
  ///
  /// In he, this message translates to:
  /// **'פעילה'**
  String get shiftStatusActiveFem;

  /// Shift status: cancelled (feminine)
  ///
  /// In he, this message translates to:
  /// **'מבוטלת'**
  String get shiftStatusCancelledFem;

  /// Shift status: pending (feminine)
  ///
  /// In he, this message translates to:
  /// **'ממתינה'**
  String get shiftStatusPendingFem;

  /// Shift decision label: accepted
  ///
  /// In he, this message translates to:
  /// **'מאושר'**
  String get decisionAcceptedLabel;

  /// Shift decision label: rejected
  ///
  /// In he, this message translates to:
  /// **'נדחה'**
  String get decisionRejectedLabel;

  /// Shift decision label: removed
  ///
  /// In he, this message translates to:
  /// **'הוסר'**
  String get decisionRemovedLabel;

  /// Shift decision label: pending (empty decision)
  ///
  /// In he, this message translates to:
  /// **'ממתין'**
  String get decisionPendingLabel;

  /// Role label: shift manager
  ///
  /// In he, this message translates to:
  /// **'מנהל משמרת'**
  String get shiftManagerRoleLabel;

  /// Role label: department manager
  ///
  /// In he, this message translates to:
  /// **'מנהל מחלקה'**
  String get deptManagerRoleLabel;

  /// Hours value with abbreviated hours unit
  ///
  /// In he, this message translates to:
  /// **'{hours} ש׳'**
  String hoursAbbrFormat(String hours);

  /// Media picker option: pick photos from gallery
  ///
  /// In he, this message translates to:
  /// **'בחר תמונות'**
  String get pickPhotoOption;

  /// Media picker option subtitle: pick photos
  ///
  /// In he, this message translates to:
  /// **'בחר תמונות מהגלריה'**
  String get pickPhotoSubtitle;

  /// Admin role label in likers sheet
  ///
  /// In he, this message translates to:
  /// **'מנהל מערכת'**
  String get adminRoleLabel;

  /// Number of people who reacted to a post
  ///
  /// In he, this message translates to:
  /// **'{count} אנשים'**
  String reactorsPeopleCount(int count);

  /// Task department: general
  ///
  /// In he, this message translates to:
  /// **'כללי'**
  String get deptGeneral;

  /// Task department: paintball
  ///
  /// In he, this message translates to:
  /// **'פיינטבול'**
  String get deptPaintball;

  /// Task department: ropes park
  ///
  /// In he, this message translates to:
  /// **'פארק חבלים'**
  String get deptRopes;

  /// Task department: carting
  ///
  /// In he, this message translates to:
  /// **'קרטינג'**
  String get deptCarting;

  /// Task department: water park
  ///
  /// In he, this message translates to:
  /// **'פארק מים'**
  String get deptWaterPark;

  /// Task department: jimbory
  ///
  /// In he, this message translates to:
  /// **'ג\'ימבורי'**
  String get deptJimbory;

  /// Shift department: operations/general
  ///
  /// In he, this message translates to:
  /// **'תפעול'**
  String get deptOperations;

  /// Short upload preparation status shown on button
  ///
  /// In he, this message translates to:
  /// **'מכין...'**
  String get preparingUploadShort;

  /// Local notification title: 10h shift reminder
  ///
  /// In he, this message translates to:
  /// **'שכחת לצאת? ⏰'**
  String get clockReminder10hTitle;

  /// Local notification body: 10h shift reminder
  ///
  /// In he, this message translates to:
  /// **'אתה במשמרת כבר 10 שעות. זכור לדווח יציאה.'**
  String get clockReminder10hBody;

  /// Local notification title: 12h shift reminder
  ///
  /// In he, this message translates to:
  /// **'משמרת ארוכה מאוד! 🚨'**
  String get clockReminder12hTitle;

  /// Local notification body: 12h shift reminder
  ///
  /// In he, this message translates to:
  /// **'אתה במשמרת כבר 12 שעות. דווח יציאה בהקדם.'**
  String get clockReminder12hBody;

  /// Local notification title: task deadline reminder
  ///
  /// In he, this message translates to:
  /// **'תזכורת משימה ⏰'**
  String get taskDeadlineReminderTitle;

  /// Local notification body: task deadline reminder
  ///
  /// In he, this message translates to:
  /// **'{title} — נותרו פחות מ-24 שעות לסיום'**
  String taskDeadlineReminderBody(String title);

  /// Dashboard: N workers awaiting manager approval
  ///
  /// In he, this message translates to:
  /// **'{count} עובדים ממתינים לאישור'**
  String pendingApprovalCount(int count);

  /// Dashboard: N shifts today lack enough workers
  ///
  /// In he, this message translates to:
  /// **'{count} משמרות היום חסרות עובדים'**
  String understaffedShiftsCount(int count);

  /// Short abbreviation for hours
  ///
  /// In he, this message translates to:
  /// **'ש׳'**
  String get hoursAbbreviation;

  /// Short abbreviation for minutes
  ///
  /// In he, this message translates to:
  /// **'דק׳'**
  String get minutesAbbreviation;

  /// Worker stat: number of days worked this month
  ///
  /// In he, this message translates to:
  /// **'{count} ימים החודש'**
  String daysThisMonth(int count);

  /// Total hours label with value
  ///
  /// In he, this message translates to:
  /// **'{count} שעות'**
  String totalHoursCount(String count);

  /// Personal area: percentage of departments the worker is licensed for
  ///
  /// In he, this message translates to:
  /// **'{percent}% מהמחלקות פעילות'**
  String activeDepartmentsPercent(int percent);

  /// In-app notification title when system auto clocks out a worker
  ///
  /// In he, this message translates to:
  /// **'יציאה אוטומטית ממשמרת'**
  String get autoClockoutTitle;

  /// In-app notification body when system auto clocks out a worker
  ///
  /// In he, this message translates to:
  /// **'לא דיווחת יציאה לאחר 16 שעות – המערכת סיימה את המשמרת אוטומטית. פנה למנהל שלך.'**
  String get autoClockoutBody;

  /// Newsfeed post category: announcement
  ///
  /// In he, this message translates to:
  /// **'הודעה'**
  String get postCategoryAnnouncement;

  /// Newsfeed post category: update
  ///
  /// In he, this message translates to:
  /// **'עדכון'**
  String get postCategoryUpdate;

  /// Newsfeed post category: event
  ///
  /// In he, this message translates to:
  /// **'אירוע'**
  String get postCategoryEvent;

  /// Newsfeed post category: general
  ///
  /// In he, this message translates to:
  /// **'כללי'**
  String get postCategoryGeneral;

  /// Location permission rationale dialog title
  ///
  /// In he, this message translates to:
  /// **'גישה למיקום'**
  String get locationRationaleTitle;

  /// Location permission rationale dialog message
  ///
  /// In he, this message translates to:
  /// **'האפליקציה זקוקה לגישה למיקומך כדי לאפשר כניסה ויציאה מהעבודה בתחום הפארק.\n\nהמיקום משמש אך ורק לאימות נוכחות ואינו נשמר או משותף.'**
  String get locationRationaleMessage;

  /// Location permission rationale confirm button
  ///
  /// In he, this message translates to:
  /// **'אשר גישה'**
  String get locationRationaleConfirm;

  /// Location permission rationale cancel button
  ///
  /// In he, this message translates to:
  /// **'לא עכשיו'**
  String get locationRationaleCancel;

  /// Reason shown in OS biometric prompt when logging in
  ///
  /// In he, this message translates to:
  /// **'אמת את זהותך כדי להיכנס לאפליקציה'**
  String get biometricLoginReason;

  /// In-app notification title: worker approved for shift
  ///
  /// In he, this message translates to:
  /// **'בקשתך למשמרת אושרה'**
  String get shiftApprovedTitle;

  /// In-app notification body: worker approved for shift
  ///
  /// In he, this message translates to:
  /// **'אושרת למשמרת {date}, {startTime}–{endTime}'**
  String shiftApprovedBody(String date, String startTime, String endTime);

  /// In-app notification title: worker rejected from shift
  ///
  /// In he, this message translates to:
  /// **'בקשתך למשמרת נדחתה'**
  String get shiftRejectedTitle;

  /// In-app notification body: worker rejected from shift
  ///
  /// In he, this message translates to:
  /// **'בקשתך למשמרת {date}, {startTime}–{endTime} לא אושרה'**
  String shiftRejectedBody(String date, String startTime, String endTime);

  /// Upload progress: uploading video N of total
  ///
  /// In he, this message translates to:
  /// **'מעלה סרטון {current} מתוך {total}...'**
  String uploadingVideoProgress(int current, int total);

  /// Upload progress: uploading image N of total
  ///
  /// In he, this message translates to:
  /// **'מעלה תמונה {current} מתוך {total}...'**
  String uploadingImageProgress(int current, int total);

  /// Upload progress: uploading file N of total
  ///
  /// In he, this message translates to:
  /// **'מעלה {current} מתוך {total}...'**
  String uploadingProgress(int current, int total);

  /// Upload progress: generating video thumbnail
  ///
  /// In he, this message translates to:
  /// **'מייצר תמונה מקדימה...'**
  String get generatingThumbnailStatus;

  /// Upload progress: file N uploaded successfully
  ///
  /// In he, this message translates to:
  /// **'קובץ {current} הועלה'**
  String fileUploadedStatus(int current);
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
      <String>['ar', 'en', 'he'].contains(locale.languageCode);

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
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
