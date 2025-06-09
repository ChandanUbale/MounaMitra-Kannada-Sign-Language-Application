import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'numbers_quiz_page.dart';
import 'AlphabetQuizPage.dart';
import 'gestureQuiz.dart';

class QuizPage extends StatefulWidget {
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool numbersCompleted = false;
  bool alphabetsCompleted = false;
  bool gestureCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadProgressFromFirestore();
  }

  Future<void> _loadProgressFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        numbersCompleted = data['hasCompletedNumberLearning'] ?? false;
        alphabetsCompleted = data['hasCompletedAlphabetLearning'] ?? false;
        gestureCompleted = data['hasCompletedGestureLearning'] ?? false;
      });
    }
  }

  void _navigateToQuiz(String type) {
    Widget screen;

    if (type == 'Numbers') {
      screen = NumbersQuizPage();
    } else if (type == 'Alphabets') {
      screen = KannadaAlphabetQuizPage(); // ✅ Show real quiz page
    }  else if (type == 'Basic Gesture') {
      screen = GestureQuizPage(); // ✅ Use actual Gesture Quiz Page
    } else {
      screen = PlaceholderQuizScreen(type: type);
  }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((value) {
      if (value == true) {
        _loadProgressFromFirestore(); // Refresh status after quiz attempt
      }
    });
  }

  void _showBlockedDialog(String label) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Quiz Locked"),
        content: Text("Please complete the $label learning video first."),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildQuizOption(String label, IconData icon, bool isEnabled) {
    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          _navigateToQuiz(label);
        } else {
          _showBlockedDialog(label);
        }
      },
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 10),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              SizedBox(width: 16),
              Text(
                '$label Quiz',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ಪ್ರಶ್ನೆಸ್ಫರ್ಧೆ(Quiz)")),
      backgroundColor: Colors.purple.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildQuizOption("Numbers", Icons.format_list_numbered, numbersCompleted),
            _buildQuizOption("Alphabets", Icons.sort_by_alpha, alphabetsCompleted),
            _buildQuizOption("Basic Gesture", Icons.gesture, gestureCompleted),
          ],
        ),
      ),
    );
  }
}

class PlaceholderQuizScreen extends StatelessWidget {
  final String type;

  const PlaceholderQuizScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$type Quiz')),
      body: Center(
        child: Text('This is the $type quiz screen.'),
      ),
    );
  }
}
