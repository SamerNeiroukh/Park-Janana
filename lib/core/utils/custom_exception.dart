class CustomException implements Exception {
  final String message;
  /// Per-field errors for form validation (field key → error message).
  final Map<String, String>? fieldErrors;

  CustomException(this.message, {this.fieldErrors});

  @override
  String toString() => message;
}
