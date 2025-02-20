import 'package:flutter/material.dart';
import 'auth/login_screen.dart'; // Import the LoginScreen file
import 'auth/new_worker_screen.dart'; // Import the NewWorkerScreen file
import '../../constants/app_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

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
                    AppConstants.teamImage,
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
                            AppColors.textBlack,
                            AppColors.textBlack.withOpacity(0.0),
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
                    AppConstants.parkLogo,
                    width: MediaQuery.of(context).size.width * 0.4, // Dynamic width
                    height: MediaQuery.of(context).size.height * 0.1,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24.0),
                  // Buttons
                  _buildButton(
                    context: context,
                    label: AppStrings.loginButtonText,
                    color: AppColors.primaryBlue,
                    onPressed: () {
                      // Navigate to LoginScreen with a slide-from-bottom transition
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const LoginScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0); // Start from the bottom
                            const end = Offset.zero; // End at original position
                            const curve = Curves.easeInOut;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _buildButton(
                    context: context,
                    label: AppStrings.newWorkerButtonText,
                    color: AppColors.secondaryYellow,
                    onPressed: () {
                      // Navigate to NewWorkerScreen with a slide-from-bottom transition
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const NewWorkerScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0); // Start from the bottom
                            const end = Offset.zero; // End at original position
                            const curve = Curves.easeInOut;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
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
      child: Directionality(
        textDirection: TextDirection.rtl, // Ensure Right-to-Left alignment for Hebrew
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textBlack, // Black text color
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
