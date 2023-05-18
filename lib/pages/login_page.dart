import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:himi_navi_rec/components/my_button.dart';
import 'package:himi_navi_rec/components/my_textfield.dart';
import 'package:himi_navi_rec/pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // show message to user
      showMessage('Password reset email sent. Check your email.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMessage('No user found for that email.');
      } else if (e.code == 'invalid-email') {
        showMessage('The email address is not valid.');
      } else {
        showMessage('Failed to send password reset email. Please try again.');
      }
    }
  }

  // sign user in method
  void signUserIn() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // try sign in
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // pop the loading circle
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      if (userCredential.user != null) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const HomePage()), // replace HomePage with your destination page
        );
      }
    } on FirebaseAuthException catch (e) {
      if (kIsWeb) {
        Navigator.pop(context);
        // For the web, we can handle errors differently
        if (e.message!.contains('auth/user-not-found')) {
          showMessage('No user found for that email.');
        } else if (e.message!.contains('auth/wrong-password')) {
          showMessage('Wrong password provided for that user.');
        } else {
          showMessage('Login failed. Please try again later.');
        }
      } else {
        // For Android/iOS, we can handle as we did previously
        if (e.code == 'user-not-found') {
          showMessage('Incorrect Email');
        } else if (e.code == 'wrong-password') {
          showMessage('Incorrect Password');
        } else if (e.code == 'invalid-email') {
          showMessage('Invalid Email');
        } else if (e.code == 'user-disabled') {
          showMessage('User Disabled');
        } else if (e.code == 'operation-not-allowed') {
          showMessage('Operation Not Allowed');
        } else {
          showMessage('Login Failed');
        }
      }
    }
  }

  // navigate to RegisterPage
  void navigateToRegisterPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var slideTransition = Tween(begin: begin, end: end).animate(
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
  }

  // show error message dialog
  void showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),

                // logo
                Image.asset(
                  'lib/images/himlogo.png',
                  width: 140,
                  height: 100,
                ),

                const SizedBox(height: 2),

                // welcome back, you've been missed!
                Text(
                  'Himlayang Pilipino Navigation App',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                // username textfield
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

                const SizedBox(height: 10),

                // forgot password?
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              // text editing controller for email input
                              final emailController = TextEditingController();

                              return AlertDialog(
                                title: const Text('Forgot Password'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Enter your email:'),
                                    TextField(controller: emailController),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(
                                          context); // close the dialog

                                      // try to send password reset email
                                      try {
                                        await FirebaseAuth.instance
                                            .sendPasswordResetEmail(
                                          email: emailController.text,
                                        );
                                        // show success message
                                        showMessage(
                                            'Password reset email sent. Check your email.');
                                      } on FirebaseAuthException catch (e) {
                                        if (e.code == 'user-not-found') {
                                          showMessage(
                                              'No user found for that email.');
                                        } else if (e.code == 'invalid-email') {
                                          showMessage(
                                              'The email address is not valid.');
                                        } else {
                                          showMessage(
                                              'Failed to send password reset email. Please try again.');
                                        }
                                      }
                                    },
                                    child: const Text('Submit'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // sign in button
                MyButton(
                  onTap: signUserIn,
                  buttonText: 'Sign In',
                ),

                const SizedBox(height: 25),

                // or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // not a member? register now
                GestureDetector(
                  onTap: () => navigateToRegisterPage(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Not a member?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Register now',
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
    );
  }
}
