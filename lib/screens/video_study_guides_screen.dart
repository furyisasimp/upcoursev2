import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:career_roadmap/widgets/custom_taskbar.dart' as taskbar;
import 'package:career_roadmap/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoStudyGuidesScreen extends StatefulWidget {
  static const routeName = '/video-study-guides';

  const VideoStudyGuidesScreen({Key? key}) : super(key: key);

  @override
  State<VideoStudyGuidesScreen> createState() => _VideoStudyGuidesScreenState();
}

class _VideoStudyGuidesScreenState extends State<VideoStudyGuidesScreen> {
  List<FileObject> _files = [];
  List<FileObject> _filtered = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  bool _grid = false;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SupabaseService.listVideoFiles();
      // keep only common video types
      list.retainWhere((f) {
        final n = f.name.toLowerCase();
        return n.endsWith('.mp4') ||
            n.endsWith('.mov') ||
            n.endsWith('.m4v') ||
            n.endsWith('.webm');
      });
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _files = list;
        _filtered = _applyFilter(list, _query);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<FileObject> _applyFilter(List<FileObject> list, String q) {
    if (q.trim().isEmpty) return list;
    final lq = q.toLowerCase();
    return list.where((f) => f.name.toLowerCase().contains(lq)).toList();
  }

  String _prettyName(String raw) => raw
      .replaceAll(RegExp(r'\.(mp4|mov|m4v|webm)$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[_\-]+'), ' ');

