import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  final List<Map<String, String>> infoData = const [
    {
      'title': 'Welcome!',
      'text':
      'We aim to make sign language learning accessible, fun, and effective for everyone.',
      'image': 'assests/images/sign_language.jpg',
    },
    {
      'title': 'Learn Alphabets & Numbers',
      'text':
      'Start your journey by learning Kannada alphabets and numbers through rich visual content.',
      'image': 'assests/images/interactive.jpg',
    },
    {
      'title': 'Interactive Learning',
      'text':
      'Engage with interactive videos to practice basic gestures and improve retention.',
      'image': 'assests/images/interactive_learning.jpg',
    },
    {
      'title': 'Test Your Skills',
      'text':
      'Take quizzes and tests to track your performance and boost your confidence.',
      'image': 'assests/images/quiz.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: PageView.builder(
        itemCount: infoData.length + 1, // last page = sign in
        itemBuilder: (context, index) {
          if (index < infoData.length) {
            final item = infoData[index];
            return _buildInfoPage(
              title: item['title']!,
              text: item['text']!,
              imagePath: item['image']!,
              delay: (index * 300).ms,
            );
          } else {
            return _buildSignInPage(context);
          }
        },
      ),
    );
  }

  Widget _buildInfoPage({
    required String title,
    required String text,
    required String imagePath,
    required Duration delay,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.4, duration: 500.ms),

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              height: 200,
              fit: BoxFit.cover,
            ),
          )
              .animate(delay: delay)
              .scale(duration: 600.ms)
              .fadeIn(),

          const SizedBox(height: 20),

          Text(
            text,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          )
              .animate(delay: delay + 200.ms)
              .slideY(begin: 0.3, duration: 600.ms)
              .fadeIn(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSignInPage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ready to Start?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideY(begin: -0.3),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/signin');
            },
            child: const Text(
              'Go to Sign In',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
              .animate()
              .fadeIn()
              .scale(duration: 500.ms)
              .shake(hz: 1.5, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}
