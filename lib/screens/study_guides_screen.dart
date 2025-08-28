// lib/screens/study_guides_screen.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:career_roadmap/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyGuidesScreen extends StatefulWidget {
  const StudyGuidesScreen({Key? key}) : super(key: key);

  @override
  State<StudyGuidesScreen> createState() => _StudyGuidesScreenState();
}

class _StudyGuidesScreenState extends State<StudyGuidesScreen> {
  final _client = http.Client();

  List<FileObject> _files = [];
  List<FileObject> _filtered = [];
  bool _loading = true;
  String? _errorMessage;

  // UI helpers
  String _query = '';
  bool _grid = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final files = await Supabase.instance.client.storage
          .from('my-study-guides')
          .list(path: ''); // root

      // Keep only PDFs and sort A→Z by name
      files.retainWhere((f) => f.name.toLowerCase().endsWith('.pdf'));
      files.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      setState(() {
        _files = files;
        _filtered = _applyFilter(_files, _query);
        _loading = false;
      });

      debugPrint("✅ Files fetched: ${files.map((f) => f.name).toList()}");
    } catch (e, st) {
      debugPrint("❌ Error fetching files: $e\n$st");
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  List<FileObject> _applyFilter(List<FileObject> list, String q) {
    if (q.trim().isEmpty) return list;
    final ql = q.toLowerCase();
    return list.where((f) => f.name.toLowerCase().contains(ql)).toList();
  }

  Future<String> _downloadToCache({
    required String url,
    required String key,
  }) async {
    // cache dir
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/study_guides');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final safeName = key.replaceAll('/', '_');
    final file = File('${cacheDir.path}/$safeName');

    // already cached
    if (await file.exists()) return file.path;

    // Simple indeterminate progress dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            title: Text('Downloading…'),
            content: Padding(
              padding: EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(),
            ),
          ),
    );

    try {
      final req = http.Request('GET', Uri.parse(url));
      final res = await _client.send(req);
      if (res.statusCode != 200) {
        throw 'HTTP ${res.statusCode}';
      }

      final sink = file.openWrite();
      await res.stream.pipe(sink);
      await sink.close();

      if (mounted) Navigator.of(context).pop(); // close dialog
      return file.path;
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // ensure dialog closes on error
      }
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  Future<void> _openPdf(FileObject file) async {
    try {
      final key = file.name; // if you add subfolders later, prefix here
      final pdfUrl = await SupabaseService.getFileUrl(
        bucket: 'my-study-guides',
        path: key,
        expiresIn: 3600,
      );
      if (pdfUrl == null) throw 'Failed to get file URL';

      final localPath = await _downloadToCache(url: pdfUrl, key: key);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(path: localPath, title: file.name),
        ),
      );
    } catch (e, st) {
      debugPrint("❌ Failed to open PDF: $e\n$st");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
    }
  }

  String _prettyName(String raw) {
    final noExt = raw.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    return noExt.replaceAll(RegExp(r'[_\-]+'), ' ');
  }

  String _formatBytes(dynamic size) {
    if (size == null) return '';
    final s = (size is int) ? size : int.tryParse(size.toString()) ?? 0;
    if (s <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB'];
    int i = (log(s) / log(1024)).floor();
    final value = s / pow(1024, i);
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[min(i, units.length - 1)]}';
  }

  // Accepts either DateTime? or String? (ISO) — avoids the type error
  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    DateTime? d;
    if (dt is DateTime) {
      d = dt;
    } else if (dt is String) {
      d = DateTime.tryParse(dt);
    }
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _onRefresh() => _loadFiles();

  @override
  Widget build(BuildContext context) {
    const title = 'Study Guides';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text("Loading study guides..."),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
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
        ),
      );
    }

    if (_files.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: const Center(
          child: Text("📄 No study guides found in Supabase bucket."),
        ),
      );
    }

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
                hintText: 'Search PDFs…',
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _grid ? _buildGrid() : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final file = _filtered[index];
        final meta = (file.metadata ?? const {}) as Map<String, dynamic>;
        final size = _formatBytes(meta['size']);
        final updated = _formatDate(file.updatedAt ?? file.createdAt);

        return ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
          title: Text(
            _prettyName(file.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (size.isNotEmpty) size,
              if (updated.isNotEmpty) '• $updated',
            ].join(' '),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _openPdf(file),
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
      itemBuilder: (context, index) {
        final file = _filtered[index];
        final meta = (file.metadata ?? const {}) as Map<String, dynamic>;
        final size = _formatBytes(meta['size']);
        final updated = _formatDate(file.updatedAt ?? file.createdAt);

        return InkWell(
          onTap: () => _openPdf(file),
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
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                const SizedBox(height: 8),
                Text(
                  _prettyName(file.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  [
                    if (size.isNotEmpty) size,
                    if (updated.isNotEmpty) '• $updated',
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
}

class PdfViewerScreen extends StatelessWidget {
  final String path;
  final String title;

  const PdfViewerScreen({Key? key, required this.path, required this.title})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF3EB6FF),
      ),
      body: PDFView(
        filePath: path,
        enableSwipe: true,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          debugPrint("❌ PDF view error: $error");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF view error: $error')));
        },
        onPageError: (page, error) {
          debugPrint("❌ Error on page $page: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error on page $page: $error')),
          );
        },
      ),
    );
  }
}
