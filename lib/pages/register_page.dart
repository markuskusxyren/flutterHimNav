import 'package:flutter/material.dart';
import 'package:himi_navi_rec/components/my_button.dart';
import 'package:himi_navi_rec/components/my_textfield.dart';
import 'package:himi_navi_rec/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zxcvbn/zxcvbn.dart';
import 'dart:async';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text editing controllers
  late final TextEditingController emailController = TextEditingController();
  late final TextEditingController passwordController = TextEditingController();
  late final TextEditingController confirmPasswordController =
      TextEditingController();

  // Stream controller for password strength
  final _passwordStrengthController = StreamController<int>();

  @override
  void initState() {
    super.initState();
    passwordController.addListener(() {
      _updatePasswordStrength(passwordController.text);
    });
  }

// Update password strength
  void _updatePasswordStrength(String password) {
    final zxcvbn = Zxcvbn();
    final strength = zxcvbn.evaluate(password).score;
    _passwordStrengthController.add(strength!.toInt()); // change here
  }

  // register user method
  void registerUser() async {
    final String email = emailController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (password != confirmPassword) {
      showMessage('Password inputs do not match. Please input again.');
      passwordController.clear();
      confirmPasswordController.clear();
      return;
    }

    final Zxcvbn zxcvbn = Zxcvbn();
    final result = zxcvbn.evaluate(password);

    if (result.score! < 3) {
      showMessage(
          'The password is not strong enough. Please try again with a stronger password.');
      passwordController.clear();
      confirmPasswordController.clear();
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password)) {
      showMessage(
          'The password must contain at least one number, special character, and a capital letter.');
      passwordController.clear();
      confirmPasswordController.clear();
      return;
    }

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

      await FirebaseFirestore.instance
          .collection('userID')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.sendEmailVerification();

      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Email needs to be verified'),
              content: const Text(
                  'An email verification link has been sent to your email. Please verify your account to continue. Check your spam folder if you cannot find the email.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // close the loading dialog
      if (e.code == 'weak-password') {
        showMessage('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        showMessage('An account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        showMessage('The email address is not valid.');
      } else {
        showMessage('Registration failed. Please try again later.');
      }
      passwordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      Navigator.pop(context); // close the loading dialog
      showMessage('Registration failed. Please try again later.');
      passwordController.clear();
      confirmPasswordController.clear();
    }
  }

  void showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registration Failed'),
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
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(
                      0.2), // Adjust the opacity to control darkness
                ],
              ),
            ),
            child: SafeArea(
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
                                additionalHint:
                                    'One uppercase letter, one number, and one special character is required',
                              ),

                              const SizedBox(height: 30),

                              // Password strength indicator
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 54, 54, 54),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: StreamBuilder<int>(
                                      stream:
                                          _passwordStrengthController.stream,
                                      builder: (BuildContext context,
                                          AsyncSnapshot<int> snapshot) {
                                        String passwordStrength = '';
                                        Color strengthColor = Colors.red;

                                        switch (snapshot.data) {
                                          case 0:
                                          case 1:
                                            passwordStrength = 'Very weak';
                                            strengthColor =
                                                const Color.fromARGB(
                                                    255, 216, 14, 0);
                                            break;
                                          case 2:
                                            passwordStrength = 'Weak';
                                            strengthColor =
                                                const Color.fromARGB(
                                                    255, 230, 138, 0);
                                            break;
                                          case 3:
                                            passwordStrength = 'Strong';
                                            strengthColor =
                                                const Color.fromARGB(
                                                    255, 233, 211, 10);
                                            break;
                                          case 4:
                                            passwordStrength = 'Very strong';
                                            strengthColor =
                                                const Color.fromARGB(
                                                    255, 29, 133, 32);
                                            break;
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Password Strength: $passwordStrength',
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 204, 204, 204),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius: const BorderRadius
                                                      .all(
                                                  Radius.circular(
                                                      10)), // set the radius value you want
                                              child: LinearProgressIndicator(
                                                value: (snapshot.data ?? 0) / 4,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        strengthColor),
                                                backgroundColor:
                                                    Colors.grey[300],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // confirm password textfield
                              MyTextField(
                                controller: confirmPasswordController,
                                hintText: 'Confirm Password',
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

                        const SizedBox(height: 20),

                        // already a member? sign in now
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80.0, vertical: 20.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (BuildContext context, animation,
                                          secondaryAnimation) =>
                                      const LoginPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return Stack(
                                      children: [
                                        child,
                                        SlideTransition(
                                          position: Tween<Offset>(
                                            begin: Offset.zero,
                                            end: const Offset(1, 0),
                                          ).animate(animation),
                                          child:
                                              const RegisterPage(), // This is your current page widget
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already a member?',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 51, 51, 51),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sign in now',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordStrengthController.close();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