  String _formatBytes(dynamic size) {
    if (size == null) return '';
    final s = (size is int) ? size : int.tryParse(size.toString()) ?? 0;
    if (s <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB'];
    final i = min(units.length - 1, (log(s) / log(1024)).floor());
    final v = s / pow(1024, i);
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[i]}';
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    DateTime? d;
    if (dt is DateTime)
      d = dt;
    else if (dt is String)
      d = DateTime.tryParse(dt);
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    const title = 'Video Study Guides';
    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        backgroundColor: const Color(0xFF3EB6FF),
        actions: [
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged:
                  (v) => setState(() {
                    _query = v;
                    _filtered = _applyFilter(_files, _query);
                  }),
              decoration: InputDecoration(
                hintText: 'Search videos…',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue.shade100),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF2FBFF),
      body: SafeArea(
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadFiles,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
                : _filtered.isEmpty
                ? const Center(child: Text('No videos found.'))
                : (_grid ? _buildGrid() : _buildList()),
      ),
      bottomNavigationBar: taskbar.CustomTaskbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final f = _filtered[i];
        final meta = (f.metadata ?? const {}) as Map<String, dynamic>;
        final size = _formatBytes(meta['size']);
        final date = _formatDate(f.updatedAt ?? f.createdAt);

        return ListTile(
          leading: const Icon(
            Icons.play_circle_fill,
            color: Colors.blue,
            size: 28,
          ),
          title: Text(
            _prettyName(f.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (size.isNotEmpty) size,
              if (date.isNotEmpty) '• $date',
            ].join(' '),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _openPlayer(context, f.name),
        );
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3 / 2,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final f = _filtered[i];
        final meta = (f.metadata ?? const {}) as Map<String, dynamic>;
        final size = _formatBytes(meta['size']);
        final date = _formatDate(f.updatedAt ?? f.createdAt);

        return InkWell(
          onTap: () => _openPlayer(context, f.name),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  _prettyName(f.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  [
                    if (size.isNotEmpty) size,
                    if (date.isNotEmpty) '• $date',
                  ].join(' '),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPlayer(BuildContext context, String key) async {
    // safer: signed URL works for both public/private buckets
    final url = await SupabaseService.getFileUrl(
      bucket: 'study-guide-videos',
      path: key,
      expiresIn: 3600,
    );
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to get video URL')));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(title: _prettyName(key), url: url),
      ),
    );
  }
}

/// Player page with custom controls (play/pause, seek, ±10s, mute, speed, fullscreen).
class _VideoPlayerPage extends StatefulWidget {
  final String title;
  final String url;
  const _VideoPlayerPage({required this.title, required this.url});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _loading = true;
  bool _error = false;
  bool _muted = false;
  double _speed = 1.0;
  bool _controlsVisible = true;
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.dispose();
    if (_fullscreen) _exitFullscreen();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause when app goes background
    if (state != AppLifecycleState.resumed) {
      _c?.pause();
    }
  }

  Future<void> _init() async {
    try {
      final c =
          VideoPlayerController.networkUrl(Uri.parse(widget.url))
            ..addListener(() => mounted ? setState(() {}) : null)
            ..setLooping(false);
      await c.initialize();
      await c.setVolume(1.0);
      setState(() {
        _c = c;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() => _fullscreen = true);
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    setState(() => _fullscreen = false);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    return WillPopScope(
      onWillPop: () async {
        if (_fullscreen) {
          await _exitFullscreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color(0xFF3EB6FF),
          actions: [
            IconButton(
              tooltip: _fullscreen ? 'Exit full screen' : 'Full screen',
              icon: Icon(
                _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              ),
              onPressed:
                  () => _fullscreen ? _exitFullscreen() : _enterFullscreen(),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error || _c == null
                ? const Center(
                  child: Text(
                    'Failed to load video',
                    style: TextStyle(color: Colors.red),
                  ),
                )
                : GestureDetector(
                  onTap:
                      () =>
                          setState(() => _controlsVisible = !_controlsVisible),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio:
                              _c!.value.aspectRatio == 0
                                  ? 16 / 9
                                  : _c!.value.aspectRatio,
                          child: VideoPlayer(_c!),
                        ),
                      ),
                      if (_controlsVisible) _buildControls(context),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final v = _c!.value;
    final pos = v.position;
    final dur = v.duration;
    final isPlaying = v.isPlaying;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek bar
          Row(
            children: [
              Text(_fmt(pos), style: const TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value:
                      pos.inMilliseconds
                          .clamp(0, dur.inMilliseconds)
                          .toDouble(),
                  min: 0,
                  max: max(1, dur.inMilliseconds).toDouble(),
                  onChanged:
                      (v) => _c!.seekTo(Duration(milliseconds: v.toInt())),
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white24,
                ),
              ),
              Text(_fmt(dur), style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          // Transport & options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Rewind 10s',
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed:
                    () => _c!.seekTo(
                      _c!.value.position - const Duration(seconds: 10),
                    ),
              ),
              IconButton(
                tooltip: isPlaying ? 'Pause' : 'Play',
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () => isPlaying ? _c!.pause() : _c!.play(),
              ),
              IconButton(
                tooltip: 'Forward 10s',
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed:
                    () => _c!.seekTo(
                      _c!.value.position + const Duration(seconds: 10),
                    ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _muted ? 'Unmute' : 'Mute',
                icon: Icon(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: () async {
                  _muted = !_muted;
                  await _c!.setVolume(_muted ? 0 : 1);
                  setState(() {});
                },
              ),
              PopupMenuButton<double>(
                tooltip: 'Speed',
                initialValue: _speed,
                onSelected: (s) async {
                  _speed = s;
                  await _c!.setPlaybackSpeed(s);
                  setState(() {});
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 0.5, child: Text('0.5×')),
                      PopupMenuItem(value: 0.75, child: Text('0.75×')),
                      PopupMenuItem(value: 1.0, child: Text('1.0×')),
                      PopupMenuItem(value: 1.25, child: Text('1.25×')),
                      PopupMenuItem(value: 1.5, child: Text('1.5×')),
                      PopupMenuItem(value: 2.0, child: Text('2.0×')),
                    ],
                child: Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_speed.toStringAsFixed(_speed % 1 == 0 ? 0 : 2)}×',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
