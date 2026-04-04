// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/features/auth/services/auth_service.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emailRequiredValidation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emailInvalidValidation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).resetLinkSent),
            backgroundColor: Colors.green,
          ),
        );
        _emailController.clear();
      }
    } on CustomException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).resetLinkError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.passwordRecoveryTitle,
                style: AppTheme.titleStyle.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              Text(
                l10n.enterEmailAddressPrompt,
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  hintStyle: AppTheme.hintTextStyle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24.0),
              _isSending
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: _sendPasswordResetEmail,
                      child: Text(
                        l10n.sendResetLinkButton,
                        style: AppTheme.buttonTextStyle,
                      ),
                    ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.backButton,
                  style: AppTheme.secondaryButtonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
