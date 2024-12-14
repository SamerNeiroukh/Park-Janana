import 'package:flutter/material.dart';

class NewWorkerScreen extends StatelessWidget {
  const NewWorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big Yellow Title
              const Directionality(
                textDirection: TextDirection.rtl, // Right-to-left direction for Hebrew
                child: Text(
                  'עובד חדש? ברוך הבא!',
                  style: TextStyle(
                    fontFamily: 'SuezOne',
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 246, 195, 76),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16.0),
              // Black Description Label
              const Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'ליצירת חשבון עובד חדש בפארק גננה, צור קשר עם ההנהלה או שלח פניה.',
                  style: TextStyle(
                    fontFamily: 'SuezOne',
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32.0),
              // Send Request Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 246, 195, 76),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const NewWorkerFormDialog(),
                  );
                },
                child: const Text(
                  'שלח פניה',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Back Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'חזור',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewWorkerFormDialog extends StatelessWidget {
  const NewWorkerFormDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black.withOpacity(0.5), // Background overlay
          ),
        ),
        Center(
          child: SizedBox(
            width: 350, // Fixed width
            height: 500, // Fixed height
            child: Material(
              borderRadius: BorderRadius.circular(12.0),
              child: Scaffold(
                resizeToAvoidBottomInset: false, // Prevent resizing due to keyboard
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end, // Align labels to the right
                      children: [
                        // Title
                        const Text(
                          'טופס הרשמה',
                          style: TextStyle(
                            fontFamily: 'SuezOne',
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        // Full Name
                        const Text(
                          'שם מלא',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            hintText: 'הכנס את שמך המלא',
                            hintStyle: const TextStyle(fontSize: 14.0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        // Phone Number
                        const Text(
                          'מספר טלפון',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            hintText: 'הכנס את מספר הטלפון שלך',
                            hintStyle: const TextStyle(fontSize: 14.0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        // ID Number
                        const Text(
                          'תעודת זהות',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            hintText: 'הכנס את תעודת הזהות שלך',
                            hintStyle: const TextStyle(fontSize: 14.0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        // Email
                        const Text(
                          'אימייל',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8.0),
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            hintText: 'הכנס את כתובת האימייל שלך',
                            hintStyle: const TextStyle(fontSize: 14.0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24.0),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close the dialog
                              },
                              child: const Text(
                                'חזור',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Handle form submission
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 246, 195, 76), // Yellow color
                              ),
                              child: const Text('שלח'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
