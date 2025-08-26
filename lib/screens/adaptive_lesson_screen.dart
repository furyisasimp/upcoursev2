import 'package:flutter/material.dart';
import 'package:career_roadmap/services/supabase_service.dart';
import 'package:career_roadmap/screens/skills_screen.dart';

class AdaptiveLessonScreen extends StatefulWidget {
  final String moduleId;
  final String title;

  const AdaptiveLessonScreen({
    super.key,
    required this.moduleId,
    required this.title,
  });

  @override
  State<AdaptiveLessonScreen> createState() => _AdaptiveLessonScreenState();
}

class _AdaptiveLessonScreenState extends State<AdaptiveLessonScreen> {
  List<Map<String, dynamic>> lessons = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final data = await SupabaseService.loadSkillModule(widget.moduleId);

    if (data.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() {
      lessons = data;
      isLoading = false;
    });

    // fetch progress so user continues where they left off
    final progress = await SupabaseService.getSkillProgress();
    final module = progress.firstWhere(
      (p) => p['module_id'] == widget.moduleId,
      orElse: () => {},
    );

    if (module.isNotEmpty) {
      setState(() {
        // lessons_completed reflects "last seen index"
        currentIndex = (module['lessons_completed'] as int?) ?? 0;
        if (currentIndex >= lessons.length) currentIndex = 0; // ✅ prevent crash
      });
    }
  }

  Future<void> _updateProgress() async {
    await SupabaseService.updateSkillProgress(
      widget.moduleId,
      currentIndex,
      lessons.length,
    );
  }

  void _nextLesson() async {
    if (currentIndex < lessons.length - 1) {
      setState(() => currentIndex++);
      await _updateProgress();
    } else {
      // ✅ On Finish
      await SupabaseService.updateSkillProgress(
        widget.moduleId,
        lessons.length,
        lessons.length,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SkillsScreen()),
      );
    }
  }

  void _prevLesson() async {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      await _updateProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (lessons.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No lessons found for this module.")),
      );
    }

    final lesson = lessons[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF3EB6FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / lessons.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            Text(
              "Lesson ${currentIndex + 1} of ${lessons.length}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lesson['content_summary'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (currentIndex > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _prevLesson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Previous"),
                    ),
                  ),
                if (currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextLesson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      currentIndex == lessons.length - 1
                          ? "Finish"
                          : "Next Lesson",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
