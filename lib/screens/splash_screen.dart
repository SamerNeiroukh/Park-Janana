import 'package:flutter/material.dart';
import 'welcome_screen.dart'; // Import the WelcomeScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 5), // Total duration for all transitions
      vsync: this,
    );

    // Define logo fade animation
    _logoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut), // Logo fades in the last part
      ),
    );

    // Define background color sequence animation
    _backgroundColorAnimation = TweenSequence<Color?>(
      [
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.white, end: Colors.blue),
          weight: 1.0,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.blue, end: Colors.red),
          weight: 1.0,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.red, end: Colors.yellow),
          weight: 1.0,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.yellow, end: Colors.white),
          weight: 1.0,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth transitions between colors
      ),
    );

    // Start the animation
    _controller.forward();

    // Navigate to the WelcomeScreen after the animation
    Future.delayed(const Duration(seconds: 6), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColorAnimation.value, // Dynamic background color
          body: Center(
            child: Opacity(
              opacity: _logoFadeAnimation.value, // Dynamic logo opacity
              child: Image.asset(
                'assets/images/park_logo.png',
                width: 250,
                height: 250,
              ),
            ),
          ),
        );
      },
    );
  }
}
