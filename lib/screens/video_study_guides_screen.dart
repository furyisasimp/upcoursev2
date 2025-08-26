import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:career_roadmap/widgets/custom_taskbar.dart' as taskbar;
import 'package:career_roadmap/services/aws_service.dart';
import 'package:career_roadmap/routes/route_tracker.dart';

class VideoStudyGuidesScreen extends StatefulWidget {
  static const routeName = '/video-study-guides';

  const VideoStudyGuidesScreen({Key? key}) : super(key: key);

  @override
  State<VideoStudyGuidesScreen> createState() => _VideoStudyGuidesScreenState();
}

class _VideoStudyGuidesScreenState extends State<VideoStudyGuidesScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _loadFailed = false;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final url = await AwsService.fetchVideoUrlFromApi('plate_tectonics.mp4');
    if (url != null) {
      try {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(url))
              ..addListener(() => setState(() {}))
              ..setLooping(false);
        await _controller!.initialize();
        setState(() => _isLoading = false);
      } catch (_) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // handle other tab navigation if needed
  }

  Future<bool> _handleSystemBack() async {
    final nav = Navigator.of(context);

    // Normal case: if there is a previous route on the stack, just pop.
    if (nav.canPop()) {
      nav.pop();
      return false;
    }

    // If this route was pushed as the first page after login with replacement,
    // fall back to the last tracked route (if any).
    final last = RouteTracker.instance.lastRouteName;
    if (last != null && last.isNotEmpty) {
      nav.pushReplacementNamed(last);
      return false;
    }

    // Otherwise, consume the back (don’t exit or go to a login screen).
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleSystemBack,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FBFF),
        // Plain AppBar (no logo, no settings). Back button appears automatically if canPop == true.
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2FBFF),
          elevation: 0,
          automaticallyImplyLeading: true, // show system back when applicable
          title: const SizedBox.shrink(), // no title/logo
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Video Study Guide',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'TT Rounds Neue Bold',
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_loadFailed || _controller == null)
                const Center(
                  child: Text(
                    'Failed to load video.',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else
                _buildVideoCard(),
            ],
          ),
        ),
        bottomNavigationBar: taskbar.CustomTaskbar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildVideoCard() {
    final isPlaying = _controller!.value.isPlaying;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grade 10 Science: Plate Tectonics',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'TT Rounds Neue Medium',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Understand how Earth’s plates move and cause natural phenomena like earthquakes and volcanoes.',
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      isPlaying ? _controller!.pause() : _controller!.play();
                    });
                  },
                ),
                Text(isPlaying ? 'Pause' : 'Play'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
