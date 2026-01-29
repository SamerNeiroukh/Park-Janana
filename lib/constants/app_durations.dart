class AppDurations {
  // Animation Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration slower = Duration(milliseconds: 800);

  // Common animation durations used in the app
  static const Duration cardExpand = Duration(milliseconds: 400);
  static const Duration fadeIn = Duration(milliseconds: 300);
  static const Duration buttonPress = Duration(milliseconds: 250);
  static const Duration shimmer = Duration(milliseconds: 350);
  static const Duration pageTransition = Duration(milliseconds: 300);

  // Delay durations
  static const Duration debounce = Duration(milliseconds: 300);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration toast = Duration(seconds: 2);
}
