import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LearnPage.dart';

class CameraCaptureScreen extends StatefulWidget {
  @override
  _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  File? _image;
  String _prediction = '';
  int _score = 0;
  int _questionIndex = 0;
  List<String> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateRandomQuestions();
  }

  void _generateRandomQuestions() {
    final rand = Random();
    final Set<int> nums = {};
    while (nums.length < 3) {
      nums.add(rand.nextInt(10));
    }
    _questions = nums.map((e) => e.toString()).toList();
    setState(() {});
  }

  String get _currentQuestion => _questions[_questionIndex];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _isLoading = true;
    });
    await _uploadImage(_image!);
  }

  Future<void> _uploadImage(File img) async {
    final uri = Uri.parse('http://10.0.2.2:5000/predict');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        img.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    final res = await req.send();
    setState(() => _isLoading = false);

    if (res.statusCode == 200) {
      final body = await res.stream.bytesToString();
      final predicted = json.decode(body)['prediction'] as String;
      final correct = predicted == _currentQuestion;

      setState(() {
        _prediction =
        correct ? 'Correct ✅ ($predicted)' : 'Incorrect ❌ ($predicted)';
        if (correct) _score++;
      });

      await Future.delayed(const Duration(seconds: 2));
      _goToNextQuestion();
    } else {
      setState(() => _prediction = 'Error: ${res.statusCode}');
    }
  }

  void _goToNextQuestion() async {
    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex++;
        _image = null;
        _prediction = '';
      });
    } else {
      await _storeResultInFirestore();
      _showCompletionDialog();
    }
  }

  Future<void> _storeResultInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final double percentage =
    (_score / _questions.length * 100).toDouble(); // numeric value

    await FirebaseFirestore.instance
        .collection('test_results')
        .doc(user.uid)
        .collection('attempts')
        .add({
      'score': _score,
      'percentage': percentage,              // store as number
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showCompletionDialog() {
    final percent = (_score / _questions.length * 100).toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Test Complete'),
        content: Text('Score: $_score/${_questions.length}\n'
            'Percentage: $percent %'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LearnPage()),
                    (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient AppBar
      appBar: AppBar(
        title: const Text('Sign Language Test'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe0eafc), Color(0xffcfdef3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: _questions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              shadowColor: Colors.purpleAccent,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Sign the number:',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              shadowColor: Colors.deepPurpleAccent,
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _currentQuestion,
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple.shade800,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),

            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _image!,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 25),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.deepPurple,
                elevation: 5,
                shadowColor: Colors.deepPurpleAccent,
              ),
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text(
                'Capture Sign',
                style: TextStyle(fontSize: 20),
              ),
              onPressed: _isLoading ? null : _pickImage,
            ),

            const SizedBox(height: 30),
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            if (_prediction.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _prediction.startsWith('Correct')
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _prediction.startsWith('Correct')
                        ? Colors.green
                        : Colors.red,
                    width: 2,
                  ),
                ),
                child: Text(
                  _prediction,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _prediction.startsWith('Correct')
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
