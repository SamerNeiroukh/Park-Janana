// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Park Janana';

  @override
  String get loginButton => 'Login';

  @override
  String get newWorkerButton => 'New worker?';

  @override
  String get logoutLabel => 'Logout';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get errorGeneral => 'An error occurred, please try again';

  @override
  String get retryButton => 'Try again';

  @override
  String get profileScreenTitle => 'Your Personal Area';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get shiftsTitle => 'Available Shifts';

  @override
  String get managerDashboardTitle => 'Shift Management Dashboard';

  @override
  String get newShiftButton => 'Create New Shift';

  @override
  String get profileUpdateSuccess => 'Profile picture updated successfully';

  @override
  String get shiftRequestSuccess => 'Your shift request was sent';

  @override
  String get shiftCancelSuccess => 'Shift request cancelled';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get closeButton => 'Close';

  @override
  String get noInternetError =>
      'Cannot connect to app servers. Please check your internet connection and try again.';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get appInitializationError => 'App initialization error';

  @override
  String get contactSupportMessage =>
      'If the problem persists, please contact support';

  @override
  String get offlineStatusText => 'No internet connection';

  @override
  String get onlineStatusText => 'Internet connection restored ✓';

  @override
  String get offlineModeLabel => 'Working offline';

  @override
  String get managerRole => 'Manager';

  @override
  String get messageUpdateError => 'Error updating message';

  @override
  String get messageDeletionError => 'Error deleting message';

  @override
  String get passwordRecoveryTitle => 'Password Recovery';

  @override
  String get enterEmailAddressPrompt => 'Please enter your email address';

  @override
  String get emailRequiredValidation => 'Please enter an email address';

  @override
  String get emailInvalidValidation => 'Please enter a valid email address';

  @override
  String get resetLinkSent => 'Password reset link sent to your email';

  @override
  String get resetLinkError => 'Error sending password reset link';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get backButton => 'Back';

  @override
  String get welcomeTitle => 'Hello, Welcome';

  @override
  String get loginCredentialsPrompt => 'Please enter your login credentials';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldHint => 'Enter your email address';

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get passwordFieldHint => 'Enter your password';

  @override
  String get passwordRequiredError => 'Please enter a password';

  @override
  String get passwordLengthError => 'Password must be at least 6 characters';

  @override
  String get orDividerText => 'or';

  @override
  String get biometricLoginTitle => 'Biometric Login';

  @override
  String get biometricSetupPrompt =>
      'Allow future login using fingerprint / face recognition?';

  @override
  String get enableBiometricButton => 'Enable';

  @override
  String get declineBiometricButton => 'No, thanks';

  @override
  String get biometricAuthFailed =>
      'Biometric authentication failed. Please try again.';

  @override
  String get noBiometricCredentials =>
      'No saved credentials found. Please login with email and password.';

  @override
  String get applicationRejectedTitle => 'Application Rejected';

  @override
  String get applicationRejectedMessage =>
      'Your approval request was rejected by management.\nYou can submit a new approval request.';

  @override
  String get reApplyButton => 'Re-apply';

  @override
  String get reApplySuccess =>
      'Request re-submitted. Management will update you on their decision.';

  @override
  String get registrationTitle => 'Register for Park Janana';

  @override
  String get registrationSubtitle =>
      'Fill in your details to submit a join request';

  @override
  String get nameRequiredValidation => 'Please enter your full name';

  @override
  String get nameInvalidCharsValidation =>
      'Please enter a name with valid characters only';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameHint => 'e.g. John Smith';

  @override
  String get phoneDigitsValidation =>
      'Phone number must contain exactly 10 digits';

  @override
  String get phoneFormatValidation => 'Israeli phone number must start with 05';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get phoneHint => '05XXXXXXXX';

  @override
  String get idDigitsValidation => 'ID number must contain exactly 9 digits';

  @override
  String get idCheckDigitValidation => 'ID number is not valid';

  @override
  String get idLabel => 'ID Number';

  @override
  String get idHint => '9 digits';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordMinLengthValidation =>
      'Password must be at least 6 characters';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get passwordMismatchValidation => 'Passwords do not match';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Enter your password again';

  @override
  String get personalDetailsSection => 'Personal Details';

  @override
  String get loginDetailsSection => 'Login Details';

  @override
  String validationErrorsBanner(int count, String noun) {
    return 'Fix $count $noun before submitting';
  }

  @override
  String get validationErrorSingular => 'error';

  @override
  String get validationErrorPlural => 'errors';

  @override
  String get registrationApprovalNotice =>
      'After submitting your request, management will approve your account and you can login to the app.';

  @override
  String get submitRegistrationButton => 'Submit Join Request';

  @override
  String get registrationSuccessTitle => 'Request Submitted Successfully!';

  @override
  String get registrationSuccessMessage =>
      'Park management will review your details and contact you as soon as possible.';

  @override
  String get registrationApprovalInfo =>
      'After management approval you will get access to the app and can login.';

  @override
  String get backToHomeButton => 'Back to Home';

  @override
  String get newWorkerWelcomeTitle => 'New Worker? Welcome!';

  @override
  String get registrationStepsSubtitle =>
      'Join the Park Janana team in a few simple steps';

  @override
  String get howItWorksSection => 'How does it work?';

  @override
  String get step1Title => 'Fill out registration form';

  @override
  String get step1Subtitle =>
      'Enter your personal details and choose a password';

  @override
  String get step2Title => 'Management approval';

  @override
  String get step2Subtitle =>
      'Park management will review your details and approve your account';

  @override
  String get step3Title => 'Join the team';

  @override
  String get step3Subtitle => 'After approval you can login and start working';

  @override
  String get welcomeSubtitle => 'Welcome';

  @override
  String get shiftsNavLabel => 'Shifts';

  @override
  String get weeklyScheduleNavLabel => 'Work Schedule';

  @override
  String get tasksNavLabel => 'Tasks';

  @override
  String get reportsNavLabel => 'Reports';

  @override
  String get newsfeedNavLabel => 'Bulletin Board';

  @override
  String get manageWorkersNavLabel => 'Manage Workers';

  @override
  String get weeklySchedulingNavLabel => 'Weekly Schedule';

  @override
  String get dashboardNavLabel => 'Dashboard';

  @override
  String get totalTeamLabel => 'Total Team';

  @override
  String get monthlyHoursLabel => 'Monthly Hours';

  @override
  String get openTasksLabel => 'Open Tasks';

  @override
  String get presentTodayLabel => 'Present Today';

  @override
  String get createShiftAction => 'Create Shift';

  @override
  String get createTaskAction => 'Create Task';

  @override
  String get publishPostAction => 'Publish Post';

  @override
  String get hoursReportAction => 'Hours Report';

  @override
  String get workersTabLabel => 'Workers';

  @override
  String get managersTabLabel => 'Managers';

  @override
  String get todayTabLabel => 'Today';

  @override
  String get thisWeekTabLabel => 'This Week';

  @override
  String get openTasksTabLabel => 'Open';

  @override
  String get urgentTasksTabLabel => 'Urgent';

  @override
  String get cropImageTitle => 'Crop Image';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully';

  @override
  String uploadError(String error) {
    return 'Error: $error';
  }

  @override
  String get takePhotoAction => 'Take Photo';

  @override
  String get takePhrotoSubtitle => 'Use the camera';

  @override
  String get chooseFromGalleryAction => 'Choose from Gallery';

  @override
  String get uploadFromGallerySubtitle => 'Upload from your photos';

  @override
  String get noDataFound => 'No data found';

  @override
  String get authorizedDepartmentsLabel => 'Authorized Departments';

  @override
  String get departmentPermissionsSection => 'Department Permissions';

  @override
  String get workerRoleLabel => 'Worker';

  @override
  String get ownerRoleLabel => 'Owner';

  @override
  String get coOwnerRoleLabel => 'Co-owner';

  @override
  String get attendanceSaved => 'Attendance saved successfully';

  @override
  String get attendanceSaveError => 'Error saving attendance';

  @override
  String get endShiftDialogTitle => 'End Shift';

  @override
  String get recordCheckoutConfirmation =>
      'Record checkout now for this shift?';

  @override
  String get endShiftButton => 'End Shift';

  @override
  String get checkoutRecordedReminder =>
      'Checkout time recorded — remember to save';

  @override
  String get recordUpdatedReminder => 'Record updated — remember to save';

  @override
  String get recordAddedReminder => 'Record added — remember to save';

  @override
  String recordDeleted(int recordNumber) {
    return 'Record #$recordNumber deleted';
  }

  @override
  String get undoButton => 'Undo';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get stayButton => 'Stay';

  @override
  String get exitWithoutSavingButton => 'Exit Without Saving';

  @override
  String get workDaysLabel => 'Work Days';

  @override
  String get hoursLabel => 'Hours';

  @override
  String get hoursShortLabel => 'hrs';

  @override
  String get recordsLabel => 'Records';

  @override
  String get missingCheckoutLabel => 'Missing Checkout';

  @override
  String get addRecordButton => 'Add Record';

  @override
  String get checkInFieldLabel => 'Check In';

  @override
  String get checkOutFieldLabel => 'Check Out';

  @override
  String attendanceReportError(String error) {
    return 'Attendance report error: $error';
  }

  @override
  String get outsideParkBoundsMessage =>
      'You are not within the park boundaries';

  @override
  String get draftRestoredSnackbar => 'Draft restored';

  @override
  String get clearDraftAction => 'Clear';

  @override
  String get taskTitleRequiredValidation => 'Please enter a task title';

  @override
  String get selectAtLeastOneWorkerValidation =>
      'Please select at least one worker';

  @override
  String get selectDeadlineValidation => 'Please select a date and time';

  @override
  String get noCommentsEmpty => 'No comments yet';

  @override
  String get callDialogTitle => 'Outgoing Call';

  @override
  String callConfirmation(String name, String phone) {
    return 'Call $name?\n$phone';
  }

  @override
  String dialFailed(String phone) {
    return 'Cannot dial $phone';
  }

  @override
  String get noPendingWorkersEmpty => 'No workers waiting for approval';

  @override
  String get callTooltip => 'Call';

  @override
  String get noActiveWorkersEmpty => 'No active workers in the system';

  @override
  String get workerApproved => 'Worker approved successfully';

  @override
  String get applicationRejectedSnackbar =>
      'Application rejected. Worker has been notified.';

  @override
  String get approveWorkerButton => 'Approve Worker';

  @override
  String get approveWorkerTitle => 'Approve Worker';

  @override
  String get rejectApplicationButton => 'Reject Application';

  @override
  String get rejectApplicationTitle => 'Reject Application';

  @override
  String get showShiftsButton => 'Show Shifts';

  @override
  String get assignTaskButton => 'Assign Task';

  @override
  String get viewPerformanceButton => 'View Performance';

  @override
  String get correctAttendanceButton => 'Correct Attendance';

  @override
  String get managePermissionsButton => 'Manage Permissions & Role';

  @override
  String get revokeApprovalButton => 'Revoke Worker Approval';

  @override
  String get revokeApprovalTitle => 'Revoke Worker Approval';

  @override
  String get revokeApprovalMessage =>
      'Worker will be moved back to the pending approval list. This action can be undone.';

  @override
  String get approvalRevoked => 'Worker approval revoked';

  @override
  String get licensesUpdated => 'Permissions updated successfully';

  @override
  String get saveLicensesError => 'Error saving data';

  @override
  String get attendanceReportTitle => 'Attendance Report';

  @override
  String get daysLabel => 'Days';

  @override
  String get averagePerDayLabel => 'Avg/Day';

  @override
  String get hoursPerDayChartTitle => 'Work Hours by Day';

  @override
  String get attendanceDetailsTitle => 'Attendance Details';

  @override
  String get shiftReportTitle => 'Shift Report';

  @override
  String get totalLabel => 'Total';

  @override
  String get approvedLabel => 'Approved';

  @override
  String get rejectedOtherLabel => 'Rejected/Other';

  @override
  String get decisionsDistributionTitle => 'Decision Distribution';

  @override
  String get shiftsDetailsTitle => 'Shift Details';

  @override
  String get shiftCoverageTitle => 'Shift Coverage';

  @override
  String get totalShiftsLabel => 'Total Shifts';

  @override
  String get staffingRateLabel => 'Staffing Rate';

  @override
  String get activeDepartmentsLabel => 'Active Departments';

  @override
  String get shiftsByDepartmentTitle => 'Shifts by Department';

  @override
  String get departmentDetailsTitle => 'Department Details';

  @override
  String get missingCheckoutsTitle => 'Missing Checkouts';

  @override
  String get noMissingCheckoutsEmpty => 'No missing checkouts';

  @override
  String get detailsByWorkerTitle => 'Details by Worker';

  @override
  String get myReportsTitle => 'My Reports';

  @override
  String get taskReportCard => 'Task Report';

  @override
  String get selectPhotosAction => 'Select Photos';

  @override
  String get selectPhotosFromGallery => 'Select photos from gallery';

  @override
  String get selectVideoAction => 'Select Video';

  @override
  String get selectVideoFromGallery => 'Select video from gallery';

  @override
  String get openCameraSubtitle => 'Open the camera';

  @override
  String get postTitleHint => 'Enter post title...';

  @override
  String get postContentHint => 'What do you want to share?';

  @override
  String get deleteCommentTitle => 'Delete Comment';

  @override
  String get deleteCommentConfirmation =>
      'Are you sure you want to delete this comment?';

  @override
  String get deletePostTitle => 'Delete Post';

  @override
  String get deletePostConfirmation =>
      'Are you sure you want to delete this post?\nThis action cannot be undone.';

  @override
  String get editPostAction => 'Edit Post';

  @override
  String get deletePostAction => 'Delete Post';

  @override
  String get editingPostTitle => 'Editing Post';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllAsReadButton => 'Mark all as read';

  @override
  String get loadNotificationsError => 'Error loading notifications';

  @override
  String get openShiftError => 'Error opening shift';

  @override
  String get openTaskError => 'Error opening task';

  @override
  String get noNotificationsEmpty => 'No notifications';

  @override
  String get newNotificationsWillAppear => 'New notifications will appear here';

  @override
  String get cannotOpenLink => 'Cannot open link';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get biometricMethodsSubtitle => 'Fingerprint / Face Recognition';

  @override
  String get pushNotificationsTitle => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle =>
      'Receive updates about shifts and tasks';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get crashReportsTitle => 'Send Crash Reports';

  @override
  String get crashReportsSubtitle => 'Helps us improve app stability';

  @override
  String get appVersionTitle => 'App Version';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Irreversible action — all data will be deleted';

  @override
  String get passwordChanged => 'Password updated successfully';

  @override
  String get biometricAuthFailedSnackbar => 'Biometric authentication failed';

  @override
  String get enableBiometricError => 'Error enabling biometric login';

  @override
  String get enableBiometricTitle => 'Enable Biometric Login';

  @override
  String get permanentDeletionTitle => 'Permanent Deletion';

  @override
  String get optionsTooltip => 'Options';

  @override
  String get settingsMenu => 'Settings';

  @override
  String get noButton => 'No';

  @override
  String get yesButton => 'Yes';

  @override
  String get longPressHint => 'Long press';

  @override
  String get weatherLabel => 'Weather';

  @override
  String get loadDataError => 'Cannot load data. Check connection or index.';

  @override
  String get noShiftsEmpty => 'No shifts to display';

  @override
  String shiftHoursFormat(String startTime, String endTime) {
    return 'Hours: $startTime - $endTime';
  }

  @override
  String departmentPrefix(String department) {
    return 'Department: $department';
  }

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Are you sure you want to exit?';

  @override
  String get noAttendanceRecords => 'No attendance records for this month';

  @override
  String get addManualRecordHint =>
      'Add a manual record or select another month';

  @override
  String get missingLabel => 'Missing';

  @override
  String get activeLabel => 'Active';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get editAttendanceRecordTitle => 'Edit Attendance Record';

  @override
  String get locationPermissionTitle => 'Location Access Required';

  @override
  String get locationPermissionMessage =>
      'To report clock-in or clock-out, location services must be enabled on your device.';

  @override
  String get enableLocationButton => 'Enable Location';

  @override
  String get clockInOutsideParkMessage =>
      'You are trying to clock in outside the permitted area. Do you want to continue anyway?';

  @override
  String get clockOutOutsideParkMessage =>
      'You are trying to clock out outside the permitted area. Do you want to continue anyway?';

  @override
  String get longPressToEndShift => 'Long press to end shift';

  @override
  String get longPressToStartShift => 'Long press to start shift';

  @override
  String clockedInSince(String time) {
    return 'Since $time';
  }

  @override
  String datePrefix(String date) {
    return 'Date: $date';
  }

  @override
  String clockInTimePrefix(String time) {
    return 'Clock-in: $time';
  }

  @override
  String clockOutTimePrefix(String time) {
    return 'Clock-out: $time';
  }

  @override
  String workDurationLabel(int hours, int minutes) {
    return 'Duration: ${hours}h ${minutes}m';
  }

  @override
  String get greetingNight => 'Good night,';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get motivationalMsg1 => 'You are an important part of our team 💪';

  @override
  String get motivationalMsg2 =>
      'Every shift is an opportunity to make an impact ✨';

  @override
  String get motivationalMsg3 => 'Keep smiling – it\'s contagious 😄';

  @override
  String get thisMonthLabel => 'This Month';

  @override
  String get nowLabel => 'Now';

  @override
  String minutesAgoLabel(int n) {
    return '$n min ago';
  }

  @override
  String hoursAgoLabel(int n) {
    return '$n hr ago';
  }

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String daysAgoLabel(int n) {
    return '$n days ago';
  }

  @override
  String get latestUpdateLabel => 'Latest Update';

  @override
  String get readMoreLabel => 'Read more';

  @override
  String get whatIsImportantNow => 'What matters now';

  @override
  String get allUpToDate => 'All up to date — no urgent items';

  @override
  String get shiftChangesWaiting => 'Shift changes pending';

  @override
  String get tasksWaitingApproval => 'Tasks awaiting approval';

  @override
  String get newPostsInBoard => 'New posts on the bulletin board';

  @override
  String get newUpdatesInBoard => 'New updates on the bulletin board';

  @override
  String get newBusinessActivity => 'New business activity to review';

  @override
  String get newShiftsAssigned => 'New shifts assigned to you';

  @override
  String get openTasksWaiting => 'Open tasks waiting for you';

  @override
  String get clickToResetClockOut => 'Tap to reset clock-out';

  @override
  String get clickToRegisterClockIn => 'Tap to register clock-in';

  @override
  String get completedLabel => 'Completed';

  @override
  String get presentNowLabel => 'Present Now';

  @override
  String get noWorkersConnected => 'No workers currently connected';

  @override
  String get topWorkersThisMonth => 'Top Workers This Month';

  @override
  String get workHoursThisMonth => 'Work Hours — This Month';

  @override
  String averageHoursPerWorker(String hours) {
    return 'Average $hours hours per worker';
  }

  @override
  String get ownerDashboardTitle => 'Owner Dashboard';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get quickActionsLabel => 'Quick Actions';

  @override
  String get staffLabel => 'Staff';

  @override
  String staffCountSummary(int count) {
    return 'Total $count team members • Tap to manage';
  }

  @override
  String get employeeManagementSystem => 'Employee Management System';

  @override
  String get myProfileTitle => 'My Profile';

  @override
  String get gpsUnavailableTitle => 'Cannot Verify Location';

  @override
  String get gpsUnavailableMessage =>
      'Location service is unavailable or GPS permissions were not granted. Do you want to continue anyway?';

  @override
  String get searchingLocationLabel => 'Locating...';

  @override
  String get networkErrorLoadMessage =>
      'Unable to load data.\nCheck your connection and try again.';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get permissionsCoverageLabel => 'Permissions Coverage';

  @override
  String get noActivePermissions => 'No active permissions';

  @override
  String get updateProfilePictureTitle => 'Update Profile Picture';

  @override
  String get chooseImageSourceTitle => 'Choose image source';

  @override
  String get setAsProfilePictureConfirm =>
      'Set this image as your profile picture?';

  @override
  String get ctaOpenButton => 'Open';

  @override
  String get clickForWeeklySchedule => 'Tap for weekly schedule';

  @override
  String get clickForManageWorkers => 'Tap to manage workers';

  @override
  String get daysWorkedLabel => 'Days Worked';

  @override
  String get hoursWorkedLabel => 'Hours Worked';

  @override
  String clockInFromLabel(String clockIn, String duration) {
    return 'From $clockIn · $duration';
  }

  @override
  String get accountSectionHeader => 'Account';

  @override
  String get languageSectionHeader => 'Language';

  @override
  String get languageSubtitle => 'Choose the interface language';

  @override
  String get notificationsSectionHeader => 'Notifications';

  @override
  String get infoSectionHeader => 'Information';

  @override
  String get signOutSectionHeader => 'Sign Out';

  @override
  String get dangerZoneSectionHeader => 'Danger Zone';

  @override
  String get requiresRecentLoginError =>
      'Please re-login before changing the password';

  @override
  String get updatePasswordError => 'Error updating password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get passwordRequiredValidator => 'Please enter a password';

  @override
  String get updatePasswordButton => 'Update Password';

  @override
  String get biometricEnableDescription =>
      'Enter your current password to enable fingerprint / face login.';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get biometricVerifyReason =>
      'Verify your identity to enable biometric login';

  @override
  String get activateBiometricButton => 'Enable Biometric Login';

  @override
  String get permanentDeletionMessage =>
      'This action is completely irreversible.\nAll your personal data will be permanently deleted.';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get wrongPasswordError => 'Wrong password. Please try again.';

  @override
  String get requiresRecentLoginDeleteError =>
      'Re-login required before deleting the account';

  @override
  String get deleteAccountError => 'Error deleting account. Please try again.';

  @override
  String get deleteAccountWarning =>
      'This will permanently delete all your personal data and cannot be undone.\nPlease enter your password to confirm.';

  @override
  String get deleteMyAccountButton => 'Delete My Account Permanently';

  @override
  String get newBadgeLabel => 'New';

  @override
  String get newWorkersTabLabel => 'New Workers';

  @override
  String get activeWorkersTabLabel => 'Active Workers';

  @override
  String get searchWorkerHint => 'Search worker by name...';

  @override
  String get noSearchResultsEmpty => 'No results found';

  @override
  String workersMissingClockOutBanner(int count, String workers) {
    return '$count $workers with missing clock-out this month';
  }

  @override
  String get workerLabelSingular => 'worker';

  @override
  String get workerLabelPlural => 'workers';

  @override
  String get missingClockOutWarning => 'Missing clock-out — tap to fix';

  @override
  String get workerSubtitleInPark => 'Worker at Park Janana';

  @override
  String get workerEmailInfoLabel => 'Email';

  @override
  String get workerPhoneInfoLabel => 'Phone';

  @override
  String get workerDetailsCardTitle => '🧾 Worker Details';

  @override
  String get adminActionsCardTitle => '🧭 Manager Actions';

  @override
  String get manageLicensesCardTitle => '🛠 Manage Licenses';

  @override
  String get noPermissionForUser => 'No permission to manage this user';

  @override
  String get newWorkerPendingApproval => 'New worker pending approval';

  @override
  String get approveEmailLabel => 'Email';

  @override
  String get approveConfirmContent =>
      'Are you sure you want to approve this worker?';

  @override
  String get rejectConfirmContent =>
      'The worker will remain on hold and can reapply. Reject?';

  @override
  String get roleSectionTitle => 'Role';

  @override
  String get managerRoleUpgradeNote =>
      'Upgrading to manager role is for owners only';

  @override
  String get departmentsSectionHint =>
      'Select the departments this worker is authorized to work in';

  @override
  String get roleChangedTitle => 'Your role has been updated';

  @override
  String roleChangedBody(String fromRole, String toRole) {
    return 'Your role was changed from $fromRole to $toRole';
  }

  @override
  String get searchByNameOrRoleHint => 'Search by name or role';

  @override
  String get workerAddedToShift => 'Worker added to shift successfully';

  @override
  String get workerRemovedFromShift => 'Worker removed from shift';

  @override
  String get noWorkersFound => 'No workers found';

  @override
  String addWorkersCount(int count) {
    return 'Add $count workers';
  }

  @override
  String get workerShiftsListSubtitle => 'Worker\'s shift list';

  @override
  String get filterAll => 'All';

  @override
  String get filterUpcoming => 'Upcoming';

  @override
  String get filterPast => 'Past';

  @override
  String get filterToday => 'Today';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String shiftNoteLabel(String note) {
    return 'Note: $note';
  }

  @override
  String get ownerRoleShort => 'Owner';

  @override
  String get coOwnerRoleShort => 'Partner';

  @override
  String get newsfeedTitle => 'Notice Board';

  @override
  String get newPostButton => 'New Post';

  @override
  String get searchPostHint => 'Search post...';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryAnnouncements => 'Announcements';

  @override
  String get categoryUpdates => 'Updates';

  @override
  String get categoryEvents => 'Events';

  @override
  String get categoryGeneral => 'General';

  @override
  String get categoryLabelAnnouncement => 'Announcement';

  @override
  String get categoryLabelUpdate => 'Update';

  @override
  String get categoryLabelEvent => 'Event';

  @override
  String get categoryLabelGeneral => 'General';

  @override
  String get pinnedPostLabel => 'Pinned Post';

  @override
  String get pinPostAction => 'Pin Post';

  @override
  String get unpinPostAction => 'Unpin';

  @override
  String get deletePostMessage =>
      'Are you sure you want to delete this post?\nThis action cannot be undone.';

  @override
  String get deleteCommentMessage =>
      'Are you sure you want to delete this comment?';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get postDeletedSuccess => 'Post deleted successfully';

  @override
  String postDeleteError(String error) {
    return 'Error deleting post: $error';
  }

  @override
  String get postPinnedSuccess => 'Post pinned';

  @override
  String get postUnpinnedSuccess => 'Post unpinned';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get noPostsEmpty => 'No posts yet';

  @override
  String get noPostsManagerHint => 'Tap \"New Post\" to publish the first post';

  @override
  String get noPostsWorkerHint => 'Managers will post updates here soon';

  @override
  String get noPostsSearchEmpty => 'No posts found matching your search';

  @override
  String get noPostsCategoryEmpty => 'No posts in this category';

  @override
  String get feedLoadError => 'Error loading posts';

  @override
  String get checkConnectionHint =>
      'Check your internet connection and try again';

  @override
  String get defaultUserName => 'User';

  @override
  String get createPostTitle => 'New Post';

  @override
  String get createPostSubtitle => 'Share updates with your team';

  @override
  String get selectCategoryLabel => 'Select a category';

  @override
  String get postTitleLabel => 'Title';

  @override
  String get postTitleRequired => 'Please enter a title';

  @override
  String get postContentLabel => 'Post Content';

  @override
  String get postContentRequired => 'Please enter content';

  @override
  String mediaLabel(int count, int max) {
    return 'Media ($count/$max)';
  }

  @override
  String get addMediaButton => 'Add photos or videos';

  @override
  String get addMoreMediaButton => 'Add more';

  @override
  String get mediaPickerTitle => 'Add Media';

  @override
  String get pickImagesOption => 'Choose Photos';

  @override
  String get pickImagesSubtitle => 'Select photos from gallery';

  @override
  String get pickVideoOption => 'Choose Video';

  @override
  String get pickVideoSubtitle => 'Select video from gallery';

  @override
  String get takePhotoOption => 'Take Photo';

  @override
  String get takePhotoSubtitle => 'Open camera';

  @override
  String maxMediaError(int max) {
    return 'You can upload up to $max files';
  }

  @override
  String get videoLabel => 'Video';

  @override
  String get publishPostButton => 'Publish Post';

  @override
  String get publishingPostStatus => 'Publishing post...';

  @override
  String get preparingUploadStatus => 'Preparing upload...';

  @override
  String get postPublishedSuccess => 'Post published successfully';

  @override
  String postPublishError(String error) {
    return 'Error publishing post: $error';
  }

  @override
  String get movWarningMessage =>
      'iPhone .MOV videos may use Dolby Vision format unsupported on some devices. Consider uploading MP4.';

  @override
  String get postDetailTitle => 'Post Details';

  @override
  String get tapToWatchVideo => 'Tap to watch video';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get beFirstToComment => 'Be the first to comment!';

  @override
  String get beFirstToCommentOnPost => 'Be the first to comment on this post!';

  @override
  String get addCommentHint => 'Add a comment...';

  @override
  String get writeCommentHint => 'Write a comment...';

  @override
  String get commentAddedSuccess => 'Comment added';

  @override
  String get commentAddError => 'Error adding comment';

  @override
  String get commentDeletedSuccess => 'Comment deleted';

  @override
  String get commentDeleteError => 'Error deleting comment';

  @override
  String get commentUpdatedSuccess => 'Comment updated';

  @override
  String get commentUpdateError => 'Error updating comment';

  @override
  String get editPostTitle => 'Edit Post';

  @override
  String get postUpdatedSuccess => 'Post updated';

  @override
  String get postUpdateError => 'Error updating post';

  @override
  String get likersTitle => 'Post Reactions';

  @override
  String likersCount(int count) {
    return '$count people';
  }

  @override
  String get noLikersEmpty => 'No likes yet';

  @override
  String get beFirstToLike => 'Be the first to like this post!';

  @override
  String get likersLoadError => 'Error loading data';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleWorker => 'Worker';

  @override
  String get roleAdmin => 'System Admin';

  @override
  String get videoFormatNotSupported => 'Video format not supported';

  @override
  String get videoLoadError => 'Error loading video';

  @override
  String get videoFormatErrorDetail =>
      'The video is encoded in Dolby Vision / HEVC format not supported\non this device. Try uploading an H.264 video (standard MP4).';

  @override
  String get videoPlaybackErrorDetail =>
      'An error occurred playing the video.\nCheck your connection and try again.';

  @override
  String get videoLoadingLabel => 'Loading video...';

  @override
  String get noPostsMatchSearch => 'No posts match your search';

  @override
  String get noPostsInCategory => 'No posts in this category';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get loadPostsError => 'Error loading posts';

  @override
  String deletePostError(String error) {
    return 'Error deleting post: $error';
  }

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In Progress';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get taskStatusPendingReview => 'Pending Approval';

  @override
  String get taskPriorityHigh => 'High';

  @override
  String get taskPriorityMedium => 'Medium';

  @override
  String get taskPriorityLow => 'Low';

  @override
  String get noTasksEmpty => 'No tasks';

  @override
  String get noTasksForDay => 'No tasks for this day';

  @override
  String get noTasksNow => 'No tasks right now';

  @override
  String get newTasksWillAppear => 'New tasks will appear here';

  @override
  String get useCreateTaskButton =>
      'Use the \'Create Task\' button to add a new one';

  @override
  String get taskManagementTitle => 'Task Management';

  @override
  String get allTasksTitle => 'All Tasks';

  @override
  String get allTasksSubtitle => 'Overview of all tasks';

  @override
  String get myTasksTitle => 'My Tasks';

  @override
  String get myTasksTabLabel => 'My Tasks';

  @override
  String get createdByMeTabLabel => 'Tasks I Created';

  @override
  String get taskDetailsTitle => 'Task Details';

  @override
  String get taskDescriptionLabel => 'Description';

  @override
  String get taskDescriptionSectionTitle => 'Task Description';

  @override
  String get noTaskDescription => 'No description for this task';

  @override
  String get taskInfoSectionTitle => 'Details';

  @override
  String get taskDeadlineLabel => 'Due Date';

  @override
  String get taskPriorityLabel => 'Priority';

  @override
  String get taskDepartmentLabel => 'Department';

  @override
  String get taskCreatedAtLabel => 'Created';

  @override
  String get taskAssigneesLabel => 'Workers';

  @override
  String taskAssigneesCount(int count) {
    return 'Workers ($count)';
  }

  @override
  String get taskOverviewTabLabel => 'Overview';

  @override
  String get taskDiscussionTabLabel => 'Discussion';

  @override
  String get editTaskMenuItem => 'Edit Task';

  @override
  String get deleteTaskMenuItem => 'Delete Task';

  @override
  String get createTaskButton => 'Create Task';

  @override
  String get deleteTaskTitle => 'Delete Task';

  @override
  String deleteTaskConfirmation(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deleteTaskButton => 'Delete';

  @override
  String taskDeletedSnackbar(String title) {
    return 'Task \"$title\" deleted';
  }

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String confirmDeleteTaskMessage(String title) {
    return 'Are you sure you want to delete the task \'$title\'?';
  }

  @override
  String get taskOverdueSection => 'Overdue';

  @override
  String get taskTodaySection => 'Today';

  @override
  String get taskUpcomingSection => 'Upcoming';

  @override
  String get taskCompletedSection => 'Completed';

  @override
  String taskDeadlineOverdue(int days, String unit) {
    return 'Overdue $days $unit';
  }

  @override
  String taskDeadlineToday(String time) {
    return 'Today, $time';
  }

  @override
  String taskDeadlineTomorrow(String time) {
    return 'Tomorrow, $time';
  }

  @override
  String taskDeadlineInDays(int days) {
    return 'In $days days';
  }

  @override
  String get dayUnit => 'day';

  @override
  String get daysUnit => 'days';

  @override
  String todayTasksProgress(int completed, int total) {
    return '$completed of $total completed today';
  }

  @override
  String get noTasksToday => 'No tasks for today';

  @override
  String taskCountOverdue(int count, int overdue) {
    return '$count tasks • $overdue overdue';
  }

  @override
  String get pendingManagerApproval => 'Pending manager approval';

  @override
  String get pendingApprovalLabel => 'Waiting for approval:';

  @override
  String get startTaskButton => 'Start Working';

  @override
  String get startTaskAction => 'Start Task';

  @override
  String get finishTaskButton => 'Finish Task';

  @override
  String get submitForApprovalButton => 'Submit for Manager Approval';

  @override
  String get approveButton => 'Approve';

  @override
  String get rejectButton => 'Reject';

  @override
  String get taskApprovedSnackbar => 'Task approved successfully';

  @override
  String get taskRejectedSnackbar => 'Task returned to in-progress';

  @override
  String get startWorkButton => 'Start Working';

  @override
  String get sendCommentButton => 'Send Comment';

  @override
  String get addCommentHintTask => 'Add a comment...';

  @override
  String get writeCommentHintTask => 'Write a comment...';

  @override
  String get commentSendError => 'Error sending comment';

  @override
  String get attachedFilesTitle => 'Attached Files';

  @override
  String get attachedFileDefault => 'Attachment';

  @override
  String get cannotOpenFile => 'Cannot open the file';

  @override
  String get filterStatusPending => 'Pending';

  @override
  String get filterStatusInProgress => 'In Progress';

  @override
  String get filterStatusDone => 'Done';

  @override
  String get searchTaskHint => 'Search task...';

  @override
  String get searchTaskByNameHint => 'Search task by name...';

  @override
  String taskErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get taskTitleLabel => 'Title';

  @override
  String get taskTitleHint => 'Task name';

  @override
  String get taskDescriptionFieldLabel => 'Description';

  @override
  String get taskDescriptionHint => 'Detailed description';

  @override
  String get taskDescriptionOptionalHint => 'Detailed description (optional)';

  @override
  String get taskFieldRequired => 'Required field';

  @override
  String get taskFillAllFields =>
      'Please fill in all fields and select workers';

  @override
  String get taskDateLabel => 'Date';

  @override
  String get taskTimeLabel => 'Time';

  @override
  String get taskSelectDate => 'Select date';

  @override
  String get taskSelectTime => 'Select time';

  @override
  String get taskDeadlineSectionTitle => 'Deadline';

  @override
  String get taskDeadlineHint => 'Set a due date and time for the task';

  @override
  String get taskWorkersSectionTitle => 'Assigned Workers';

  @override
  String get taskAssignWorkersTitle => 'Assign Workers';

  @override
  String taskSelectedWorkersCount(int count) {
    return 'Select $count workers';
  }

  @override
  String get taskSearchWorkerHint => 'Search worker...';

  @override
  String get taskSearchWorkerByNameHint => 'Search by name or role...';

  @override
  String get taskSummaryTitle => 'Summary & Create';

  @override
  String get taskSummarySubtitle => 'Review details before creating the task';

  @override
  String get taskBasicInfoTitle => 'Task Details';

  @override
  String get taskBasicInfoSubtitle => 'Fill in the basic details of the task';

  @override
  String get taskStepDetails => 'Details';

  @override
  String get taskStepWorkers => 'Workers';

  @override
  String get taskStepDeadline => 'Deadline';

  @override
  String get taskStepSummary => 'Summary';

  @override
  String get taskReviewWorkersLabel => 'Workers';

  @override
  String get taskReviewDeadlineLabel => 'Due Date';

  @override
  String get createTaskActionButton => 'Create Task';

  @override
  String get nextButton => 'Next';

  @override
  String get backStepButton => 'Back';

  @override
  String get saveChangesTaskButton => 'Save Changes';

  @override
  String get taskCreateError => 'Error creating task';

  @override
  String get taskUpdateError => 'Error updating task';

  @override
  String get taskLogEdited => 'Task updated';

  @override
  String get userFallbackName => 'User';

  @override
  String get showLessButton => 'Show less';

  @override
  String get showAllButton => 'Show all';

  @override
  String get tasksTitleValidation => 'Please enter a task title';

  @override
  String get tasksWorkersValidation => 'Please select at least one worker';

  @override
  String get tasksDeadlineValidation => 'Please select a date and time';

  @override
  String get userIdentificationError => 'Error identifying user.';

  @override
  String get taskReturnedSnackbar => 'Task returned to in-progress';

  @override
  String tasksOverdueCount(int total, int overdue) {
    return '$total tasks • $overdue overdue';
  }

  @override
  String get noShiftsAvailableEmpty => 'No shifts available right now';

  @override
  String get shiftsComingSoonSubtitle => 'New shifts will be added soon';

  @override
  String get noShiftsForDay => 'No shifts for this day';

  @override
  String get selectOtherDayHint => 'Select another day or wait for new shifts';

  @override
  String get tryReconnectHint => 'Try reconnecting';

  @override
  String get shiftStatusActive => 'Active';

  @override
  String get shiftStatusCancelled => 'Cancelled';

  @override
  String pendingRequestsCount(int count) {
    return '$count requests';
  }

  @override
  String get newShiftFab => 'New Shift';

  @override
  String get managerShiftDashboardTitle => 'Shift Management';

  @override
  String get shiftRequestCancelledSnackbar => 'Shift request cancelled';

  @override
  String get shiftConflictTitle => 'Shift Conflict';

  @override
  String shiftConflictMessage(String startTime, String endTime) {
    return 'Already assigned to a shift on this date with overlapping hours ($startTime–$endTime). Continue anyway?';
  }

  @override
  String get proceedAnywayButton => 'Continue Anyway';

  @override
  String get cancelShiftRequestLabel => 'Cancel shift request';

  @override
  String get joinShiftLabel => 'Join shift';

  @override
  String get joinButton => 'Join';

  @override
  String get shiftWorkedLabel => 'Worked';

  @override
  String get shiftEndedLabel => 'Ended';

  @override
  String get shiftAssignedLabel => 'Assigned';

  @override
  String get shiftFullLabel => 'Full';

  @override
  String get shiftCancelledChip => 'Shift Cancelled';

  @override
  String get shiftOutdatedChip => 'Date Passed';

  @override
  String get youAreAssignedChip => 'You are assigned';

  @override
  String get waitingApprovalChip => 'Waiting Approval';

  @override
  String get shiftFullChip => 'Shift Full';

  @override
  String get openForRegistrationChip => 'Open for Registration';

  @override
  String get assignedWorkersSection => 'Assigned Workers';

  @override
  String get noAssignedWorkersYet => 'No assigned workers yet';

  @override
  String get messagesSection => 'Messages';

  @override
  String get loadingMessages => 'Loading messages...';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get createNewShiftTitle => 'Create New Shift';

  @override
  String get createShiftSubtitle => 'Fill in the details to create a shift';

  @override
  String get dateLabel => 'Date';

  @override
  String get departmentLabel => 'Department';

  @override
  String get startTimeLabel => 'Start';

  @override
  String get endTimeLabel => 'End';

  @override
  String get maxWorkersLabel => 'Maximum Workers';

  @override
  String get weeklyRecurrenceLabel => 'Weekly Recurrence';

  @override
  String get shiftRepeatsWeekly => 'Shift repeats every week';

  @override
  String get createRecurringShift => 'Create recurring shift';

  @override
  String get numberOfWeeksLabel => 'Number of weeks:';

  @override
  String get shiftsToBeCreatedLabel => 'Shifts to be created:';

  @override
  String get createShiftButton => 'Create Shift';

  @override
  String shiftsCreatedSuccess(int count) {
    return '$count shifts created successfully!';
  }

  @override
  String get shiftCreatedSuccess => 'Shift created successfully!';

  @override
  String createShiftError(String error) {
    return 'Error creating shift: $error';
  }

  @override
  String get clearButton => 'Clear';

  @override
  String get editShiftTitle => 'Edit Shift';

  @override
  String get unsavedChangesHeaderSubtitle => 'There are unsaved changes';

  @override
  String get updateShiftDetailsSubtitle => 'Update shift details';

  @override
  String get saveChangesDialogTitle => 'Save Changes';

  @override
  String get followingChangesSavedLabel =>
      'The following changes will be saved:';

  @override
  String get workersNotifiedOfChanges =>
      'All assigned and pending workers will be notified of the changes';

  @override
  String get shiftUpdatedSuccess => 'Shift updated successfully!';

  @override
  String updateShiftError(String error) {
    return 'Error updating shift: $error';
  }

  @override
  String get continueEditingButton => 'Continue Editing';

  @override
  String get departmentChangedLabel => 'Department (changed)';

  @override
  String get hoursChangedLabel => 'Hours (changed)';

  @override
  String get maxWorkersChangedLabel => 'Maximum Workers (changed)';

  @override
  String get changedBadge => 'Changed';

  @override
  String tooManyWorkersWarning(int count) {
    return 'There are currently $count assigned workers, more than the new maximum';
  }

  @override
  String get statusLabel => 'Status';

  @override
  String get statusChangedLabel => 'Status (changed)';

  @override
  String get shiftStatusCancelledMasc => 'Cancelled';

  @override
  String get shiftStatusCompleted => 'Completed';

  @override
  String get noChangesLabel => 'No Changes';

  @override
  String weekRangeLabel(String start, String end) {
    return 'Week $start - $end';
  }

  @override
  String get myShiftsTitle => 'My Shifts';

  @override
  String get nextWeekTooltip => 'Next week';

  @override
  String get prevWeekTooltip => 'Previous week';

  @override
  String get loadShiftsError => 'Error loading shifts';

  @override
  String get todayLabel => 'Today';

  @override
  String get pastLabel => 'Past';

  @override
  String get noShiftsDay => 'No shifts';

  @override
  String get loadingShifts => 'Loading shifts...';

  @override
  String get loginToViewShifts => 'Please log in to view shifts';

  @override
  String get viewShiftDetailsButton => 'View Shift Details';

  @override
  String get allShiftsTabLabel => 'All Shifts';

  @override
  String get weeklyScheduleTitle => 'Weekly Work Schedule';

  @override
  String get noWorkersAssigned => 'No workers assigned';

  @override
  String get noWorkersAssignedForShift => 'No workers assigned for this shift';

  @override
  String get managerRoleShort => 'Manager';

  @override
  String get workerRoleShort => 'Worker';

  @override
  String get noShiftsThisWeek => 'No shifts this week';

  @override
  String get notAssignedThisWeek => 'You are not assigned to shifts this week';

  @override
  String get changesSavedSuccess => 'Changes saved successfully!';

  @override
  String saveChangesError(String error) {
    return 'Error saving changes: $error';
  }

  @override
  String unsavedChangesCountMessage(int count) {
    return 'You have $count unsaved changes. Are you sure you want to exit?';
  }

  @override
  String get cancelAllButton => 'Cancel All';

  @override
  String saveChangesWithCount(int count) {
    return 'Save Changes ($count)';
  }

  @override
  String get workersLabel => 'Workers';

  @override
  String get requestsTabLabel => 'Requests';

  @override
  String get approvedTabLabel => 'Approved';

  @override
  String get messagesTabLabel => 'Messages';

  @override
  String get detailsTabLabel => 'Details';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get newRequestsWillAppear => 'New requests will appear here';

  @override
  String get willBeApprovedLabel => 'Will be approved';

  @override
  String get willBeRejectedLabel => 'Will be rejected';

  @override
  String get addWorkersButton => 'Add Workers';

  @override
  String get noAssignedWorkersEmpty => 'No assigned workers';

  @override
  String get clickAddWorkersHint => 'Click \"Add Workers\" to add manually';

  @override
  String get willBeAddedLabel => 'Will be added';

  @override
  String get willBeRemovedLabel => 'Will be removed';

  @override
  String get willBeRestoredLabel => 'Will be restored';

  @override
  String get sendFirstMessage => 'Send first message';

  @override
  String get writeMessageHint => 'Write a message...';

  @override
  String get createdByLabel => 'Created by';

  @override
  String get creationDateLabel => 'Creation date';

  @override
  String get lastUpdatedByLabel => 'Last updated by';

  @override
  String get shiftManagerLabel => 'Shift manager';

  @override
  String pendingChangesBanner(int count) {
    return '$count changes pending save';
  }

  @override
  String workersWillBeApproved(int count) {
    return '$count workers will be approved';
  }

  @override
  String requestsWillBeRejected(int count) {
    return '$count requests will be rejected';
  }

  @override
  String workersWillBeRemoved(int count) {
    return '$count workers will be removed';
  }

  @override
  String workersWillBeRestored(int count) {
    return '$count workers will be returned to pending list';
  }

  @override
  String workersWillBeAdded(int count) {
    return '$count workers will be added';
  }

  @override
  String commentsCountLabel(int count) {
    return '$count comments';
  }

  @override
  String get editCommentTitle => 'Edit comment';

  @override
  String get editCommentHint => 'Edit your comment...';

  @override
  String get postTypeAnnouncementDesc =>
      'Important announcements for all workers';

  @override
  String get postTypeUpdateDesc => 'Updates and changes';

  @override
  String get postTypeEventDesc => 'Events and activities';

  @override
  String get postTypeGeneralDesc => 'General information';

  @override
  String get dateRangeButton => 'Date Range';

  @override
  String get selectDateRange => 'Select date range';

  @override
  String get noAttendanceDataMonth => 'No attendance data for this month';

  @override
  String chartTooltipDayHours(int day, String hours) {
    return 'Day $day\n$hours hours';
  }

  @override
  String get missingClockOutLabel => 'Missing clock-out';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String clockInPrefix(String time) {
    return 'Clock-in: $time';
  }

  @override
  String clockOutPrefix(String time) {
    return 'Clock-out: $time';
  }

  @override
  String get exportingLabel => 'Exporting...';

  @override
  String get exportPdfButton => 'Export PDF';

  @override
  String get allWorkersValidClockout =>
      'All workers clocked out correctly this month';

  @override
  String get noShiftsMonth => 'No shifts for this month';

  @override
  String shiftCountAndSlotsFormat(int count, int filled, int total) {
    return '$count shifts · $filled/$total slots filled';
  }

  @override
  String shiftCountTooltip(int count) {
    return '$count shifts';
  }

  @override
  String get taskDistributionTitle => 'Task Distribution';

  @override
  String get noTasksMonth => 'No tasks for this month';

  @override
  String get totalTasksLabel => 'Total Tasks';

  @override
  String get workersWithTasksLabel => 'Workers with Tasks';

  @override
  String get completionRateLabel => 'Completion Rate';

  @override
  String get completionRateByWorkerTitle => 'Completion Rate by Worker';

  @override
  String get topTenLabel => '(Top 10)';

  @override
  String get workerDetailsTitle => 'Worker Details';

  @override
  String get executionLabel => 'Completion';

  @override
  String get statusDistributionTitle => 'Status Distribution';

  @override
  String get taskDetailsListTitle => 'Task Details';

  @override
  String taskGoalPrefix(String date) {
    return 'Due: $date';
  }

  @override
  String get taskTimelineSubmitted => 'Submitted';

  @override
  String get taskTimelineStarted => 'Started';

  @override
  String get taskTimelineEnded => 'Ended';

  @override
  String get workersHoursTitle => 'Work Hours';

  @override
  String get activeWorkersLabel => 'Active Workers';

  @override
  String get totalHoursLabel => 'Total Hours';

  @override
  String get avgPerWorkerLabel => 'Avg per Worker';

  @override
  String get hoursByWorkerTitle => 'Hours by Worker';

  @override
  String workerDaysAndAvgFormat(int days, String avg) {
    return '$days days · avg $avg h/day';
  }

  @override
  String get generalReportsTabLabel => 'General Reports';

  @override
  String get personalReportsSubtitle =>
      'View personal attendance, task, and shift data';

  @override
  String get attendanceReportDescription =>
      'Work hours, days worked, and monthly summary';

  @override
  String get taskReportDescription =>
      'Task status, progress, and completion rates';

  @override
  String get shiftReportDescription =>
      'Shift history, approvals, and decisions';

  @override
  String get generalReportsTitle => 'General Reports';

  @override
  String get generalReportsSubtitle => 'Aggregated data across all workers';

  @override
  String get workersHoursDescription => 'Monthly work hours summary by worker';

  @override
  String get taskDistributionDescription =>
      'Tasks by worker, completion rates, and ranking';

  @override
  String get shiftCoverageDescription =>
      'Shifts by department, fill rate, and details';

  @override
  String get missingClockoutsDescription =>
      'Workers who forgot to clock out by month';

  @override
  String reportsOfWorker(String name) {
    return '$name\'s Reports';
  }

  @override
  String get workerReportsSubtitle => 'View attendance, task, and shift data';

  @override
  String get performanceSummaryTitle => 'Performance Summary — This Month';

  @override
  String hoursWithValue(String hours) {
    return '$hours hours';
  }

  @override
  String daysWithValue(int days) {
    return '$days days';
  }

  @override
  String get presenceLabel => 'Presence';

  @override
  String get atWorkLabel => 'At Work';

  @override
  String get tasksCompletedLabel => 'Tasks Completed';

  @override
  String shiftDecisionApproved(int count) {
    return 'Approved ($count)';
  }

  @override
  String shiftDecisionRejected(int count) {
    return 'Rejected ($count)';
  }

  @override
  String shiftDecisionOther(int count) {
    return 'Other ($count)';
  }

  @override
  String get showDetailsLabel => 'Show Details';

  @override
  String get hideDetailsLabel => 'Hide Details';

  @override
  String get approvedByLabel => 'Approved by';

  @override
  String get roleAtAssignmentLabel => 'Role at Assignment';

  @override
  String get requestTimeLabel => 'Request Time';

  @override
  String get removedByLabel => 'Removed by';

  @override
  String get removalTimeLabel => 'Removal Time';

  @override
  String get cancelledByLabel => 'Cancelled by';

  @override
  String get cancellationTimeLabel => 'Cancellation Time';

  @override
  String get shiftStatusActiveFem => 'Active';

  @override
  String get shiftStatusCancelledFem => 'Cancelled';

  @override
  String get shiftStatusPendingFem => 'Pending';

  @override
  String get decisionAcceptedLabel => 'Approved';

  @override
  String get decisionRejectedLabel => 'Rejected';

  @override
  String get decisionRemovedLabel => 'Removed';

  @override
  String get decisionPendingLabel => 'Pending';

  @override
  String get shiftManagerRoleLabel => 'Shift Manager';

  @override
  String get deptManagerRoleLabel => 'Department Manager';

  @override
  String hoursAbbrFormat(String hours) {
    return '$hours hr';
  }

  @override
  String get pickPhotoOption => 'Choose photos';

  @override
  String get pickPhotoSubtitle => 'Choose photos from gallery';

  @override
  String get adminRoleLabel => 'Admin';

  @override
  String reactorsPeopleCount(int count) {
    return '$count people';
  }

  @override
  String get deptGeneral => 'General';

  @override
  String get deptPaintball => 'Paintball';

  @override
  String get deptRopes => 'Ropes Park';

  @override
  String get deptCarting => 'Carting';

  @override
  String get deptWaterPark => 'Water Park';

  @override
  String get deptJimbory => 'Jimbory';

  @override
  String get deptOperations => 'Operations';

  @override
  String get preparingUploadShort => 'Preparing...';

  @override
  String get clockReminder10hTitle => 'Forgot to clock out? ⏰';

  @override
  String get clockReminder10hBody =>
      'You\'ve been on shift for 10 hours. Remember to report clock out.';

  @override
  String get clockReminder12hTitle => 'Very long shift! 🚨';

  @override
  String get clockReminder12hBody =>
      'You\'ve been on shift for 12 hours. Report clock out soon.';

  @override
  String get taskDeadlineReminderTitle => 'Task Reminder ⏰';

  @override
  String taskDeadlineReminderBody(String title) {
    return '$title — less than 24 hours remaining to complete';
  }

  @override
  String pendingApprovalCount(int count) {
    return '$count workers pending approval';
  }

  @override
  String understaffedShiftsCount(int count) {
    return '$count shifts today are understaffed';
  }

  @override
  String get hoursAbbreviation => 'hr';

  @override
  String get minutesAbbreviation => 'min';

  @override
  String daysThisMonth(int count) {
    return '$count days this month';
  }

  @override
  String totalHoursCount(String count) {
    return '$count hours';
  }

  @override
  String activeDepartmentsPercent(int percent) {
    return '$percent% of departments active';
  }

  @override
  String get autoClockoutTitle => 'Auto clock-out from shift';

  @override
  String get autoClockoutBody =>
      'You didn\'t report clock-out after 16 hours – the system ended the shift automatically. Contact your manager.';

  @override
  String get postCategoryAnnouncement => 'Announcement';

  @override
  String get postCategoryUpdate => 'Update';

  @override
  String get postCategoryEvent => 'Event';

  @override
  String get postCategoryGeneral => 'General';

  @override
  String get locationRationaleTitle => 'Location Access';

  @override
  String get locationRationaleMessage =>
      'The app needs access to your location to allow clock-in and clock-out within the park area.\n\nLocation is used only to verify attendance and is never stored or shared.';

  @override
  String get locationRationaleConfirm => 'Allow Access';

  @override
  String get locationRationaleCancel => 'Not Now';

  @override
  String get biometricLoginReason =>
      'Verify your identity to log in to the app';

  @override
  String get shiftApprovedTitle => 'Your shift request was approved';

  @override
  String shiftApprovedBody(String date, String startTime, String endTime) {
    return 'You were assigned to the shift on $date, $startTime–$endTime';
  }

  @override
  String get shiftRejectedTitle => 'Your shift request was rejected';

  @override
  String shiftRejectedBody(String date, String startTime, String endTime) {
    return 'Your request for the shift on $date, $startTime–$endTime was not approved';
  }

  @override
  String uploadingVideoProgress(int current, int total) {
    return 'Uploading video $current of $total...';
  }

  @override
  String uploadingImageProgress(int current, int total) {
    return 'Uploading image $current of $total...';
  }

  @override
  String uploadingProgress(int current, int total) {
    return 'Uploading $current of $total...';
  }

  @override
  String get generatingThumbnailStatus => 'Generating thumbnail...';

  @override
  String fileUploadedStatus(int current) {
    return 'File $current uploaded';
  }

  @override
  String get agreeToPrivacyPrefix => 'I have read and agree to the';

  @override
  String get andConnector => 'and';

  @override
  String get privacyPolicyRequiredError =>
      'You must accept the privacy policy to continue';
}
