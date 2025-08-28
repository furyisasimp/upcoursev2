import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'package:career_roadmap/services/supabase_service.dart';

class Question {
  final String text;
  final List<String> options;

  Question({required this.text, required this.options});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
    );
  }
}

class QuizScreen extends StatefulWidget {
  /// Accepts legacy ids (e.g., "abm_stats") or new ids ("ABM", "GAS", "STEM", "TECHPRO")
  final String categoryId;
  const QuizScreen({Key? key, required this.categoryId}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- Category metadata (UI) ---
  static const _categoryMeta = {
    'ABM': (
      title: 'ABM — Business & Finance',
      colors: [Color(0xFF81D4FA), Color(0xFF29B6F6)],
      icon: Icons.payments_outlined,
    ),
    'GAS': (
      title: 'GAS — General Academic Strand',
      colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
      icon: Icons.menu_book_outlined,
    ),
    'STEM': (
      title: 'STEM — Science & Technology',
      colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
      icon: Icons.science_outlined,
    ),
    'TECHPRO': (
      title: 'TechPro — TVL / Tech-Voc',
      colors: [Color(0xFFFFCC80), Color(0xFFFFA726)],
      icon: Icons.build_circle_outlined,
    ),
  };

  String get _programId {
    final id = widget.categoryId.trim();
    if (id.toLowerCase().contains('abm')) return 'ABM';
    if (id.toLowerCase().contains('stem')) return 'STEM';
    if (id.toLowerCase().contains('gas')) return 'GAS';
    if (id.toLowerCase().contains('tech')) return 'TECHPRO';
    return id.toUpperCase();
  }

  // --- State ---
  final Map<int, String> _answers = {};
  final List<Question> _questions = [];
  bool _loading = true;
  bool _submitted = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFromBucket();
  }

  Future<void> _loadFromBucket() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final url = await SupabaseService.getFileUrl(
        bucket: 'quizzes',
        path: '${_programId}.json',
        expiresIn: 60 * 60, // 1 hour
      );

      if (url == null) {
        throw Exception('Quiz file not found for $_programId');
      }

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw Exception('Failed to fetch quiz (${res.statusCode})');
      }

      final List<dynamic> raw = jsonDecode(res.body) as List<dynamic>;
      _questions
        ..clear()
        ..addAll(raw.map((e) => Question.fromJson(e as Map<String, dynamic>)));

      if (_questions.isEmpty) {
        throw Exception('Quiz is empty for $_programId');
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _submit() {
    if (_answers.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please answer all questions before submitting.',
            style: TextStyle(fontFamily: 'Inter'),
          ),
        ),
      );
      return;
    }
    setState(() => _submitted = true);
  }

  void _returnHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (r) => false,
    );
  }

  // Confirm exit if quiz not submitted
  Future<bool> _confirmExit() async {
    if (_submitted) return true;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Exit Quiz?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'If you leave now, your answers will not be submitted. Are you sure you want to exit?',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Continue Quiz',
                  style: TextStyle(
                    fontFamily: 'Inter',
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
                  'Exit',
                  style: TextStyle(fontFamily: 'Inter'),
                ),
              ),
            ],
          ),
    );
    return shouldExit ?? false;
  }

  // --- UI helpers ---
  (List<Color> colors, IconData icon, String title) _meta() {
    final meta = _categoryMeta[_programId];
    if (meta != null) {
      return (meta.colors, meta.icon, meta.title);
    }
    // Fallback for unknown category ids
    return (
      const [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
      Icons.quiz_outlined,
      'Quiz — $_programId',
    );
  }

  @override
  Widget build(BuildContext context) {
    final (colors, icon, titleText) = _meta();
    final answered = _answers.length;
    final total = _questions.length;
    final progress = total == 0 ? 0.0 : answered / total;

    return WillPopScope(
      onWillPop: _confirmExit, // intercept system back / swipe
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBFF),
        appBar: AppBar(
          automaticallyImplyLeading: false, // we handle the back action
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            _submitted ? 'Results Overview' : titleText,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading:
              _submitted
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () async {
                      final ok = await _confirmExit();
                      if (ok && mounted) Navigator.pop(context);
                    },
                  ),
        ),

        // Sticky submit on bottom for nice ergonomics
        bottomNavigationBar:
            _loading || _submitted || _questions.isEmpty
                ? null
                : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Submit Quiz',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        onPressed:
                            _answers.length == _questions.length
                                ? _submit
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          disabledBackgroundColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? _ErrorState(message: _loadError!, onRetry: _loadFromBucket)
                : _questions.isEmpty
                ? const _EmptyState()
                : Column(
                  children: [
                    // Header card with icon + progress
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.last.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: Icon(icon, color: colors.last),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _submitted
                                        ? 'Submission complete'
                                        : 'Progress',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.white24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$answered of $total answered',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Questions / Results
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final q = _questions[index];
                          return _QuestionCard(
                            index: index,
                            question: q,
                            selected: _answers[index],
                            submitted: _submitted,
                            accent: colors.last,
                            onChanged: (val) {
                              if (_submitted) return;
                              setState(() => _answers[index] = val);
                            },
                          );
                        },
                      ),
                    ),

                    if (_submitted)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.last, width: 1.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _returnHome,
                            child: const Text(
                              'Return Home',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Question question;
  final String? selected;
  final bool submitted;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.submitted,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${index + 1}. ${question.text}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (!submitted)
              ...question.options.map(
                (opt) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        selected == opt
                            ? accent.withOpacity(0.08)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == opt ? accent : Colors.grey.shade300,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: opt,
                    groupValue: selected,
                    onChanged: (v) => onChanged(v!),
                    dense: true,
                    activeColor: accent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    title: Text(
                      opt,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected ?? '—',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: accent,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 10),
            const Text(
              'Could not load quiz',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(fontFamily: 'Inter')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No questions available.',
        style: TextStyle(fontFamily: 'Inter'),
      ),
    );
  }
}
