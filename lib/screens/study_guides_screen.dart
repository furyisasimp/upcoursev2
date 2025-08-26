// lib/screens/study_guides_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:career_roadmap/services/aws_service.dart';
import 'package:http/http.dart' as http;

class StudyGuidesScreen extends StatefulWidget {
  const StudyGuidesScreen({Key? key}) : super(key: key);

  @override
  _StudyGuidesScreenState createState() => _StudyGuidesScreenState();
}

class _StudyGuidesScreenState extends State<StudyGuidesScreen> {
  String? _localFilePath;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAndCachePdf();
  }

  Future<void> _loadAndCachePdf() async {
    try {
      // 1. Fetch the public PDF URL from your API
      final pdfUrl = await AwsService.fetchPdfUrl(
        'el-filibusterismo-modyul-8.pdf',
      );
      if (pdfUrl == null) {
        throw 'Failed to fetch PDF URL';
      }

      // 2. Download the PDF bytes
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw 'Error downloading PDF: HTTP ${response.statusCode}';
      }

      // 3. Save to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/el-filibusterismo-modyul-8.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      setState(() {
        _localFilePath = file.path;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Guides')),
        body: const Center(child: CircularProgressIndicator()),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Guides'),
        backgroundColor: const Color(0xFF3EB6FF),
      ),
      body: PDFView(
        filePath: _localFilePath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF view error: $error')));
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error on page $page: $error')),
          );
        },
      ),
    );
  }
}
