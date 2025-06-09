import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PerformancePage extends StatefulWidget {
  @override
  _PerformancePageState createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  late String userId;
  List<Map<String, dynamic>> attempts = [];
  String selectedQuizType = 'numbers_attempts';

  final Map<String, String> quizTypeLabels = {
    'numbers_attempts': 'Numbers Quiz',
    'kannada_alphabet_attempts': 'Kannada Alphabet Quiz',
    'gesture_attempts': 'Gesture Quiz',
    'test_results': 'Test Results', // ✅ Added test results label
  };

  @override
  void initState() {
    super.initState();
    _fetchAttempts();
  }

  Future<void> _fetchAttempts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    userId = user.uid;

    try {
      QuerySnapshot snapshot;

      if (selectedQuizType == 'test_results') {
        snapshot = await FirebaseFirestore.instance
            .collection('test_results')
            .doc(userId)
            .collection('attempts')
            .orderBy('score', descending: false)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('quiz_results')
            .doc(userId)
            .collection(selectedQuizType)
            .orderBy('timestamp', descending: false)
            .get();
      }

      setState(() {
        attempts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'score': data['score'] ?? 0,
            'percentage': (data['percentage'] as num?)?.toDouble() ?? 0.0,
            'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching attempts: $e');
    }
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('Q${value.toInt() + 1}'),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: attempts.asMap().entries.map((entry) {
          int index = entry.key;
          double percentage = entry.value['percentage'];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: percentage,
                color: Colors.teal,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Performance Overview')),
      backgroundColor: Colors.purple.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedQuizType,
              items: quizTypeLabels.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedQuizType = value;
                    attempts.clear();
                  });
                  _fetchAttempts();
                }
              },
            ),
            SizedBox(height: 20),
            attempts.isEmpty
                ? Expanded(
              child: Center(
                child: Text("No attempts found for selected quiz."),
              ),
            )
                : Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quizTypeLabels[selectedQuizType]} Performance',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  SizedBox(height: 250, child: _buildBarChart()),
                  SizedBox(height: 20),
                  Text(
                    'Attempt History:',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = attempts[index];
                        final timestamp = attempt['timestamp'];
                        final formattedTime = timestamp != null
                            ? DateFormat('yyyy-MM-dd – kk:mm')
                            .format(timestamp)
                            : 'Unknown';
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text('${index + 1}',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            title: Text('Score: ${attempt['score']}'),
                            subtitle: Text(
                                'Percentage: ${attempt['percentage'].toStringAsFixed(1)}%\n$formattedTime'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
