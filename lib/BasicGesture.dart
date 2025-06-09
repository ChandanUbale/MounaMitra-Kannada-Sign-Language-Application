import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class BasicGesturesPage extends StatefulWidget {
  @override
  _BasicGesturesPageState createState() => _BasicGesturesPageState();
}

class _BasicGesturesPageState extends State<BasicGesturesPage> {
  final List<Map<String, String>> gestures = [
    {'name': 'ನಮಸ್ಕಾರ', 'videoUrl': 'assests/videos/gestures/namaskara.mp4'},
    {'name': 'ನೀನು/ನೀವು', 'videoUrl': 'assests/videos/gestures/neenu.mp4'},
    {'name': 'ಊಟ', 'videoUrl': 'assests/videos/gestures/oota.mp4'},
    {'name': 'ನಾನು', 'videoUrl': 'assests/videos/gestures/naanu.mp4'},
    {'name':'ಧನ್ಯವಾದಗಳು', 'videoUrl': 'assests/videos/gestures/dhanyavadhagalu.mp4'},
    {'name':'ಬನ್ನಿ', 'videoUrl': 'assests/videos/gestures/bhanni.mp4'},
    {'name':'ಹೋಗು', 'videoUrl': 'assests/videos/gestures/hogu.mp4'}
    // Add more gestures here...
  ];

  Set<int> watchedGestures = Set();

  @override
  void initState() {
    super.initState();
    _loadWatchedGestures();
  }

  _loadWatchedGestures() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        watchedGestures = Set<int>.from(userData['watchedGestures'] ?? []);
      });
    }
  }

  _saveWatchedGestures() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDocRef.update({
      'watchedGestures': watchedGestures.toList(),
    });

    if (watchedGestures.length == gestures.length) {
      await userDocRef.update({'hasCompletedGestureLearning': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ಸನ್ನೆಗಳು'),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.purple.shade50,
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: gestures.length,
        itemBuilder: (context, index) {
          final gesture = gestures[index]['name']!;
          final videoUrl = gestures[index]['videoUrl']!;
          final isWatched = watchedGestures.contains(index);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GestureVideoPlayer(
                    gestureName: gesture,
                    videoUrl: videoUrl,
                    onVideoWatched: () {
                      setState(() {
                        watchedGestures.add(index);
                      });
                      _saveWatchedGestures();
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
                  gesture,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
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

class GestureVideoPlayer extends StatefulWidget {
  final String gestureName;
  final String videoUrl;
  final VoidCallback onVideoWatched;

  const GestureVideoPlayer({
    required this.gestureName,
    required this.videoUrl,
    required this.onVideoWatched,
  });

  @override
  _GestureVideoPlayerState createState() => _GestureVideoPlayerState();
}

class _GestureVideoPlayerState extends State<GestureVideoPlayer> {
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
      setState(() {}); // Update UI (progress)
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
        title: Text(widget.gestureName),
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
