import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../welcome_screen.dart';
import 'package:flutter/services.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  String? _nameError;
  String? _phoneError;
  String? _idError;
  String? _emailError;
  String? _passwordError;

  final RegExp _hebrewRegex = RegExp(r'^[א-ת\s]+$');
  final RegExp _phoneRegex = RegExp(r'^\d{10}$');
  final RegExp _idRegex = RegExp(r'^\d{9}$');
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  Future<void> _registerUser() async {
    if (_isLoading) return;

    setState(() {
      _nameError = !_hebrewRegex.hasMatch(_fullNameController.text.trim())
          ? 'יש להזין שם בעברית בלבד'
          : null;

      _phoneError = !_phoneRegex.hasMatch(_phoneNumberController.text.trim())
          ? 'מספר טלפון חייב להכיל בדיוק 10 ספרות'
          : null;

      _idError = !_idRegex.hasMatch(_idNumberController.text.trim())
          ? 'תעודת זהות חייבת להכיל בדיוק 9 ספרות'
          : null;

      _emailError = !_emailRegex.hasMatch(_emailController.text.trim())
          ? 'כתובת אימייל אינה תקינה'
          : null;

      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (password.length < 6) {
        _passwordError = 'הסיסמה חייבת להכיל לפחות 6 תווים';
      } else if (password != confirmPassword) {
        _passwordError = 'הסיסמאות אינן תואמות';
      } else {
        _passwordError = null;
      }
    });

    if (_nameError != null ||
        _phoneError != null ||
        _idError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      UserModel userModel = UserModel(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        uid: uid,
        profilePicture:
            'https://firebasestorage.googleapis.com/v0/b/park-janana-app.firebasestorage.app/o/profile_pictures%2Fdefault_profile.png?alt=media&token=918661c9-90a5-4197-8649-d2498d8ef4cd',
        role: 'worker',
      );

      // ✅ Add "approved": false here explicitly
      await _firestore.collection('users').doc(uid).set({
        ...userModel.toMap(),
        'approved': false,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('טופס הרשמה', style: AppTheme.titleStyle),
                const SizedBox(height: 16.0),
                _buildTextField(_fullNameController, 'שם מלא', 'הכנס את שמך המלא',
                    errorText: _nameError, autofillHints: [AutofillHints.name]),
                _buildTextField(
                  _phoneNumberController,
                  'מספר טלפון',
                  'הכנס את מספר הטלפון שלך',
                  errorText: _phoneError,
                  // keep local suffix; also include full telephoneNumber as a hint fallback
                  autofillHints: const [
                    AutofillHints.telephoneNumberLocalSuffix,
                    AutofillHints.telephoneNumber,
                    AutofillHints.telephoneNumberNational,
                  ],
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    IlLocalPhoneFormatter(),
                  ],
                ),
                _buildTextField(_idNumberController, 'תעודת זהות',
                    'הכנס את תעודת הזהות שלך',
                    errorText: _idError),
                _buildTextField(
                    _emailController, 'אימייל', 'הכנס את כתובת האימייל שלך',
                    errorText: _emailError, autofillHints: [AutofillHints.email]),
                _buildTextField(_passwordController, 'סיסמה', 'בחר סיסמה',
                    obscureText: true,
                    errorText:
                        _passwordError == 'הסיסמה חייבת להכיל לפחות 6 תווים'
                            ? _passwordError
                            : null,
                    autofillHints: [AutofillHints.newPassword]),
                _buildTextField(
                    _confirmPasswordController, 'אשר סיסמה', 'הכנס שוב את הסיסמה',
                    obscureText: true,
                    errorText: _passwordError == 'הסיסמאות אינן תואמות'
                        ? _passwordError
                        : null,
                    autofillHints: [AutofillHints.newPassword]),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        onPressed: _registerUser,
                        child: Text('שלח', style: AppTheme.buttonTextStyle),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('חזור', style: AppTheme.secondaryButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool obscureText = false,
    String? errorText,
    List<String>? autofillHints,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: AppTheme.bodyText),
          const SizedBox(height: 8.0),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            autofillHints: autofillHints,
            decoration: InputDecoration(
              filled: AppTheme.inputDecorationTheme.filled,
              fillColor: AppTheme.inputDecorationTheme.fillColor,
              contentPadding: AppTheme.inputDecorationTheme.contentPadding,
              border: AppTheme.inputDecorationTheme.border,
              enabledBorder: AppTheme.inputDecorationTheme.enabledBorder,
              focusedBorder: AppTheme.inputDecorationTheme.focusedBorder,
              hintText: hint,
              hintStyle: AppTheme.inputDecorationTheme.hintStyle,
              errorText: errorText,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class IlLocalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String t = newValue.text;

    // remove spaces, hyphens, parentheses, plus
    t = t.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // if it starts with country code 972 → convert to local (drop 972, add leading 0)
    if (t.startsWith('972')) {
      t = '0${t.substring(3)}';
    }

    // if we got a local suffix (9 digits, no leading 0), e.g. 503006771 → 0503006771
    if (t.length == 9 && !t.startsWith('0')) {
      t = '0$t';
    }

    // keep digits only and cap at 10
    t = t.replaceAll(RegExp(r'\D'), '');
    if (t.length > 10) t = t.substring(0, 10);

    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
