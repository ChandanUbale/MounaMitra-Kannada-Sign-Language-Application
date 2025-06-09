import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GestureQuizPage extends StatefulWidget {
  @override
  _GestureQuizPageState createState() => _GestureQuizPageState();
}

class _GestureQuizPageState extends State<GestureQuizPage> {
  final int totalQuestions = 5;
  late List<String> questions;
  int currentIndex = 0;
  int score = 0;
  late String userId;

  late VideoPlayerController _videoController;

  final List<String> gestureOptions = [
    'ನಮಸ್ಕಾರ', 'ನೀನು', 'ಊಟ', 'ನಾನು', 'ಧನ್ಯವಾದಗಳು', 'ಬನ್ನಿ', 'ಹೋಗು'
  ];

  final Map<String, String> gestureVideoMap = {
    'ನಮಸ್ಕಾರ': 'assests/videos/gestures/namaskara.mp4',
    'ನೀನು': 'assests/videos/gestures/neenu.mp4',
    'ಊಟ': 'assests/videos/gestures/oota.mp4',
    'ನಾನು': 'assests/videos/gestures/naanu.mp4',
    'ಧನ್ಯವಾದಗಳು': 'assests/videos/gestures/dhanyavadhagalu.mp4',
    'ಬನ್ನಿ': 'assests/videos/gestures/bhanni.mp4',
    'ಹೋಗು': 'assests/videos/gestures/hogu.mp4',
  };

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _generateRandomQuestions();
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

  void _generateRandomQuestions() {
    final all = List<String>.from(gestureOptions);
    all.shuffle();
    questions = all.take(totalQuestions).toList();
    _initializeVideo(questions[0]);
  }

  void _initializeVideo(String gesture) {
    _videoController = VideoPlayerController.asset(gestureVideoMap[gesture]!)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
      });
  }

  void _checkAnswer(String selected) {
    String correct = questions[currentIndex];
    if (selected == correct) score++;

    if (currentIndex < totalQuestions - 1) {
      _videoController.pause();
      _videoController.dispose();

      setState(() {
        currentIndex++;
        _initializeVideo(questions[currentIndex]);
      });
    } else {
      _videoController.dispose();
      _saveResultToFirestore();
    }
  }

  List<String> _generateOptions(String correct) {
    List<String> options = [correct];
    Random rand = Random();

    while (options.length < 4) {
      String candidate = gestureOptions[rand.nextInt(gestureOptions.length)];
      if (!options.contains(candidate)) {
        options.add(candidate);
      }
    }

    options.shuffle();
    return options;
  }

  void _saveResultToFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    final userId = user.uid;
    double percentage = (score / totalQuestions) * 100;

    final resultData = {
      'score': score,
      'percentage': percentage,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('quiz_results')
          .doc(userId)
          .collection('gesture_attempts')
          .add(resultData);

      _showResult(percentage.toStringAsFixed(1));
    } catch (e) {
      print("Failed to save result: $e");
    }
  }

  void _showResult(String percent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Quiz Completed 🎉"),
        content: Text("Score: $score/$totalQuestions\nPercentage: $percent%"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return Scaffold();

    String current = questions[currentIndex];
    List<String> options = _generateOptions(current);

    return Scaffold(
      appBar: AppBar(title: Text("Gesture Quiz")),
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${currentIndex + 1} of $totalQuestions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            _videoController.value.isInitialized
                ? Container(
              height: 350,  // smaller height for video
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            )
                : Center(child: CircularProgressIndicator()),
            SizedBox(height: 30),

            ...options.map((option) => Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                ),
                onPressed: () => _checkAnswer(option),
                child: Text(
                  option.toUpperCase(),
                  style: TextStyle(fontSize: 20),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
