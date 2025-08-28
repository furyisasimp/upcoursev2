import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:career_roadmap/services/supabase_service.dart';
import 'package:career_roadmap/screens/questionnaire_intro_screen.dart';
import 'package:career_roadmap/screens/exploration_screen.dart';
import 'package:career_roadmap/screens/skills_screen.dart';
import 'package:career_roadmap/screens/resources_screen.dart';
import '../widgets/custom_taskbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _firstName = 'Guest';
  String _gradeLevel = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getMyProfile();

      if (profile != null) {
        setState(() {
          _firstName = profile['first_name'] ?? 'Guest';
          _gradeLevel = profile['grade_level']?.toString() ?? '';
        });
      } else {
        setState(() {
          _firstName = SupabaseService.authEmail ?? 'Guest';
        });
      }
    } catch (_) {
      setState(() {
        _firstName = SupabaseService.authEmail ?? 'Guest';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth =
        (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top header ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3EB6FF),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $_firstName',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _gradeLevel.isNotEmpty
                              ? 'Grade $_gradeLevel – Web Developer Track'
                              : 'Student',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Navigation pills ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navPill(
                      icon: Icons.home,
                      label: 'Home',
                      selected: true,
                      onTap: () {},
                    ),
                    _navPill(
                      icon: Icons.receipt_long,
                      label: 'Assessment',
                      selected: false,
                      onTap:
                          () => Navigator.push(
                            context,
                            _buildPageRoute(const QuestionnaireIntroScreen()),
                          ),
                    ),
                    _navPill(
                      icon: Icons.explore,
                      label: 'Exploration',
                      selected: false,
                      onTap:
                          () => Navigator.push(
                            context,
                            _buildPageRoute(const ExplorationScreen()),
                          ),
                    ),
                    _navPill(
                      icon: Icons.fitness_center,
                      label: 'Skills',
                      selected: false,
                      onTap:
                          () => Navigator.pushReplacement(
                            context,
                            _buildPageRoute(const SkillsScreen()),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick Actions ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _quickActionButton(
                          width: buttonWidth,
                          icon: Icons.book,
                          label: 'NCAE Review',
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResourcesScreen(),
                                ),
                              ),
                        ),
                        _quickActionButton(
                          width: buttonWidth,
                          icon: Icons.quiz,
                          label: 'Take Quiz',
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const QuestionnaireIntroScreen(),
                                ),
                              ),
                        ),
                        _quickActionButton(
                          width: buttonWidth,
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat AI',
                          onTap: () {
                            // TODO
                          },
                        ),
                        _quickActionButton(
                          width: buttonWidth,
                          icon: Icons.show_chart,
                          label: 'Market Insights',
                          onTap: () {
                            // TODO
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Main Progress Card ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Progress',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          CircularPercentIndicator(
                            radius: 54,
                            lineWidth: 10,
                            percent: 0.3243,
                            center: const Text(
                              "32.43%",
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            progressColor: const Color(0xFF3EB6FF),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          CircularPercentIndicator(
                            radius: 54,
                            lineWidth: 10,
                            percent: 0.481,
                            center: const Text(
                              "48.1%",
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            progressColor: const Color(0xFF3EB6FF),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'NCAE Prep',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Assessment',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Focus Areas',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _progressRow('Programming Logic', 0.7, 0.3),
                      _progressRow('Problem Solving', 0.5, 0.4),
                      _progressRow('Communication', 0.8, 0.2),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomTaskbar(
        selectedIndex: 0,
        onItemTapped: (index) {},
      ),
    );
  }

  Widget _navPill({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? const Color(0xFF3EB6FF) : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: selected ? const Color(0xFF3EB6FF) : Colors.grey[700],
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required double width,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _progressRow(String label, double primary, double secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (primary * 100).toInt(),
                  child: Container(height: 8, color: const Color(0xFF3EB6FF)),
                ),
                Expanded(
                  flex: (secondary * 100).toInt(),
                  child: Container(height: 8, color: Colors.grey.shade200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Route _buildPageRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (c, a, sa) => screen,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (c, anim, sa, child) {
        final tween = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        final fade = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: anim.drive(tween),
          child: FadeTransition(opacity: anim.drive(fade), child: child),
        );
      },
    );
  }
}
