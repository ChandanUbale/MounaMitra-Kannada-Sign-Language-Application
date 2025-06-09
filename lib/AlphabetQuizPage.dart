import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class KannadaAlphabetQuizPage extends StatefulWidget {
  @override
  _KannadaAlphabetQuizPageState createState() => _KannadaAlphabetQuizPageState();
}

class _KannadaAlphabetQuizPageState extends State<KannadaAlphabetQuizPage> {
  final int totalQuestions = 10;
  late List<String> questions; // Kannada alphabets as strings
  int currentIndex = 0;
  int score = 0;
  late String userId;

  // List of Kannada vowels (Vyanjanagalu can be added or changed)
  final List<String> kannadaAlphabets = [
     'ಕ', 'ಖ', 'ಗ', 'ಘ', 'ಙ', 'ಚ', 'ಛ',
    'ಜ', 'ಝ', 'ಞ', 'ಟ', 'ಠ', 'ಡ', 'ಢ', 'ಣ', 'ತ', 'ಥ',
    'ದ', 'ಧ', 'ನ', 'ಪ', 'ಫ', 'ಬ', 'ಭ', 'ಮ', 'ಯ', 'ರ',
    'ಲ', 'ವ', 'ಶ', 'ಷ', 'ಸ', 'ಹ', 'ಳ'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    generateRandomQuestions();
  }

  void _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    } else {
      print("User not authenticated");
    }
  }

  void generateRandomQuestions() {
    final allAlphabets = List<String>.from(kannadaAlphabets);
    allAlphabets.shuffle();
    questions = allAlphabets.take(totalQuestions).toList();
  }

  void checkAnswer(String selected) {
    String correctAnswer = questions[currentIndex];
    if (selected == correctAnswer) {
      score++;
    }

    if (currentIndex < totalQuestions - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      _showResult();
    }
  }

  Future<void> _showResult() async {
    double scorePercentage = (score / totalQuestions) * 100;

    final firestore = FirebaseFirestore.instance;
    final resultCollection = firestore
        .collection('quiz_results')
        .doc(userId)
        .collection('kannada_alphabet_attempts'); // separate subcollection

    final progressRef = firestore.collection('user_progress').doc(userId);

    final attempt = {
      'score' : score,
      'completed': true,
      'percentage': scorePercentage,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await resultCollection.add(attempt);

      // Mark basic gesture progress as completed

      // Unlock next learning stage if score ≥ 75%
      if (scorePercentage >= 75) {
        await progressRef.set({
          'basic_gesture_unlocked': true,
        }, SetOptions(merge: true));
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('Quiz Completed'),
          content: Text(
            'Your score: $score / $totalQuestions\n'
                'Percentage: ${scorePercentage.toStringAsFixed(1)}%',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error saving quiz result: $e");
    }
  }

  List<String> generateOptions(String correct) {
    List<String> options = [correct];
    Random random = Random();

    while (options.length < 4) {
      String randomChar = kannadaAlphabets[random.nextInt(kannadaAlphabets.length)];
      if (!options.contains(randomChar)) {
        options.add(randomChar);
      }
    }

    options.shuffle();
    return options;
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return Scaffold();

    String currentQuestion = questions[currentIndex];
    List<String> options = generateOptions(currentQuestion);

    return Scaffold(
      appBar: AppBar(title: Text("Kannada Alphabet Quiz")),
      backgroundColor: Colors.purple.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Question ${currentIndex + 1} of $totalQuestions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Image.asset(
              'assests/images/alphabets/$currentQuestion.jpeg',
              height: 200,
            ),
            SizedBox(height: 30),
            Column(
              children: options.map((char) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: () => checkAnswer(char),
                    child: Text(
                      char,
                      style: TextStyle(fontSize: 24),  // bigger font for Kannada
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
