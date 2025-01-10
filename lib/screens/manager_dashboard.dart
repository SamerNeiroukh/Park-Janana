import 'package:flutter/material.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Manager Dashboard',
          style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
