import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_strings.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/features/home/screens/home_screen.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/features/auth/screens/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate form
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Use AuthService to sign in - it handles approval check automatically
      await _authService.signIn(email, password);

      // AppAuthProvider's listener will automatically update auth state
      if (!mounted) return;
      _navigateToHomeScreen();
    } on CustomException catch (e) {
      if (!mounted) return;

      // Parse the error message to set appropriate field errors
      final errorMsg = e.message;
      setState(() {
        if (errorMsg.contains('האימייל לא נמצא במערכת') ||
            errorMsg.contains('כתובת האימייל לא תקינה')) {
          _emailError = errorMsg;
        } else if (errorMsg.contains('הסיסמה שגויה')) {
          _passwordError = errorMsg;
        } else {
          // Show general errors in SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor:
                  errorMsg.contains('לא אושר') ? Colors.orange : Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('שגיאה: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHomeScreen() {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppDimensions.paddingHorizontalXXL,
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Container(
                  constraints: const BoxConstraints(
                      maxWidth: AppDimensions.maxWidthForm),
                  padding: const EdgeInsets.all(AppDimensions.paddingXXXL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.borderRadiusXXXL,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: AppDimensions.shadowBlurL,
                        offset: AppDimensions.shadowOffsetL,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo or Icon
                      Container(
                        width: AppDimensions.containerS,
                        height: AppDimensions.containerS,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: AppDimensions.borderRadiusCircle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: AppDimensions.iconLarge,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXXXL),

                      // Welcome Text
                      Text(
                        'שלום עובדים יקרים',
                        style: AppTheme.titleStyle.copyWith(
                          color: AppColors.primary,
                          fontSize: AppDimensions.fontTitleL,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppDimensions.spacingM),
                      const Text(
                        'אנא הכנס את פרטי הכניסה שלך',
                        style: TextStyle(
                          fontSize: AppDimensions.fontL,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppDimensions.spacingHuge),

                      // Email Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                bottom: AppDimensions.paddingS,
                                right: AppDimensions.paddingXS),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'אימייל',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontL,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(width: AppDimensions.spacingM),
                                Icon(
                                  Icons.email_outlined,
                                  size: AppDimensions.iconM,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: AppDimensions.borderRadiusL,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppDimensions.borderRadiusL,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: AppDimensions.borderWidthM,
                                ),
                                borderRadius: AppDimensions.borderRadiusL,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: AppDimensions.borderWidthS,
                                ),
                                borderRadius: AppDimensions.borderRadiusL,
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: AppDimensions.borderWidthM,
                                ),
                                borderRadius: AppDimensions.borderRadiusL,
                              ),
                              contentPadding: AppDimensions.paddingContentInput,
                              hintText: 'הכנס את כתובת האימייל שלך',
                              hintStyle: AppTheme.hintTextStyle,
                              errorText: _emailError,
                            ),
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'אנא הכנס כתובת אימייל';
                              }
                              if (!value.contains('@')) {
                                return 'אנא הכנס כתובת אימייל תקינה';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.spacingXXXL),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                bottom: AppDimensions.paddingS,
                                right: AppDimensions.paddingXS),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'סיסמה',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontL,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(width: AppDimensions.spacingM),
                                Icon(
                                  Icons.lock_outlined,
                                  size: AppDimensions.iconM,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: AppDimensions.borderRadiusL,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppDimensions.borderRadiusL,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: AppDimensions.borderWidthM,
                                ),
                                borderRadius: AppDimensions.borderRadiusL,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: AppDimensions.borderWidthS,
                                ),
                                borderRadius: AppDimensions.borderRadiusL,
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: AppDimensions.borderWidthM,
                                ),
                                borderRadius: AppDimensions.borderRadiusL,
                              ),
                              contentPadding: AppDimensions.paddingContentInput,
                              hintText: 'הכנס את הסיסמה שלך',
                              hintStyle: AppTheme.hintTextStyle,
                              errorText: _passwordError,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            textAlign: TextAlign.right,
                            autofillHints: const [AutofillHints.password],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'אנא הכנס סיסמה';
                              }
                              if (value.length < 6) {
                                return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.spacingXL),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            AppStrings.forgotPassword,
                            style: AppTheme.linkTextStyle.copyWith(
                              color: AppColors.primary,
                              fontSize: AppDimensions.fontM,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spacingXXXL),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeightL,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: AppDimensions.elevationS,
                            shadowColor: AppColors.primary.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppDimensions.borderRadiusXL,
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: AppDimensions.loaderS,
                                  height: AppDimensions.loaderS,
                                  child: CircularProgressIndicator(
                                    strokeWidth: AppDimensions.borderWidthM,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textWhite,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'כניסה',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontXXL,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spacingXXXL),

                      // Back Button
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingM,
                            horizontal: AppDimensions.paddingXXL,
                          ),
                        ),
                        child: Text(
                          'חזור',
                          style: AppTheme.secondaryButtonTextStyle.copyWith(
                            fontSize: AppDimensions.fontL,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
