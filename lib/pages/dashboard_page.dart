// DashboardPage.dart
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String userEmail;

  const DashboardPage(this.userEmail, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'LOGGED IN AS: $userEmail',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
