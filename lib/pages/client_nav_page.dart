import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:himlayang_nav/pages/login_page.dart';
import 'client_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'client_map_page.dart';
import 'client_records_page.dart';

class ClientHomePage extends StatefulWidget {
  final String userEmail;
  const ClientHomePage(this.userEmail, {Key? key}) : super(key: key);

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<User?> _authSubscription;
  late StreamSubscription<DocumentSnapshot> _verificationSubscription;

  int _currentIndex = 0; // Variable for the currently selected index

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
        FirebaseFirestore.instance.collection('userID').doc(user.uid).update({
          'isVerified': true,
        });
      }
    });

    _verificationSubscription = FirebaseFirestore.instance
        .collection('userID')
        .doc()
        .snapshots()
        .listen((snapshot) {
      // Handle the snapshot data
      // ...
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _verificationSubscription.cancel();
    super.dispose();
  }

  void signUserOut() {
    _auth.signOut().then((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }).catchError((error) {});
  }

  void _onItemTapped(int index) {
    // Navigation handler
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      ClientDashboardPage(widget.userEmail),
      const ClientMapPage(),
      const ClientRecordsPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: children.isNotEmpty ? children[_currentIndex] : Container(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onItemTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}
