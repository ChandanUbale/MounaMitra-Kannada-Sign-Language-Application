import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'info_page.dart'; // Info page import
import 'signin_page.dart'; // SignInPage import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kannada Sign Language App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/info': (context) => const InfoPage(),
        '/signin': (context) => const SignInPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assests/animation/bg_shape.json', // Correct the path for your Lottie file
          fit: BoxFit.cover,
          repeat: false,
          onLoaded: (composition) {
            Future.delayed(
              Duration(seconds: composition.duration.inSeconds),
                  () {
                // Navigate to InfoPage after animation
                Navigator.pushReplacementNamed(context, '/info');
              },
            );
          },
        ),
      ),
    );
  }
}
