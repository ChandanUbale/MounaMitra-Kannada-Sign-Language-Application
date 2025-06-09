import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LetterVideoPlayer.dart';

class AlphabetsPage extends StatefulWidget {
  @override
  _AlphabetsPageState createState() => _AlphabetsPageState();
}

class _AlphabetsPageState extends State<AlphabetsPage> {
  final List<String> swaragalu = ['ಅ', 'ಆ', 'ಇ', 'ಈ', 'ಉ', 'ಊ', 'ಋ', 'ಎ', 'ಏ', 'ಐ', 'ಒ', 'ಓ', 'ಔ', 'ಅಂ', 'ಅಃ'];
  final List<String> vyanjanagalu = ['ಕ', 'ಖ', 'ಗ', 'ಘ', 'ಙ', 'ಚ', 'ಛ', 'ಜ', 'ಝ', 'ಞ', 'ಟ', 'ಠ', 'ಡ', 'ಢ', 'ಣ', 'ತ', 'ಥ', 'ದ', 'ಧ', 'ನ', 'ಪ', 'ಫ', 'ಬ', 'ಭ', 'ಮ', 'ಯ', 'ರ', 'ಲ', 'ವ', 'ಶ', 'ಷ', 'ಸ', 'ಹ', 'ಳ'];

  Set<String> watchedLetters = Set();

  @override
  void initState() {
    super.initState();
    _loadWatchedLetters();
  }

  Future<void> _loadWatchedLetters() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final watched = snapshot.data()?['watchedAlphabetVideos'] ?? [];

      setState(() {
        watchedLetters = Set<String>.from(watched.map((id) {
          final parts = id.split('_');
          final folder = parts[0];
          final index = int.parse(parts[1]) - 1;
          if (folder == 'swara' && index >= 0 && index < swaragalu.length) {
            return swaragalu[index];
          } else if (folder == 'vyanjana' && index >= 0 && index < vyanjanagalu.length) {
            return vyanjanagalu[index];
          }
          return ''; // fallback
        }));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("ಕನ್ನಡ ವರ್ಣಮಾಲೆ"),
          backgroundColor: Colors.teal,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Swaragalu'),
              Tab(text: 'Vyanjanagalu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildGrid(context, swaragalu, 'swara'),
            buildGrid(context, vyanjanagalu, 'vyanjana'),
          ],
        ),
      ),
    );
  }

  Widget buildGrid(BuildContext context, List<String> letters, String folder) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: letters.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final letter = letters[index];
          final isWatched = watchedLetters.contains(letter);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LetterVideoPlayer(
                    index: index + 1,
                    folder: folder,
                    letter: letter,
                    onVideoWatched: () {
                      _loadWatchedLetters(); // Refresh when returning
                    },
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isWatched ? Colors.green : Colors.teal.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
