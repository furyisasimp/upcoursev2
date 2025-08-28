import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quiz_categories_screen.dart';
import 'profile_details_screen.dart';
import '../widgets/custom_taskbar.dart';

class ExplorationScreen extends StatelessWidget {
  const ExplorationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Exploration',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                'Recommended SHS Strands',
                'Based on your assessment results',
              ),

              _shsStrandCard(
                context,
                title: 'STEM',
                match: '95%',
                description: 'Science, Technology, Engineering, Mathematics',
                points: [
                  'High demand in tech industry',
                  'Avg salary: ₱45,000–₱60,000',
                  '15,000+ job openings in Metro Manila',
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
                ),
                badgeColor: Colors.blue,
                icon: Icons.science,
              ),

              const SizedBox(height: 12),

              _shsStrandCard(
                context,
                title: 'ICT',
                match: '88%',
                description: 'Information & Communications Technology',
                points: [
                  'Growing digital economy',
                  'Avg salary: ₱35,000–₱70,000',
                  '8,500+ job openings nationwide',
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
                ),
                badgeColor: Colors.deepPurple,
                icon: Icons.computer,
              ),

              const SizedBox(height: 20),

              _sectionTitle('College Pathways', null),
              _pathwayTile('Computer Science', '4 years · High employability'),
              _pathwayTile(
                'Information Technology',
                '4 years · Industry partnerships',
              ),
              _pathwayTile(
                'Software Engineering',
                '4 years · High starting salary',
              ),

              const SizedBox(height: 20),

              _sectionTitle('Real-Time Market Insights', null),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    left: BorderSide(color: Colors.green, width: 3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _insightBox(
                          title: '↑ 15%',
                          subtitle: 'STEM Job Growth',
                          color: Colors.green,
                        ),
                        _insightBox(
                          title: '₱52K',
                          subtitle: 'Avg Starting Salary',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "View Detailed Market Report",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _sectionTitle('AI Career Counselor', null),
              _aiCounselorCard(),

              const SizedBox(height: 40),
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
                MaterialPageRoute(builder: (_) => const QuizCategoriesScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _sectionTitle(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _shsStrandCard(
    BuildContext context, {
    required String title,
    required String match,
    required String description,
    required List<String> points,
    required LinearGradient gradient,
    required Color badgeColor,
    required IconData icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title tapped!'))),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: badgeColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$match Match',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $p',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pathwayTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Inter')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _aiCounselorCard() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.green),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Counselor Available',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Get instant answers about career paths, requirements, and opportunities.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'In Development',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.video_call_outlined, color: Colors.indigo),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Schedule with Counselor',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lowercase “i” here matches the calls above:
class _insightBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _insightBox({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
