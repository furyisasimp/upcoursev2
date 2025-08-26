import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'quiz_intro_screen.dart';
import '../widgets/custom_taskbar.dart';

class QuizCategoriesScreen extends StatefulWidget {
  const QuizCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<QuizCategoriesScreen> createState() => _QuizCategoriesScreenState();
}

class _QuizCategoriesScreenState extends State<QuizCategoriesScreen> {
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'ABM: Statistics & Probability',
      'id': 'abm_stats',
      'icon': Icons.calculate,
      'color': const Color(0xFF3EB6FF),
    },
    {
      'title': 'STEM: Physics Fundamentals',
      'id': 'stem_physics',
      'icon': Icons.science,
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'HUMSS: World History',
      'id': 'humss_history',
      'icon': Icons.public,
      'color': const Color(0xFFFF7043),
    },
  ];

  int _selectedIndex = 2;
  final Map<int, bool> _hovering = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _categories.length; i++) {
      _hovering[i] = false;
    }
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
            (context, animation, secondaryAnimation) =>
                QuizIntroScreen(categoryId: categoryId),
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

      // Plain, light AppBar—just like in resources_screen.dart
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🚫 disables back button
        backgroundColor: const Color(0xFFF0F8FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quiz Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            final isHovered = _hovering[i]!;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovering[i] = true),
              onExit: (_) => setState(() => _hovering[i] = false),
              child: AnimatedScale(
                scale: isHovered ? 1.03 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: color.withOpacity(0.3),
                    onTap: () => _navigateToIntro(cat['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isHovered ? 0.4 : 0.3),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(isHovered ? 0.6 : 0.4),
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
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'TT Rounds Neue Medium',
                              color: Colors.black87,
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
