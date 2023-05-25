import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:himi_navi_rec/pages/login_page.dart';

class DashboardPage extends StatelessWidget {
  final String userEmail;

  const DashboardPage(this.userEmail, {Key? key}) : super(key: key);

  void signUserOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }).catchError((error) {});

                Navigator.of(context).pop();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Text(
                'LOGGED IN AS: $userEmail',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Positioned(
              top: 10.0,
              right: 10.0,
              child: GestureDetector(
                onTap: () => signUserOut(context),
                child: CircleAvatar(
                  radius: 25.0,
                  backgroundColor: Colors.grey[900],
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
