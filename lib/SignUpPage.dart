import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // Add a function to save user data in Firestore
  Future<void> saveUserData(User user) async {
    try {
      await FirebaseFirestore.instance.collection('userCollection').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        // You can add more user details here, like display name or profile photo URL
      });
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Sign Up',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800])),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.teal)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.teal)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.teal)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  String email = emailController.text.trim();
                  String password = passwordController.text;
                  String confirmPassword = confirmPasswordController.text;

                  if (email.isEmpty ||
                      password.isEmpty ||
                      confirmPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please fill in all the fields')));
                    return;
                  }

                  if (!isValidEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Enter a valid email address')));
                    return;
                  }

                  if (password != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Passwords do not match')));
                    return;
                  }

                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    User? user = userCredential.user;

                    if (user != null) {
                      // After registration, save user data to Firestore
                      await saveUserData(user);

                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Registration successful! Please sign in.')));
                      Navigator.pop(context);
                    }
                  } on FirebaseAuthException catch (e) {
                    String errorMsg = 'Registration failed';
                    if (e.code == 'weak-password') {
                      errorMsg = 'The password provided is too weak.';
                    } else if (e.code == 'email-already-in-use') {
                      errorMsg =
                      'The account already exists for that email.';
                    }
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(errorMsg)));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Sign Up',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
