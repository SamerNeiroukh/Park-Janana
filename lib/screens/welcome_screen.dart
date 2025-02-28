import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/new_worker_screen.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Background Image with Inclined Cut
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
                  // 🔹 Gradient Overlay for Contrast
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.textBlack.withOpacity(0.7),
                            AppColors.textBlack.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 🔹 Logo & Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Park Logo
                  Image.asset(
                    AppConstants.parkLogo,
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.1,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24.0),
                  // 🔹 Login Button
                  _buildButton(
                    context: context,
                    label: AppStrings.loginButtonText,
                    color: AppColors.primaryBlue,
                    onPressed: () => _navigateToScreen(context, const LoginScreen()),
                  ),
                  const SizedBox(height: 16.0),
                  // 🔹 New Worker Registration Button
                  _buildButton(
                    context: context,
                    label: AppStrings.newWorkerButtonText,
                    color: AppColors.secondaryYellow,
                    onPressed: () => _navigateToScreen(context, const NewWorkerScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 **Reusable Button Widget**
  Widget _buildButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: AppTheme.primaryButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.all(color),
      ),
      onPressed: onPressed,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          label,
          style: AppTheme.buttonTextStyle,
        ),
      ),
    );
  }

  /// 🔹 **Reusable Navigation with Slide Transition**
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }
}

/// 🔹 **Custom Clipper for Background Image**
class BottomInclinedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
