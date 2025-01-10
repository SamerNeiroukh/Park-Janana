import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_card.dart';
import '../widgets/user_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required String role});

  Future<List<Map<String, dynamic>>> _getCardsForRole() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    User? currentUser = auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(currentUser.uid).get();

    String role = userDoc.get('role') ?? 'worker';

    List<Map<String, dynamic>> allCards = [
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

    if (role == 'worker') {
      return allCards
          .where((card) =>
              ["פרופיל אישי", "תלושי שכר", "משמרות", "תמיכה", "יצירת קשר"]
                  .contains(card["title"]))
          .toList();
    } else if (role == 'manager') {
      return allCards
          .where((card) =>
              [
                "פרופיל אישי",
                "תלושי שכר",
                "משמרות",
                "דוחות",
                "ניהול צוות",
                "הגדרות",
                "תמיכה",
                "יצירת קשר"
              ].contains(card["title"]))
          .toList();
    } else if (role == 'owner') {
      return allCards; // Owners see everything
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('עמוד הבית'),
        backgroundColor: const Color.fromARGB(255, 86, 194, 244), // Sky blue
        actions: const [UserHeader()],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getCardsForRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final cards = snapshot.data!;

          return Padding(
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
          );
        },
      ),
    );
  }
}
