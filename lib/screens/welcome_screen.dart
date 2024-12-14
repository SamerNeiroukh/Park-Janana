import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Background image with inclined cut
            ClipPath(
              clipper: BottomInclinedClipper(),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/team_image.jpg',
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.7,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for better contrast
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Logo and Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/park_logo.png',
                    width: MediaQuery.of(context).size.width * 0.4, // Dynamic width
                    height: MediaQuery.of(context).size.height * 0.1,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24.0),
                  // Buttons
                  _buildButton(
                    context: context,
                    label: 'כניסה',
                    color: const Color.fromARGB(255, 86, 194, 244),
                    onPressed: () {
                      // Handle login navigation
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _buildButton(
                    context: context,
                    label: 'עובד חדש ?',
                    color: const Color.fromARGB(255, 246, 195, 76),
                    onPressed: () {
                      // Handle sign-up navigation
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable button builder
  Widget _buildButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 4,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      onPressed: onPressed,
      child: Directionality( // Ensure Right-to-Left alignment for Hebrew text
        textDirection: TextDirection.rtl,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Black text color
          ),
        ),
      ),
    );
  }
}

// Custom clipper for inclined cut
class BottomInclinedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50); // Start from bottom-left
    path.quadraticBezierTo(
      size.width / 2, // Smooth horizontal control point at the center
      size.height + 20, // Slightly below the bottom
      size.width, // End at the far right
      size.height - 50, // 50px above the bottom
    );
    path.lineTo(size.width, 0); // Line to top-right corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
