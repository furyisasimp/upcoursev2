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

    await SupabaseService.updateQuizProgress(
      widget.quizId,
      status: "completed",
      score: score,
      answers: answers,
    );
  }

  Future<bool> _onWillPop() async {
    if (submitted) return true; // ✅ Allow exit if finished

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // force explicit choice
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Exit Quiz?",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            "If you leave now, your progress will not be saved. "
            "Are you sure you want to quit the quiz?",
            style: TextStyle(fontFamily: 'Inter', fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Continue Quiz",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3EB6FF),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Exit",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: const Color(0xFF3EB6FF),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true, // show back button, but controlled
        ),
        body: Column(
          children: [
            if (!submitted)
              LinearProgressIndicator(
                value: answers.length / questions.length,
                backgroundColor: Colors.grey[300],
                color: const Color(0xFF3EB6FF),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...questions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Q${idx + 1}. ${q['text']}",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...q['options'].asMap().entries.map((opt) {
                              final optIndex = opt.key;
                              final isSelected = answers[idx] == optIndex;
                              final isCorrect = q['correct_index'] == optIndex;

                              Color? tileColor;
                              if (submitted) {
                                if (isCorrect) {
                                  tileColor = Colors.green.withOpacity(0.15);
                                } else if (isSelected && !isCorrect) {
                                  tileColor = Colors.red.withOpacity(0.15);
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF3EB6FF)
                                            : Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                ),
                                child: RadioListTile<int>(
                                  value: optIndex,
                                  groupValue: answers[idx],
                                  title: Text(
                                    opt.value,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  activeColor: const Color(0xFF3EB6FF),
                                  onChanged:
                                      submitted
                                          ? null
                                          : (val) => setState(() {
                                            answers[idx] = val!;
                                          }),
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
                      onPressed:
                          answers.length == questions.length ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3EB6FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Submit Quiz",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          "Your Score: $score%",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: score >= 60 ? Colors.green : Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SkillsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3EB6FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Back to Skill Development",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
