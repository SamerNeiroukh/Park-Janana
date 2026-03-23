import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'registration_form.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kYellow = Color(0xFFF6C34C);
const _kAmber = Color(0xFFD97706);
const _kBg = Color(0xFFF9FAFB);

class NewWorkerScreen extends StatelessWidget {
  const NewWorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            // ── Hero image ────────────────────────────────────────────────────
            SizedBox(
              height: size.height * 0.32,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppConstants.teamImage,
                    fit: BoxFit.cover,
                  ),
                  // Light top fade for back button readability
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: 100,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x88000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Bottom fade into white card
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    height: 80,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Back button — top left
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content card ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo + title
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              AppConstants.parkLogo,
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'עובד חדש? ברוך הבא!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'הצטרף לצוות פארק גננה בכמה צעדים פשוטים',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Section title
                      const Text(
                        'איך זה עובד?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Steps
                      _buildStep(
                        number: '1',
                        icon: Icons.edit_note_rounded,
                        title: 'מלא טופס הרשמה',
                        subtitle: 'הזן את פרטיך האישיים ובחר סיסמה',
                      ),
                      _buildStep(
                        number: '2',
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'אישור ההנהלה',
                        subtitle: 'הנהלת הפארק תבדוק את פרטיך ותאשר את חשבונך',
                      ),
                      _buildStep(
                        number: '3',
                        icon: Icons.celebration_rounded,
                        title: 'הצטרף לצוות',
                        subtitle: 'לאחר האישור תוכל להתחבר ולהתחיל לעבוד',
                        isLast: true,
                      ),

                      const SizedBox(height: 28),

                      // CTA button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kYellow,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _openRegistrationForm(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'שלח בקשת הצטרפות',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number + connector line
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _kYellow,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: _kAmber),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openRegistrationForm(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const RegistrationForm(),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}
