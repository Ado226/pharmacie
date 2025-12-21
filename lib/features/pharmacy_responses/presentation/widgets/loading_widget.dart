// Widget - Loading State

import 'package:flutter/material.dart';

class PharmacyResponsesLoadingWidget extends StatelessWidget {
  const PharmacyResponsesLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF009688)),
          ),
          SizedBox(height: 24),
          Text(
            'Chargement des réponses...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
