import 'package:flutter/material.dart';
import 'Performancepage.dart';
import 'LearnPage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(
                  'https://storage.googleapis.com/a1aa/image/kXPc-0uAi0fAoJF6sDAMPTagjsfJKuze0x1if24ITtI.jpg',
                ),
              ),
            ),
            SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      icon: Icons.book,
                      text: 'Learn',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LearnPage()),
                        );
                      },
                    ),
                    CustomButton(
                      icon: Icons.speed,
                      text: 'Performance',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PerformancePage()),
                        );
                      },
                    ),

                    CustomButton(icon: Icons.support, text: 'Support'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.language), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        currentIndex: 1,
        onTap: (index) {
          // Navigation logic if needed
        },
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;

  const CustomButton({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed ?? () {},
          icon: Icon(icon, color: Colors.white),
          label: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}
