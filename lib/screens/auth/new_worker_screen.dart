import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'registration_form.dart';

class NewWorkerScreen extends StatelessWidget {
  const NewWorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Directionality(
            textDirection:
                TextDirection.rtl, // Set text direction to Right-to-Left
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center align content
              children: [
                Text(
                  'עובד חדש? ברוך הבא!',
                  style: AppTheme.titleStyle
                      .copyWith(color: AppColors.secondary), // ✅ Use Yellow
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'ליצירת חשבון עובד חדש בפארק גננה, צור קשר עם ההנהלה או שלח פניה.',
                  style: AppTheme.bodyText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary, // ✅ Use Yellow
                    elevation: 4,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  onPressed: () {
                    _showRegistrationForm(
                        context); // Show the registration form
                  },
                  child: const Text(
                    'שלח פניה',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to the welcome screen
                  },
                  child: const Text(
                    'חזור',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRegistrationForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const RegistrationForm();
      },
    );
  }
}
