import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject2/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebaseproject2/screens/home_screnn.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    String phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a phone number.")));
      return;
    }
    if (!phoneNumber.startsWith('+')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please include the country code (e.g., +1, +91).")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        print("Verification Completed Automatically");
        setState(() { _isLoading = false; });
        try {
          await _auth.signInWithCredential(credential);
          print("User signed in automatically!");
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        } on FirebaseAuthException catch (e) {
          print("Failed to sign in automatically: ${e.message}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Auto verification failed: ${e.message}")),
            );
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification Failed: ${e.message}");
        setState(() { _isLoading = false; });
        String errorMessage = "Verification failed. Please try again.";
        if (e.code == 'invalid-phone-number') {
          errorMessage = "The phone number provided is not valid.";
        } else if (e.code == 'too-many-requests') {
          errorMessage = "Too many requests. Please try again later.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        print("OTP Sent to $phoneNumber. Verification ID: $verificationId");
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _verificationId = verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent to $phoneNumber")),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("Code auto retrieval timeout. Verification ID: $verificationId");
        // You might want to set _verificationId here if it's not already set,
        // though typically 'codeSent' would have been called first.
        // setState(() { _verificationId = verificationId; });
      },
      timeout: const Duration(seconds: 60),
    );
  }

  // NEW: Function to verify OTP and sign in
  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter the OTP.")));
      return;
    }
    if (otp.length != 6) { // Basic check for OTP length
        ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter a valid 6-digit OTP.")));
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification ID not found. Please try sending OTP again.")));
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign the user in (or link) with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("User signed in successfully with phone: ${userCredential.user?.uid}");

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Remove all previous routes so user can't go back to login
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Failed to sign in with OTP: ${e.message}");
      String errorMessage = "Failed to verify OTP. Please try again.";
      if (e.code == 'invalid-verification-code') {
        errorMessage = "The OTP entered is invalid. Please check and try again.";
      } else if (e.code == 'session-expired') {
        errorMessage = "The verification code has expired. Please request a new OTP.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("An unexpected error occurred during OTP verification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Login with Phone",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2893"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 40),
                if (!_otpSent)
                  TextField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.phone, color: Colors.white70),
                      labelText: "Enter Phone Number (e.g., +16505551234)",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      fillColor: Colors.white.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(width: 0, style: BorderStyle.none),
                      ),
                    ),
                    cursorColor: Colors.white,
                  ),
                const SizedBox(height: 20),
                if (_otpSent)
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), letterSpacing: 5.0, fontSize: 18.0),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: "",
                      labelText: "Enter OTP",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                      filled: true,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      fillColor: Colors.white.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(width: 0, style: BorderStyle.none),
                      ),
                    ),
                    cursorColor: Colors.white,
                  ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  ElevatedButton(
                    onPressed: () {
                      if (_otpSent) {
                        _verifyOtp(); // Call the verify OTP function
                      } else {
                        _sendOtp();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: hexStringToColor("5E61F4"),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(_otpSent ? "Verify OTP" : "Send OTP"),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}