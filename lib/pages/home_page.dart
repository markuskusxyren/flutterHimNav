import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:himi_navi_rec/pages/login_page.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user; // <- Change this to nullable
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          this.user = user; // Update user variable within setState
        });
        checkEmailVerification();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription
        .cancel(); // cancelling the stream subscription when not needed to free up resources
    super.dispose();
  }

  void signUserOut() {
    _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> checkEmailVerification() async {
    if (!user!.emailVerified) {
      // If email is not verified
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Email Not Verified'),
            content: const Text('Please verify your email to continue.'),
            actions: [
              TextButton(
                onPressed: () {
                  signUserOut(); // No need to pass the context here
                },
                child: const Text('Sign Out'),
              ),
            ],
          );
        },
      );
    } else {
      // If email is verified
      await FirebaseFirestore.instance.collection('userID').doc(user!.uid).set({
        'email': user!.email,
        'isVerified': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: () => signUserOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'LOGGED IN AS: ${user?.email ?? 'Loading...'}', // <- Check if user is not null before using
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
