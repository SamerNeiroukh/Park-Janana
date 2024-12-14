import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome Label
              const Text(
                'שלום עובדים יקרים',
                style: TextStyle(
                  fontFamily: 'SuezOne', // Custom font
                  fontSize: 36.0, // Larger font size
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 86, 194, 244), // Sky blue color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              // ID Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center-align labels
                children: [
                  const Text(
                    'תעודת זהות',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // Center-align label text
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                      hintText: 'הכנס את תעודת הזהות שלך',
                      hintStyle: const TextStyle(fontSize: 14.0),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 86, 194, 244), // Sky blue color
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    textAlign: TextAlign.center, // Center-align text inside the box
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center-align labels
                children: [
                  const Text(
                    'סיסמה',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // Center-align label text
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                      hintText: 'הכנס את הסיסמה שלך',
                      hintStyle: const TextStyle(fontSize: 14.0),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 86, 194, 244), // Sky blue color
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    textAlign: TextAlign.center, // Center-align text inside the box
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Forgot Password Label
              GestureDetector(
                onTap: () {
                  // Handle "Forgot Password" action
                },
                child: const Text(
                  'שכחתי סיסמה',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Color.fromARGB(255, 86, 194, 244), // Sky blue color
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // Center-align text
                ),
              ),
              const SizedBox(height: 32.0),
              // Log In Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 86, 194, 244), // Sky blue color
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  // Handle sign-in action
                },
                child: const Text(
                  'כניסה',
                  style: TextStyle(
                    fontSize: 18.0, // Slightly larger font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Back Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
                child: const Text(
                  'חזור',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey, // Gray color for back button
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
