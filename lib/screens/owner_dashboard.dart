import 'package:flutter/material.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Owner Dashboard',
          style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
