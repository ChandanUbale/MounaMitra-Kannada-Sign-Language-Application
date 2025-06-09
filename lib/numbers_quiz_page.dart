import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NumbersQuizPage extends StatefulWidget {
  @override
  _NumbersQuizPageState createState() => _NumbersQuizPageState();
}

class _NumbersQuizPageState extends State<NumbersQuizPage> {
  final int totalQuestions = 5;
  late List<int> questions;
  int currentIndex = 0;
  int score = 0;
  late String userId;

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
    final allNumbers = List<int>.generate(10, (index) => index);
    allNumbers.shuffle();
    questions = allNumbers.take(totalQuestions).toList();
  }

  void checkAnswer(int selected) {
    int correctAnswer = questions[currentIndex];
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
        .collection('numbers_attempts');  // subcollection for attempts

    final progressRef = firestore.collection('user_progress').doc(userId);

    final attempt = {
      'score' : score,
      'completed': true,
      'percentage': scorePercentage,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Add a new attempt document with timestamp
      await resultCollection.add(attempt);

      // Unlock alphabet learning if score ≥ 75%
      if (scorePercentage >= 75) {
        await progressRef.set({
          'alphabet_learning_unlocked': true,
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

  List<int> generateOptions(int correct) {
    List<int> options = [correct];
    Random random = Random();

    while (options.length < 4) {
      int randomNum = random.nextInt(10);
      if (!options.contains(randomNum)) {
        options.add(randomNum);
      }
    }

    options.shuffle();
    return options;
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return Scaffold();

    int currentQuestion = questions[currentIndex];
    List<int> options = generateOptions(currentQuestion);

    return Scaffold(
      appBar: AppBar(title: Text("Numbers Quiz")),
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
              'assests/images/numbers/$currentQuestion.jpg',
              height: 200,
            ),
            SizedBox(height: 30),
            Column(
              children: options.map((num) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: () => checkAnswer(num),
                    child: Text(
                      '$num',
                      style: TextStyle(fontSize: 20),
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
