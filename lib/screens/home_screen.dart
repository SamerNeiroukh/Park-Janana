import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cards = [
      {"title": "פרופיל אישי", "icon": Icons.person, "route": "/profile"},
      {"title": "תלושי שכר", "icon": Icons.receipt_long, "route": "/pay_slips"},
      {"title": "משמרות", "icon": Icons.schedule, "route": "/shifts"},
      {"title": "דוחות", "icon": Icons.bar_chart, "route": "/reports"},
      {"title": "ניהול צוות", "icon": Icons.people, "route": "/team_management"},
      {"title": "הגדרות", "icon": Icons.settings, "route": "/settings"},
      {"title": "אירועים", "icon": Icons.event, "route": "/events"},
      {"title": "משימות", "icon": Icons.task, "route": "/tasks"},
      {"title": "תמיכה", "icon": Icons.support_agent, "route": "/support"},
      {"title": "מידע נוסף", "icon": Icons.info, "route": "/more_info"},
      {"title": "יצירת קשר", "icon": Icons.contact_mail, "route": "/contact"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('עמוד הבית'),
        backgroundColor: const Color.fromARGB(255, 86, 194, 244), // Sky blue
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two cards per row
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return CustomCard(
              title: card['title'],
              icon: card['icon'],
              onTap: () {
                Navigator.pushNamed(context, card['route']);
              },
            );
          },
        ),
      ),
    );
  }
}
