import 'package:flutter/material.dart';
// For redirection after registration
import 'registration_form.dart';

class NewWorkerScreen extends StatelessWidget {
  const NewWorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const Text(
                'עובד חדש? ברוך הבא!',
                style: TextStyle(
                  fontFamily: 'SuezOne',
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 246, 195, 76), // Yellow color
                ),
                textAlign: TextAlign.right, // Align from right to left
              ),
              const SizedBox(height: 16.0),
              // Subtitle
              const Text(
                'ליצירת חשבון עובד חדש בפארק גננה, צור קשר עם ההנהלה או שלח פניה.',
                style: TextStyle(
                  fontFamily: 'SuezOne',
                  fontSize: 16.0,
                  color: Colors.black,
                ),
                textAlign: TextAlign.right, // Align from right to left
              ),
              const SizedBox(height: 24.0),
              // Send Form Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 246, 195, 76), // Yellow color
                  elevation: 4,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                onPressed: () {
                  _showRegistrationForm(context); // Show the registration form
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
              // Back Button
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
    );
  }

  // Show the registration form
  void _showRegistrationForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const RegistrationForm();
      },
    );
  }
}
