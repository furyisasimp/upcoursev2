import 'package:flutter/material.dart';
import 'package:career_roadmap/services/supabase_service.dart';
import 'package:career_roadmap/screens/skills_screen.dart';

class AdaptiveQuizScreen extends StatefulWidget {
  final String quizId;
  final String title;

  const AdaptiveQuizScreen({
    super.key,
    required this.quizId,
    required this.title,
  });

  @override
  State<AdaptiveQuizScreen> createState() => _AdaptiveQuizScreenState();
}

class _AdaptiveQuizScreenState extends State<AdaptiveQuizScreen> {
  List<Map<String, dynamic>> questions = [];
  final Map<int, int> answers = {};
  bool submitted = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final data = await SupabaseService.loadQuiz(widget.quizId);
    setState(() => questions = data);

    // ✅ Fetch existing progress
    final quizProgress = await SupabaseService.getQuizProgress();
    final thisQuiz = quizProgress.firstWhere(
      (q) => q['quiz_id'] == widget.quizId,
      orElse: () => {},
    );

    if (thisQuiz.isNotEmpty && thisQuiz['status'] == 'completed') {
      setState(() {
        submitted = true;
        score = thisQuiz['score'] ?? 0;
        if (thisQuiz['answers'] != null) {
          answers.addAll(
            (thisQuiz['answers'] as Map).map(
              (key, value) => MapEntry(int.parse(key.toString()), value as int),
            ),
          );
        }
      });
    } else {
      // Mark as in progress if never started
      await SupabaseService.updateQuizProgress(
        widget.quizId,
        status: "in_progress",
      );
    }
  }

  Future<void> _submit() async {
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i]['correct_index']) correct++;
    }

    setState(() {
      submitted = true;
      score = ((correct / questions.length) * 100).round();
    });

    // ✅ Save score + answers
    await SupabaseService.updateQuizProgress(
      widget.quizId,
      status: "completed",
      score: score,
      answers: answers,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF3EB6FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${idx + 1}. ${q['text']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...q['options'].asMap().entries.map((opt) {
                      final optIndex = opt.key;
                      final isSelected = answers[idx] == optIndex;
                      final isCorrect = q['correct_index'] == optIndex;

                      // ✅ Highlight after submission
                      Color? tileColor;
                      if (submitted) {
                        if (isCorrect) {
                          tileColor = Colors.green.withOpacity(0.2);
                        } else if (isSelected && !isCorrect) {
                          tileColor = Colors.red.withOpacity(0.2);
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RadioListTile<int>(
                              value: optIndex,
                              groupValue: answers[idx],
                              title: Text(opt.value),
                              onChanged:
                                  submitted
                                      ? null
                                      : (val) =>
                                          setState(() => answers[idx] = val!),
                            ),
                            if (submitted)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  bottom: 6,
                                  right: 16,
                                ),
                                child: Row(
                                  children: [
                                    if (isCorrect)
                                      const Text(
                                        "✔ Correct",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    else if (isSelected && !isCorrect)
                                      const Text(
                                        "✘ Your Answer",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          if (!submitted)
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Submit Quiz"),
            )
          else
            Column(
              children: [
                Text(
                  "Your Score: $score%",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SkillsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3EB6FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Back to Skill Development"),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
