import 'package:flutter/material.dart';

class GlobalBackground extends StatelessWidget {
  final Widget child;

  const GlobalBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/background_image.jpg', // Replace with your background image
            fit: BoxFit.cover,
          ),
        ),
        // Foreground Content
        child,
      ],
    );
  }
}
