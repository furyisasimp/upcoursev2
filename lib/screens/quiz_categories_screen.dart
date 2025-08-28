import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'quiz_intro_screen.dart';
import '../widgets/custom_taskbar.dart';
import 'package:career_roadmap/services/supabase_service.dart';

class QuizCategoriesScreen extends StatefulWidget {
  const QuizCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<QuizCategoriesScreen> createState() => _QuizCategoriesScreenState();
}

class _QuizCategoriesScreenState extends State<QuizCategoriesScreen> {
  // UI meta for known strands
  static const Map<String, ({String title, IconData icon, Color color})> _meta =
      {
        'ABM': (
          title: 'ABM — Business & Finance',
          icon: Icons.payments_outlined,
          color: Color(0xFF3EB6FF),
        ),
        'GAS': (
          title: 'GAS — General Academic Strand',
          icon: Icons.menu_book_outlined,
          color: Color(0xFF7E57C2),
        ),
        'STEM': (
          title: 'STEM — Science & Technology',
          icon: Icons.science_outlined,
          color: Color(0xFF4CAF50),
        ),
        'TECHPRO': (
          title: 'TechPro — TVL / Tech-Voc',
          icon: Icons.build_circle_outlined,
          color: Color(0xFFFF7043),
        ),
      };

  List<Map<String, dynamic>> _categories = [];
  final Map<int, bool> _hovering = {};
  bool _loading = true;
  String? _error;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
      _categories = [];
      _hovering.clear();
    });

    try {
      final files = await SupabaseService.listFiles(
        bucket: 'quizzes',
        path: '',
      );
      // Expect filenames like ABM.json, STEM.json, etc.
      final ids =
          files
              .where((f) => f.toLowerCase().endsWith('.json'))
              .map((f) => f.substring(0, f.length - 5).toUpperCase())
              .toSet()
              .toList();

      if (ids.isEmpty) {
        // Fallback to defaults if bucket is empty
        _applyFallback();
      } else {
        _categories =
            ids.map((id) {
              final info =
                  _meta[id] ??
                  (
                    title: '$id — Practice Quiz',
                    icon: Icons.quiz_outlined,
                    color: const Color(0xFF81D4FA),
                  );
              return {
                'id': id,
                'title': info.title,
                'icon': info.icon,
                'color': info.color,
              };
            }).toList();
      }
    } catch (e) {
      _applyFallback();
      _error = e.toString();
      // Non-fatal: we show fallback + a snack
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Showing default categories (fetch failed): $e'),
          ),
        );
      }
    } finally {
      // init hover map
      for (var i = 0; i < _categories.length; i++) {
        _hovering[i] = false;
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFallback() {
    _categories =
        _meta.entries
            .map(
              (e) => {
                'id': e.key,
                'title': e.value.title,
                'icon': e.value.icon,
                'color': e.value.color,
              },
            )
            .toList();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToIntro(String categoryId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder:
            (context, animation, secondaryAnimation) => QuizIntroScreen(
              categoryId: categoryId,
            ), // Passes ABM/GAS/STEM/TECHPRO
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF0F8FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quiz Categories',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
              ? _EmptyState(onRetry: _loadCategories, error: _error)
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final color = cat['color'] as Color;
                    final isHovered = kIsWeb ? (_hovering[i] ?? false) : false;

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) {
                        if (!kIsWeb) return;
                        setState(() => _hovering[i] = true);
                      },
                      onExit: (_) {
                        if (!kIsWeb) return;
                        setState(() => _hovering[i] = false);
                      },
                      child: AnimatedScale(
                        scale: isHovered ? 1.03 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            splashColor: color.withOpacity(0.25),
                            onTap: () => _navigateToIntro(cat['id'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: color.withOpacity(
                                  isHovered ? 0.42 : 0.32,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(
                                      isHovered ? 0.55 : 0.35,
                                    ),
                                    blurRadius: isHovered ? 10 : 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withOpacity(0.9),
                                    radius: 28,
                                    child: Icon(
                                      cat['icon'] as IconData,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    cat['title'] as String,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap to practice',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      bottomNavigationBar: CustomTaskbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  final String? error;
  const _EmptyState({required this.onRetry, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 10),
            const Text(
              'No quiz categories found',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter'),
              ),
            ],
            const SizedBox(height: 12),
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
