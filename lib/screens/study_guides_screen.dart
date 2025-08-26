// lib/screens/study_guides_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:career_roadmap/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyGuidesScreen extends StatefulWidget {
  const StudyGuidesScreen({Key? key}) : super(key: key);

  @override
  _StudyGuidesScreenState createState() => _StudyGuidesScreenState();
}

class _StudyGuidesScreenState extends State<StudyGuidesScreen> {
  List<FileObject> _files = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    debugPrint("📂 Fetching study guide files from Supabase bucket...");
    try {
      // ✅ Explicitly fetch files from root of `my-study-guides`
      final files = await Supabase.instance.client.storage
          .from('my-study-guides')
          .list(path: ""); // root folder

      debugPrint("✅ Files fetched: ${files.map((f) => f.name).toList()}");

      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint("❌ Error fetching files: $e\n$st");
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openPdf(String fileName) async {
    try {
      debugPrint("📥 Opening PDF: $fileName");

      final pdfUrl = await SupabaseService.getPdfUrl(fileName);
      if (pdfUrl == null) throw 'Failed to fetch PDF URL';

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw 'Error downloading PDF: HTTP ${response.statusCode}';
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(path: file.path, title: fileName),
        ),
      );
    } catch (e, st) {
      debugPrint("❌ Failed to open PDF: $e\n$st");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Guides')),
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
        appBar: AppBar(title: const Text('Study Guides')),
        body: Center(
          child: Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Guides')),
        body: const Center(
          child: Text("📄 No study guides found in Supabase bucket."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Guides'),
        backgroundColor: const Color(0xFF3EB6FF),
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(file.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openPdf(file.name),
          );
        },
      ),
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
