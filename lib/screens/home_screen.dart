import 'package:flutter/material.dart';
import '../widgets/global_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GlobalBackground(
        child: Center(
          child: Text(
            'Welcome to the Home Screen!',
            style: TextStyle(
              color: Colors.white, // Ensure text contrasts with the background
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
