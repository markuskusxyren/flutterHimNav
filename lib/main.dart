import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:himi_navi_rec/pages/login_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), navigateToLoginPage);
  }

  void navigateToLoginPage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
          255, 212, 235, 255), // Set your desired background color here
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.fromARGB(255, 42, 188, 255),
                        Color.fromARGB(0, 255, 255, 255)
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: SizedBox(
                    width: 500, // set the size of the light effect
                    height: 500, // set the size of the light effect
                  ),
                ),
                ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.1).animate(
                    CurvedAnimation(
                        parent: _controller, curve: Curves.easeInOut),
                  ),
                  child: SizedBox(
                    width: 200, // Set the desired width of the image
                    height: 200, // Set the desired height of the image
                    child: Image.asset(
                      'lib/images/himlogo.png', // replace this with your actual logo path
                      fit: BoxFit
                          .contain, // Adjust the image's fit as per your requirement
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(), // Add the CircularProgressIndicator widget
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
