import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const CustomCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox( // ✅ Use SizedBox to ensure proper constraints
        width: 80.0, // Slightly increased to accommodate text
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ Prevents overflow by using min size
          children: [
            Container(
              height: 60.0,
              width: 60.0,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 207, 228, 241), // Sky blue
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: Icon(
                icon,
                size: 40.0,
                color: const Color.fromARGB(255, 0, 182, 254),
              ),
            ),
            const SizedBox(height: 8.0),
            Flexible( // ✅ Wrap Text in Flexible to prevent text overflow
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // ✅ Ensures long text does not overflow
                maxLines: 2, // ✅ Allows text wrapping if necessary
              ),
            ),
          ],
        ),
      ),
    );
  }
}
