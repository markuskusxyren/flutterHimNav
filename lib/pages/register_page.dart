import 'package:flutter/material.dart';
import 'package:himi_navi_rec/components/my_button.dart';
import 'package:himi_navi_rec/components/my_textfield.dart';
import 'package:himi_navi_rec/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // register user method
  void registerUser() async {
    final String email = emailController.text;
    final String password = passwordController.text;

    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Add user email to Firestore with isVerified set to false
      await FirebaseFirestore.instance
          .collection('userID')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'isVerified': false,
      });

      // Send email verification to the user
      await userCredential.user!.sendEmailVerification();

      // Clear the text fields after successful registration
      emailController.clear();
      passwordController.clear();

      // Show a success message and navigate to the login page
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text(
                'An email verification link has been sent to your email. Please verify your account to continue.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Handle any errors that occurred during registration
      print('Registration failed: $e');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Registration Failed'),
            content: const Text(
                'An error occurred during registration. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // registration form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // email textfield
                        MyTextField(
                          controller: emailController,
                          hintText: 'Email',
                          obscureText: false,
                        ),

                        const SizedBox(height: 10),

                        // password textfield
                        MyTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // register button
                  MyButton(
                    onTap: registerUser,
                    buttonText: 'Register',
                  ),

                  const SizedBox(height: 50),

                  // already a member? sign in now
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const LoginPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            var begin =
                                const Offset(1.0, 0.0); // Slide from right
                            var end = Offset.zero; // Slide to left
                            var curve = Curves.ease;

                            var slideTransition =
                                Tween(begin: begin, end: end).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: curve,
                              ),
                            );

                            return SlideTransition(
                              position: slideTransition,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already a member?',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Sign in now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
