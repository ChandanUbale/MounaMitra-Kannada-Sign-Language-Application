import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'numbers_page.dart';
import 'AlphabetsPage.dart';
import 'QuizPage.dart';
import 'BasicGesture.dart';
import 'TestPage.dart';

class LearnPage extends StatefulWidget {
  @override
  _LearnPageState createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final List<Map<String, dynamic>> options = [
    {'icon': Icons.format_list_numbered, 'label': 'ಸಂಖ್ಯೆಗಳು'},
    {'icon': Icons.sort_by_alpha, 'label': 'ವರ್ಣಮಾಲೆ'},
    {'icon': Icons.gesture, 'label': 'ಸನ್ನೆಗಳು'},
    {'icon': Icons.assignment, 'label': 'ಪರೀಕ್ಷೆ(Test)'},
    {'icon': Icons.quiz, 'label': 'ಪ್ರಶ್ನೆಸ್ಫರ್ಧೆ(Quiz)'},
  ];

  bool numbersCompleted = false;
  bool alphabetsUnlocked = false;  // Changed from alphabetsCompleted to reflect unlock state
  bool gestureCompleted = false;
  bool allVideosCompleted = false;
  bool gestureLearningCompleted = false;
  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      print("User data from 'users' collection: $userData");
      gestureLearningCompleted = userData['hasCompletedGestureLearning'] == true;
      await _checkQuizCompletion(user.uid);
    } else {
      print("User document not found in 'users' collection.");
    }
  }

  Future<void> _checkQuizCompletion(String userId) async {
    final quizResultsRef = FirebaseFirestore.instance.collection('quiz_results').doc(userId);
    final quizResultsDoc = await quizResultsRef.get();

    bool numbersPassed = false;
    bool alphabetsPassed = false;
    bool gesturePassed = false;

    if (quizResultsDoc.exists) {
      final quizData = quizResultsDoc.data()!;

      if (quizData.containsKey('numbers_attempts')) {
        final attempts = quizData['numbers_attempts'] as List<dynamic>;
        for (var attempt in attempts) {
          if (attempt['completed'] == true && (attempt['percentage'] ?? 0) >= 75) {
            numbersPassed = true;
            break;
          }
        }
      }

      if (quizData.containsKey('alphabet_attempts')) {
        final attempts = quizData['alphabet_attempts'] as List<dynamic>;
        for (var attempt in attempts) {
          if (attempt['completed'] == true && (attempt['percentage'] ?? 0) >= 75) {
            alphabetsPassed = true;
            break;
          }
        }
      }

      if (quizData.containsKey('gesture_attempts')) {
        final attempts = quizData['gesture_attempts'] as List<dynamic>;
        for (var attempt in attempts) {
          if (attempt['completed'] == true && (attempt['percentage'] ?? 0) >= 75) {
            gesturePassed = true;
            break;
          }
        }
      }
    }

    // Firestore progress check
    final progressDoc = await FirebaseFirestore.instance.collection('user_progress').doc(userId).get();

    bool alphabetUnlockedInProgress = false;
    bool gestureUnlockedInProgress = false;

    if (progressDoc.exists) {
      final progressData = progressDoc.data()!;
      alphabetUnlockedInProgress = progressData['alphabet_learning_unlocked'] == true;
      gestureUnlockedInProgress = progressData['basic_gesture_unlocked'] == true;
    }

    setState(() {
      numbersCompleted = numbersPassed;
      alphabetsUnlocked = alphabetsPassed || alphabetUnlockedInProgress;
      gestureCompleted = gesturePassed || gestureUnlockedInProgress;
    });
  }


  bool _isSectionEnabled(String label) {
    switch (label) {
      case 'ಸಂಖ್ಯೆಗಳು':
        return true;
      case 'ವರ್ಣಮಾಲೆ':
        return alphabetsUnlocked;
      case 'ಸನ್ನೆಗಳು':
        return gestureCompleted; // Updated to check proper field
      case 'ಪ್ರಶ್ನೆಸ್ಫರ್ಧೆ(Quiz)':
        return true;
      case 'ಪರೀಕ್ಷೆ(Test)':
        return gestureLearningCompleted;
      default:
        return false;
    }
  }

  void _handleTap(String label) {
    if (label == 'ಸಂಖ್ಯೆಗಳು') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NumbersPage()));
    } else if (label == 'ವರ್ಣಮಾಲೆ') {
      if (!alphabetsUnlocked) {
        _showBlockedDialog("Complete the Numbers Quiz with at least 75% to unlock Alphabets.");
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AlphabetsPage()));
       }
    } else if (label == 'ಸನ್ನೆಗಳು') {
      if (!gestureCompleted) {
        _showBlockedDialog("Complete the Alphabets Quiz with at least 75% to unlock Basic Gesture.");
      } else {
        // TODO: Navigate to Basic Gesture Page
        Navigator.push(context, MaterialPageRoute(builder: (_) => BasicGesturesPage()));
        // Example:
        // Navigator.push(context, MaterialPageRoute(builder: (_) => BasicGesturePage()));
      }
    } else if (label == 'ಪ್ರಶ್ನೆಸ್ಫರ್ಧೆ(Quiz)') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage()))
          .then((_) => _loadProgress());
    } else if (label == 'ಪರೀಕ್ಷೆ(Test)') {
      if (!gestureLearningCompleted) {
        _showBlockedDialog("Complete the Numbers Quiz with at least 75% to unlock Alphabets.");
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => CameraCaptureScreen()));
      }
      // TODO: Add navigation for Test
    }
  }

  void _showBlockedDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Access Denied"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('Learn'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage('assests/images/man.png'), // fixed typo here
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Choose What To Learn',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  String label = options[index]['label'];
                  bool isEnabled = _isSectionEnabled(label);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        if (isEnabled) {
                          _handleTap(label);
                        } else {
                          _showBlockedDialog("This section is locked.");
                        }
                      },
                      child: Opacity(
                        opacity: isEnabled ? 1.0 : 0.5,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.brown[400],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(options[index]['icon'], size: 40, color: Colors.white),
                              const SizedBox(height: 10),
                              Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
