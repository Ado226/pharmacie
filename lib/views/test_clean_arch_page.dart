// Page de test pour Clean Architecture
import 'package:flutter/material.dart';
import '../features/pharmacy_responses/presentation/pages/pharmacy_responses_page.dart';

class TestCleanArchPage extends StatelessWidget {
  const TestCleanArchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Clean Architecture'),
        backgroundColor: Color(0xFF009688),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tester la Clean Architecture',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers PharmacyResponsesPage avec commandeId = 8
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PharmacyResponsesPage(
                      commandeId: 8, // ID de test
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF009688),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Voir Réponses Pharmacies (ID: 8)',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Naviguer avec un autre ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PharmacyResponsesPage(
                      commandeId: 1,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Voir Réponses Pharmacies (ID: 1)',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
