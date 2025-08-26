import 'package:flutter/material.dart';
import 'package:career_roadmap/services/supabase_service.dart';

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

    // Mark quiz as "in_progress" if user starts it
    await SupabaseService.updateQuizProgress(
      widget.quizId,
      status: "in_progress",
    );
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

    await SupabaseService.updateQuizProgress(
      widget.quizId,
      status: "completed",
      score: score,
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
                      "Q${idx + 1}. ${q['question']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...q['options'].asMap().entries.map((opt) {
                      return RadioListTile<int>(
                        value: opt.key,
                        groupValue: answers[idx],
                        title: Text(opt.value),
                        onChanged:
                            submitted
                                ? null
                                : (val) => setState(() => answers[idx] = val!),
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
                  onPressed: () => Navigator.pop(context),
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
