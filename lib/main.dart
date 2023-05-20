import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:himi_navi_rec/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  late Animation<double> _animation;
  late Animation<Gradient?> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _animation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.08, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
    ]).animate(_controller);

    _gradientAnimation = _controller.drive(GradientTween());

    Future.delayed(const Duration(seconds: 3), navigateToLoginPage);
  }

  void navigateToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 20000),
            decoration: BoxDecoration(
              gradient: _gradientAnimation.value,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        MediaQuery.of(context).size.height * _animation.value,
                      ),
                      child: RotationTransition(
                        turns: TweenSequence<double>([
                          TweenSequenceItem<double>(
                            tween: Tween<double>(begin: 0.0, end: -0.05),
                            weight: 70,
                          ),
                          TweenSequenceItem<double>(
                            tween: Tween<double>(begin: -0.05, end: 0.0),
                            weight: 80,
                          ),
                        ]).animate(_controller),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: SizedBox(
          width: 200,
          height: 200,
          child: Image.asset(
            'lib/images/himlogo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class GradientTween extends Animatable<Gradient?> {
  @override
  Gradient? transform(double t) {
    return LinearGradient(
      colors: [
        Color.lerp(const Color.fromARGB(255, 252, 252, 252),
            const Color.fromARGB(255, 250, 222, 131), t)!,
        Color.lerp(const Color.fromARGB(255, 255, 255, 255),
            const Color.fromARGB(255, 121, 246, 255), t)!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
