import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LetterVideoPlayer extends StatefulWidget {
  final int index;
  final String folder;
  final String letter;
  final VoidCallback onVideoWatched;

  const LetterVideoPlayer({
    Key? key,
    required this.index,
    required this.folder,
    required this.letter,
    required this.onVideoWatched,
  }) : super(key: key);

  @override
  _LetterVideoPlayerState createState() => _LetterVideoPlayerState();
}

class _LetterVideoPlayerState extends State<LetterVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _alreadyMarkedWatched = false;

  @override
  void initState() {
    super.initState();
    String videoPath = 'assests/videos/${widget.folder}/${widget.index}.mp4';

    _controller = VideoPlayerController.asset(videoPath)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration &&
          !_alreadyMarkedWatched) {
        _markVideoAsWatched();
        widget.onVideoWatched();
        _alreadyMarkedWatched = true;
      }
      setState(() {});
    });
  }

  Future<void> _markVideoAsWatched() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    List<dynamic> watchedAlphabets = [];
    if (snapshot.exists) {
      watchedAlphabets = snapshot.data()?['watchedAlphabetVideos'] ?? [];
    }

    String videoId = '${widget.folder}_${widget.index}';
    if (!watchedAlphabets.contains(videoId)) {
      watchedAlphabets.add(videoId);

      await userRef.update({
        'watchedAlphabetVideos': watchedAlphabets,
      });

      if (watchedAlphabets.length >= 49) {
        await userRef.update({
          'hasCompletedAlphabetLearning': true,
        });
      }
    }
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
        title: Text(widget.letter),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
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
                        style: const TextStyle(color: Colors.black),
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
                        style: const TextStyle(color: Colors.black),
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
