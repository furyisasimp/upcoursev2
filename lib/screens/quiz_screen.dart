import 'package:flutter/material.dart';
import 'home_screen.dart';

class Question {
  final String text;
  final List<String> options;
  Question({required this.text, required this.options});
}

class QuizScreen extends StatefulWidget {
  final String categoryId;
  const QuizScreen({Key? key, required this.categoryId}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<Question> _questions;
  final Map<int, String> _answers = {};
  bool _quizSubmitted = false;

  @override
  void initState() {
    super.initState();
    switch (widget.categoryId) {
      case 'abm_stats':
        _questions = [
          Question(
            text: "What is the mean of [2,5,7]?",
            options: ["4", "5", "6", "7"],
          ),
          Question(
            text: "P(even) on a fair die?",
            options: ["1/2", "1/3", "1/6", "1/4"],
          ),
        ];
        break;
      case 'stem_physics':
        _questions = [
          Question(
            text: "g ≈ ?",
            options: ["9.8 m/s²", "8.9", "9.8 km/s²", "10"],
          ),
        ];
        break;
      default:
        _questions = [
          Question(text: "No questions found.", options: ["OK"]),
        ];
    }
  }

  void _submitQuiz() {
    if (_answers.length != _questions.length) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text("Incomplete"),
                ],
              ),
              content: const Text("Please answer all questions."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
      );
      return;
    }

    setState(() => _quizSubmitted = true);
  }

  void _returnHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final answered = _answers.length;
    final pct = ((answered / total) * 100).toInt();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        // Gradient AppBar
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3EB6FF), Color(0xFF00E0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            _quizSubmitted ? "Results Overview" : "Quiz: ${widget.categoryId}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading:
              _quizSubmitted
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary card
              if (_quizSubmitted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF81D4FA), Color(0xFF29B6F6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$answered of $total answered",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 8,
                            width:
                                (MediaQuery.of(context).size.width - 64) *
                                (answered / total),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _returnHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                        ),
                        child: const Text(
                          "Return Home",
                          style: TextStyle(
                            color: Color(0xFF29B6F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Questions / Results list
              Expanded(
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (ctx, i) {
                    final q = _questions[i];
                    final isAnswered = _answers.containsKey(i);
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _quizSubmitted ? 1 : 1,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Q${i + 1}. ${q.text}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (!_quizSubmitted)
                                ...q.options.map(
                                  (opt) => RadioListTile<String>(
                                    dense: true,
                                    title: Text(opt),
                                    value: opt,
                                    activeColor: const Color(0xFF3EB6FF),
                                    groupValue: _answers[i],
                                    onChanged:
                                        (v) => setState(() => _answers[i] = v!),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF3EB6FF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Color(0xFF3EB6FF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _answers[i] ?? "—",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF3EB6FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (!_quizSubmitted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "Submit Quiz",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E0FF),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
