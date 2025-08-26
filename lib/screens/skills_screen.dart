// lib/screens/skills_screen.dart
import 'package:flutter/material.dart';
import 'package:career_roadmap/widgets/custom_taskbar.dart';
import 'home_screen.dart';
import 'resources_screen.dart';
import 'quiz_categories_screen.dart';
import 'profile_details_screen.dart';
import 'package:career_roadmap/services/supabase_service.dart';
import 'package:career_roadmap/routes/route_tracker.dart';

// Import adaptive screens
import 'adaptive_lesson_screen.dart';
import 'adaptive_quiz_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({Key? key}) : super(key: key);

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _skills = [];
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    final skills = await SupabaseService.getSkillProgress();
    final quizzes = await SupabaseService.getQuizProgress();

    setState(() {
      _skills = skills;
      _quizzes = quizzes;
      _isLoading = false;
    });
  }

  Future<bool> _handleBack(BuildContext context) async {
    final nav = Navigator.of(context);

    if (nav.canPop()) {
      nav.pop();
      return false;
    }

    try {
      final last = RouteTracker.instance.lastRouteName;
      if (last != null && last.isNotEmpty) {
        nav.pushReplacementNamed(last);
        return false;
      }
    } catch (_) {}

    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const ResourcesScreen()),
    );
    return false;
  }

  Widget _buildSkillCard({
    required String title,
    required String level,
    required int lessonsCompleted,
    required int lessonsTotal,
    bool isPrimary = false,
  }) {
    final progress = lessonsTotal > 0 ? lessonsCompleted / lessonsTotal : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFEFF6FF) : Colors.white,
        border: Border.all(
          color: isPrimary ? const Color(0xFF3B82F6) : Colors.grey.shade300,
          width: isPrimary ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isPrimary
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPrimary ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lessons
          Text('$lessonsCompleted / $lessonsTotal lessons completed'),
          const SizedBox(height: 4),

          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: Colors.black,
            minHeight: 8,
          ),
          const SizedBox(height: 12),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AdaptiveLessonScreen(
                              moduleId: title,
                              title: title.replaceAll('_', ' ').toUpperCase(),
                            ),
                      ),
                    ).then((_) => _loadProgress());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Continue Learning"),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final url = await SupabaseService.getFileUrl(
                    bucket: "skill-modules",
                    path: "$title.json",
                  );
                  if (!mounted) return;
                  if (url != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Download started: $url")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black12),
                ),
                child: const Text("Download"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quizCard(Map<String, dynamic> quiz) {
    final status = quiz['status'] ?? 'locked';
    final score = quiz['score'];
    final isCompleted = status == 'completed';
    final isLocked = status == 'locked';

    String subtitle;
    if (isCompleted) {
      subtitle = "Completed • Score: ${score ?? '--'}%";
    } else if (status == 'in_progress') {
      subtitle = "In Progress";
    } else {
      subtitle = "Locked • Complete previous quiz";
    }

    return Opacity(
      opacity: isLocked ? 0.4 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color:
              isCompleted
                  ? const Color(0xFFDFFFE0)
                  : isLocked
                  ? Colors.grey.shade100
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle
                  : isLocked
                  ? Icons.lock
                  : Icons.play_arrow,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (quiz['quiz_id'] as String)
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            if (!isLocked)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AdaptiveQuizScreen(
                            quizId: quiz['quiz_id'],
                            title:
                                (quiz['quiz_id'] as String)
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                          ),
                    ),
                  ).then((_) => _loadProgress());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(isCompleted ? "View" : "Start"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _handleBack(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBFF),
        appBar: AppBar(
          title: const Text('Skill Development'),
          backgroundColor: const Color(0xFF3EB6FF),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(onPressed: () => _handleBack(context)),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Skill Development Modules",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Adaptive learning for your chosen path"),
                        const SizedBox(height: 16),

                        // Dynamic Skill Cards
                        for (var i = 0; i < _skills.length; i++)
                          _buildSkillCard(
                            title: _skills[i]['module_id'],
                            level: "Level ${(i + 1)}",
                            lessonsCompleted: _skills[i]['lessons_completed'],
                            lessonsTotal: _skills[i]['lessons_total'] ?? 0,
                            isPrimary: i == 0,
                          ),

                        const SizedBox(height: 30),
                        const Text(
                          "Adaptive Quizzes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Dynamic Quizzes
                        for (final quiz in _quizzes) _quizCard(quiz),
                      ],
                    ),
                  ),
                ),
        bottomNavigationBar: CustomTaskbar(
          selectedIndex: 1,
          onItemTapped: (index) {
            if (index == 1) return;
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuizCategoriesScreen(),
                  ),
                );
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileDetailsScreen(),
                  ),
                );
                break;
            }
          },
        ),
      ),
    );
  }
}
