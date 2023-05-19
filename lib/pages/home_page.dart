import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:himi_navi_rec/pages/login_page.dart';
import 'package:himi_navi_rec/pages/dashboard_page.dart';
import 'package:himi_navi_rec/pages/map_page.dart';
import 'package:himi_navi_rec/pages/records_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  final String userEmail;
  const HomePage(this.userEmail, {Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState(userEmail);
}

class _HomePageState extends State<HomePage> {
  final String userEmail;

  _HomePageState(this.userEmail);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<User?> _authSubscription;

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
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void signUserOut() {
    _auth.signOut().then((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }).catchError((error) {
      print("Error signing out: $error");
    });
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
      DashboardPage(userEmail),
      const MapPage(),
      const RecordsPage(),
    ];

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
