import 'package:firebaseproject2/resuable__widgets/resuable_widgets.dart';
import 'package:firebaseproject2/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:firebaseproject2/screens/home_screnn.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void dispose() {
    _passwordTextController.dispose();
    _emailTextController.dispose();
    _userNameTextController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Widget _buildModernTextField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF666666),
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(
              color: Color(0xFF00BFA5),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: () {
          // Your existing sign-up logic
          final String userName = _userNameTextController.text.trim();
          final String email = _emailTextController.text.trim();
          final String phoneNumber = _phoneNumberController.text.trim();
          final String password = _passwordTextController.text.trim();

          if (userName.isEmpty || email.isEmpty || phoneNumber.isEmpty || password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill all fields.")));
            return;
          }

          if (!phoneNumber.startsWith('+') || phoneNumber.length < 10) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a valid phone number with country code (e.g., +1234567890).")));
            return;
          }

          bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
          if (!emailValid) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a valid email address.")));
            return;
          }

          if (password.length < 6) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Password must be at least 6 characters long.")));
            return;
          }

          FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: email,
                  password: password)
              .then((userCredential) async {
            print("Created new Auth account: ${userCredential.user?.uid}");

            User? user = userCredential.user;
            if (user != null) {
              try {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'username': userName,
                  'email': email,
                  'phoneNumber': phoneNumber,
                  'uid': user.uid,
                  'createdAt': Timestamp.now(),
                });
                print("User data saved to Firestore for UID: ${user.uid}");

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sign up successful! Redirecting..."), duration: Duration(seconds: 2)),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                print("Error saving user data to Firestore: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving profile data: ${e.toString()}. Please try signing up again."))
                  );
                }
              }
            }
          }).catchError((error) {
            print("Error creating Auth account: ${error.toString()}");
            if (mounted) {
              String errorMessage = "Sign Up Failed. Please try again.";
              if (error is FirebaseAuthException) {
                  switch (error.code) {
                      case 'email-already-in-use':
                          errorMessage = "This email is already registered. Please try logging in or use a different email.";
                          break;
                      case 'weak-password':
                          errorMessage = "The password is too weak. Please choose a stronger password.";
                          break;
                      case 'invalid-email':
                          errorMessage = "The email address is not valid.";
                          break;
                      default:
                          errorMessage = error.message ?? "An unknown sign-up error occurred.";
                  }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage))
              );
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Sign Up',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00BFA5),
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo and title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Logo and app name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Color(0xFF00BFA5),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'WELLNEX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main content container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        // Form container
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and subtitle
                              const Text(
                                'Register with us!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your information is safe with us',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Form fields
                              _buildModernTextField(
                                hintText: 'Enter your full name',
                                icon: Icons.person_outline,
                                controller: _userNameTextController,
                              ),
                              _buildModernTextField(
                                hintText: 'Enter your Email',
                                icon: Icons.email_outlined,
                                controller: _emailTextController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              _buildModernTextField(
                                hintText: 'Enter your phone number',
                                icon: Icons.phone_android_outlined,
                                controller: _phoneNumberController,
                                keyboardType: TextInputType.phone,
                              ),
                              _buildModernTextField(
                                hintText: 'Enter your password',
                                icon: Icons.lock_outline,
                                controller: _passwordTextController,
                                isPassword: true,
                              ),
                              
                              const SizedBox(height: 10),

                              // Sign up button
                              _buildSignUpButton(),

                              // Sign in link
                              const SizedBox(height: 10),
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Already have an account? ',
                                    style: const TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign in',
                                        style: const TextStyle(
                                          color: Color(0xFF00BFA5),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        // Add onTap handler if you have a sign-in screen to navigate to
                                      ),
                                    ],
                                  ),
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
          ],
        ),
      ),
    );
  }
}