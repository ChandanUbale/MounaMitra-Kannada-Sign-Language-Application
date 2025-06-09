import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'SignUpPage.dart';
import 'HomeScreen.dart'; // Replace with your actual home screen file

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // Function to add user data to Firestore
  Future<void> addUserDataToFirestore(User user) async {
    try {
      // Check if the user document exists in Firestore
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Get the user document from Firestore
      DocumentSnapshot userDoc = await userRef.get();

      // If the document does not exist, create it with default values
      if (!userDoc.exists) {
        await userRef.set({
          'email': user.email ?? '',
          'hasCompletedAlphabetLearning': false,
          'hasCompletedGestureLearning': false,
          'hasCompletedNumberLearning': false,
        });
      }
    } catch (e) {
      print("Error adding user data to Firestore: $e");
    }
  }

  Future<void> signIn() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all the fields")));
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a valid email")));
      return;
    }

    try {
      // Sign in the user using Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore (if not already done)
      User? user = userCredential.user;
      if (user != null) {
        await addUserDataToFirestore(user);
      }

      // Navigate to the home screen after sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Sign in failed";
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Wrong password provided.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Welcome',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800])),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text('Sign In',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800])),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: const Text('Sign Up',
                          style: TextStyle(fontSize: 24, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(
                    color: Colors.teal,
                    thickness: 2,
                    indent: 16,
                    endIndent: 16),
                const SizedBox(height: 16),
                Text("Let's get started by filling out the form below.",
                    style: TextStyle(color: Colors.grey[700])),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: signIn,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Sign In',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
