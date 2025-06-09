import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class NumbersPage extends StatefulWidget {
  @override
  _NumbersPageState createState() => _NumbersPageState();
}

class _NumbersPageState extends State<NumbersPage> {
  final List<Map<String, String>> numbers = [
    {'number': '೦', 'videoUrl': 'assests/videos/numbers/0.mp4'},
    {'number': '೧', 'videoUrl': 'assests/videos/numbers/1.mp4'},
    {'number': '೨', 'videoUrl': 'assests/videos/numbers/2.mp4'},
    {'number': '೩', 'videoUrl': 'assests/videos/numbers/3.mp4'},
    {'number': '೪', 'videoUrl': 'assests/videos/numbers/4.mp4'},
    {'number': '೫', 'videoUrl': 'assests/videos/numbers/5.mp4'},
    {'number': '೬', 'videoUrl': 'assests/videos/numbers/6.mp4'},
    {'number': '೭', 'videoUrl': 'assests/videos/numbers/7.mp4'},
    {'number': '೮', 'videoUrl': 'assests/videos/numbers/8.mp4'},
    {'number': '೯', 'videoUrl': 'assests/videos/numbers/9.mp4'},
  ];


  Set<int> watchedNumbers = Set();

  @override
  void initState() {
    super.initState();
    _loadWatchedNumbers();
  }

  // Load watched numbers from Firestore
  _loadWatchedNumbers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        watchedNumbers = Set<int>.from(userData['watchedNumbers'] ?? []);
      });
    }
  }

  // Save watched numbers to Firestore
  _saveWatchedNumbers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDocRef.update({
      'watchedNumbers': watchedNumbers.toList(),
    });

    if (watchedNumbers.length == 10) {
      await userDocRef.update({'hasCompletedNumberLearning': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ಸಂಖ್ಯೆಗಳು'),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.purple.shade50,
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          final number = numbers[index]['number']!;
          final videoUrl = numbers[index]['videoUrl']!;
          final isWatched = watchedNumbers.contains(index);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NumberVideoPlayer(
                    number: number,
                    videoUrl: videoUrl,
                    onVideoWatched: () {
                      setState(() {
                        watchedNumbers.add(index);
                      });
                      _saveWatchedNumbers();
                    },
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isWatched ? Colors.green : Colors.teal[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NumberVideoPlayer extends StatefulWidget {
  final String number;
  final String videoUrl;
  final VoidCallback onVideoWatched;

  const NumberVideoPlayer({
    required this.number,
    required this.videoUrl,
    required this.onVideoWatched,
  });

  @override
  _NumberVideoPlayerState createState() => _NumberVideoPlayerState();
}

class _NumberVideoPlayerState extends State<NumberVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _alreadyMarkedWatched = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration &&
          !_alreadyMarkedWatched) {
        widget.onVideoWatched();
        _alreadyMarkedWatched = true;
      }
      setState(() {}); // For progress bar update
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  String _format(Duration d) {
    return d.inMinutes.toString().padLeft(2, '0') +
        ":" +
        (d.inSeconds % 60).toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final duration = _controller.value.duration.inSeconds.toDouble();
    final position = _controller.value.position.inSeconds.toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFf3f4f6),
      appBar: AppBar(
        title: Text('ಸಂಖ್ಯೆ ${widget.number}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? GestureDetector(
          onTap: () {
            setState(() => _showControls = !_showControls);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
              if (_showControls) ...[
                IconButton(
                  iconSize: 40,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.black,
                  ),
                  onPressed: _togglePlayback,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _format(_controller.value.position),
                        style: TextStyle(color: Colors.black),
                      ),
                      Expanded(
                        child: Slider(
                          value: position.clamp(0.0, duration),
                          min: 0,
                          max: duration > 0 ? duration : 1,
                          onChanged: (val) {
                            _controller.seekTo(
                              Duration(seconds: val.toInt()),
                            );
                          },
                        ),
                      ),
                      Text(
                        _format(_controller.value.duration),
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                )
              ]
            ],
          ),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
