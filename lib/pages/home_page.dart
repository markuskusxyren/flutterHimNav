import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:himi_navi_rec/pages/login_page.dart';
import 'package:himi_navi_rec/pages/dashboard_page.dart';
import 'package:himi_navi_rec/pages/map_page.dart';
import 'package:himi_navi_rec/pages/records_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  final String userEmail;
  const HomePage(this.userEmail, {Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      DashboardPage(widget.userEmail),
      const MapPage(),
      const RecordsPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        leading: kIsWeb
            ? null
            : Container(), // Conditionally remove the leading back button
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: () => signUserOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onItemTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
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
