// ignore_for_file: unused_import

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../components/my_button.dart';
import 'head_nav_page.dart';
import 'admin_nav_page.dart';
import 'client_nav_page.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneAuthPage extends StatefulWidget {
  final String userEmail;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const PhoneAuthPage({
    required this.userEmail,
    required this.emailController,
    required this.passwordController,
    Key? key,
  }) : super(key: key);

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  late String _base32Secret;
  final int _interval = 30;
  String? _otpAuthUri;
  final TextEditingController _otpController = TextEditingController();
  bool? _hasOTPSecret;
  bool _isCorrectOTP = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _otpTimer;
  bool _isLoading = false;

  void _backToLogin() async {
    // Clear the email and password fields
    widget.emailController.clear();
    widget.passwordController.clear();

    // Clear the saved user from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberedUserEmail');
    await prefs.remove('rememberedUserPassword');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _auth.authStateChanges().listen((User? user) {
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

    _checkExistingOTPSecret().then((hasExistingSecret) {
      setState(() {
        _hasOTPSecret = hasExistingSecret;
        _buildMessage(); // Call _buildMessage to update the message immediately
      });

      if (hasExistingSecret) {
        _startOtpGeneration();
      } else {
        _generateAndStoreOtpSecret().then((_) {
          _generateOtp();
          _startOtpGeneration();
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpTimer?.cancel(); // Cancel the timer if it's still active
    super.dispose();
  }

  void _startOtpGeneration() {
    _otpTimer = Timer.periodic(Duration(seconds: _interval), (Timer t) {
      _generateOtp();
    });
  }

  Future<bool> _checkExistingOTPSecret() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore
          .instance
          .collection('userID')
          .doc(user.uid)
          .get();

      String? otpSecret = document.data()?['otpSecret'];

      if (otpSecret != null) {
        _base32Secret = otpSecret;
        return true;
      }
    }

    return false;
  }

  Future<void> _generateAndStoreOtpSecret() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
      var random = Random();

      _base32Secret = List.generate(32, (index) {
        int randomNumber = random.nextInt(chars.length);
        return chars[randomNumber];
      }).join();

      CollectionReference users =
          FirebaseFirestore.instance.collection('userID');
      await users.doc(user.uid).update(
        {
          'otpSecret': _base32Secret,
        },
      );
    }
  }

  void _generateOtp() {
    if (_base32Secret.isNotEmpty) {
      String issuerName = 'HimNav';
      String accountName = FirebaseAuth.instance.currentUser!.email!;

      _otpAuthUri =
          'otpauth://totp/$issuerName:$accountName?secret=$_base32Secret&issuer=$issuerName';

      setState(() {});
    }
  }

  Future<void> _checkOTP() async {
    String enteredOTP = _otpController.text;
    String generatedOTP = TOTPGenerator(_base32Secret, _interval).generateOtp();

    if (enteredOTP.length == 6) {
      setState(() {
        _isLoading = true; // Start the loading indicator
      });

      await Future.delayed(
          const Duration(seconds: 2)); // Simulating OTP verification delay

      if (enteredOTP == generatedOTP) {
        setState(() {
          _isLoading = false; // Stop the loading indicator
          _isCorrectOTP = true;
        });

        String loggedInEmail =
            widget.userEmail; // Get the logged-in user's email

        if (loggedInEmail.toLowerCase() == 'himlayangpilipinoha@outlook.com') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HeadHomePage(widget.userEmail)),
            );
          }
        } else if (loggedInEmail.toLowerCase() ==
            'himlayangpilipinoa@outlook.com') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AdminHomePage(widget.userEmail)),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ClientHomePage(widget.userEmail)),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false; // Stop the loading indicator
          _isCorrectOTP = false;
        });
        _showAlertDialog(
            'Incorrect OTP'); // Show an alert dialog for incorrect OTP
      }
    } else {
      if (_isLoading) {
        setState(() {
          _isLoading = false; // Stop the loading indicator
        });
      }
    }
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verification Failed'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _base32Secret));
    _showCopiedToClipboardAlert();
  }

  void _showCopiedToClipboardAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Key Copied'),
          content: const Text('The key has been copied to the clipboard.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _buildMessage() {
    if (_hasOTPSecret == null) {
      return 'Checking OTP secret...';
    } else if (_hasOTPSecret == true) {
      return 'Please input the OTP located in your authentication app';
    } else {
      return 'Please download Google Authenticator App to obtain OTP. '
          'Scan the QR code or long press the QR code to copy the key to your clipboard.'
          'Do not leave the page until you have retrieved the key.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Original content goes here
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Text(
                    _buildMessage(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ),
                const SizedBox(height: 20.0),
                if (_hasOTPSecret == false && _otpAuthUri != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: <Widget>[
                      GestureDetector(
                        onLongPress: () => _copyToClipboard(context),
                        child: QrImageView(
                          data: _otpAuthUri!,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Center(
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 6, // Limit input to 6 digits
                      onChanged: (value) {
                        if (value.length == 6) {
                          _checkOTP();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        errorText: _isCorrectOTP ? 'Incorrect OTP' : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                MyButton(
                  onTap: _checkOTP,
                  buttonText: 'Verify OTP',
                ),
                const SizedBox(height: 10.0),
                MyButton(
                  onTap: _backToLogin,
                  buttonText: 'Back to Login',
                ),
              ],
            ),
          ),

          // Translucent black background + loading animation
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class TOTPGenerator {
  final String _base32Secret;
  final int _interval;

  TOTPGenerator(this._base32Secret, this._interval);

  String generateOtp() {
    // Get the number of time steps since Unix Epoch
    final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeSteps = nowInSeconds ~/ _interval;

    // Convert time steps to byte array
    final stepsBytes = _intToBytes(timeSteps);

    // Decode Base32 secret to byte array
    final secretBytes = _base32decode(_base32Secret);

    // Calculate HMAC-SHA1
    final hmacSha1 = Hmac(sha1, secretBytes);
    final digest = hmacSha1.convert(stepsBytes);

    // Calculate offset
    final offset = digest.bytes.last & 0xf;

    // Calculate binary
    final binary = ((digest.bytes[offset] & 0x7f) << 24) |
        ((digest.bytes[offset + 1] & 0xff) << 16) |
        ((digest.bytes[offset + 2] & 0xff) << 8) |
        (digest.bytes[offset + 3] & 0xff);

    // Calculate OTP
    final otp = binary % pow(10, 6);

    return otp.toString().padLeft(6, '0');
  }

  List<int> _intToBytes(int num) {
    var bytes = List<int>.filled(8, 0, growable: false);
    for (int pos = 7; pos >= 0; pos--) {
      bytes[pos] = num & 0xff;
      num >>= 8;
    }
    return bytes;
  }

  List<int> _base32decode(String base32) {
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    int size = base32.length;
    int buffer = 0;
    int bitsLeft = 0;
    List<int> result = [];

    for (int pos = 0; pos < size; pos++) {
      int val = alphabet.indexOf(base32[pos]);
      if (val < 0) continue;
      buffer <<= 5;
      buffer |= val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        result.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }
    return result;
  }
}
