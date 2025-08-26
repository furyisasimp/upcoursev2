import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const ResultsScreen({super.key, required this.results});

  // Full names for categories
  final Map<String, String> categoryNames = const {
    'A': 'Science',
    'B': 'Natural Sciences',
    'C': 'Agriculture & Forestry',
    'D': 'Engineering',
    'E': 'Business & Finance / Commerce',
    'F': 'Personal Services',
    'G': 'Community Services / Law Enforcement',
    'H': 'Professional Services',
    'I': 'Computers & Technology',
    'J': 'Education / Teaching',
    'K': 'Architecture & Construction',
    'L': 'The Arts',
    'M': 'Fashion / Garments',
    'N': 'Military & Law',
    'O': 'Spiritual Vocation',
  };

  // Short codes for chart
  final Map<String, String> shortCategoryNames = const {
    'A': 'Sci',
    'B': 'NatSci',
    'C': 'Agri',
    'D': 'Eng',
    'E': 'Bus',
    'F': 'Pers',
    'G': 'Comm',
    'H': 'Prof',
    'I': 'Tech',
    'J': 'Edu',
    'K': 'Arch',
    'L': 'Arts',
    'M': 'Fash',
    'N': 'Mil',
    'O': 'Spir',
  };

  // Career matches (unchanged)
  final Map<String, List<String>> occupationalMatches = const {
    'A': [
      'Biochemist',
      'Microbiologist',
      'Pharmacologist',
      'Medical Technologist',
      'Chemist',
      'Medical Doctor',
      'Nutritionist/Dietitian',
      'Optometrist',
      'Dentist',
      'Physical Therapist',
    ],
    'B': [
      'Meteorologist',
      'Marine Biologist',
      'Zoologist',
      'Botanist',
      'Ecologist',
      'Geologist',
      'Wildlife Biologist',
      'Seismologist',
    ],
    'C': [
      'Farmer',
      'Fish Hatchery Technician',
      'Poultry Farm Attendant',
      'Forest Technician',
      'Horticulturist',
      'Veterinarian',
      'Farm Machinery Mechanic',
    ],
    'D': [
      'Electrical Engineer',
      'Mechanical Engineer',
      'Industrial Engineer',
      'Mining Engineer',
      'Civil Engineer',
      'Electronics and Communication Engineer',
      'Chemical Engineer',
      'Sanitary Engineer',
      'Environmental Engineer',
    ],
    'E': [
      'Bank Teller',
      'Bookkeeper',
      'Entrepreneur',
      'Accountant',
      'Sales Agent',
      'Insurance Agent',
      'Business Manager',
      'Auditor',
      'Marketing Officer',
    ],
    'F': [
      'Flight Steward',
      'Receptionist',
      'Hotel Manager',
      'Tour Guide',
      'Travel Agent',
      'Waiter/Waitress',
      'Customer Service Representative',
    ],
    'G': [
      'Police Officer',
      'Fireman',
      'Barangay Tanod',
      'Barangay Chairman',
      'Barangay Councilor',
      'Security Guard',
      'Community Welfare Officer',
    ],
    'H': [
      'Lawyer',
      'News Writer',
      'Editor',
      'Librarian',
      'Historian',
      'Social Scientist',
      'Public Relations Officer',
    ],
    'I': [
      'Computer Programmer',
      'Systems Analyst',
      'Network Administrator',
      'Computer Engineer',
      'Web Designer',
      'Multimedia Artist',
      'Database Analyst',
    ],
    'J': [
      'Elementary School Teacher',
      'Secondary School Teacher',
      'College Instructor',
      'Guidance Counselor',
      'School Principal',
      'Curriculum Developer',
    ],
    'K': [
      'Architect',
      'Interior Designer',
      'Landscape Architect',
      'Building Contractor',
      'Draftsman',
      'Structural Designer',
    ],
    'L': [
      'Painter',
      'Sculptor',
      'Musician',
      'Theater Performer',
      'Graphic Artist',
      'Dancer',
      'Visual Artist',
    ],
    'M': [
      'Fashion Designer',
      'Tailor/Dressmaker',
      'Jewelry Designer',
      'Textile Designer',
      'Accessories Maker',
    ],
    'N': [
      'Soldier',
      'Police Officer',
      'Firefighter',
      'Criminologist',
      'Coast Guard Officer',
      'Security Officer',
    ],
    'O': [
      'Priest',
      'Pastor',
      'Religious Brother/Sister',
      'Missionary',
      'Charity Worker',
    ],
  };

  // Style helpers
  Color _levelColor(String level) {
    switch (level) {
      case 'HP':
        return Colors.green.shade600;
      case 'MP':
        return Colors.orange.shade600;
      case 'LP':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'HP':
        return Icons.star;
      case 'MP':
        return Icons.trending_up;
      case 'LP':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  // Bar chart builder
  List<BarChartGroupData> _buildBarChartData() {
    return results.asMap().entries.map((entry) {
      final idx = entry.key;
      final data = entry.value;
      final pct = double.tryParse(data['percentage'].toString()) ?? 0.0;

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: pct,
            color: _levelColor(data['level']),
            width: 20,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildBarChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          maxY: 100,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine:
                (_) => const FlLine(color: Colors.grey, strokeWidth: 0.3),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 28,
                getTitlesWidget:
                    (v, _) => Text(
                      '${v.toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, _) {
                  final i = x.toInt();
                  if (i < results.length) {
                    final categoryKey = results[i]['category'].toString();
                    final label =
                        shortCategoryNames[categoryKey] ?? categoryKey;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarChartData(),
        ),
      ),
    );
  }

  // Top 3 Preferences section
  Widget _buildTop3Preferences() {
    final top3 = results.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 3 Preferences',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children:
              top3.map((res) {
                final color = _levelColor(res['level']);
                final categoryKey = res['category'].toString();
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(_levelIcon(res['level']), color: color),
                    ),
                    title: Text(
                      "${res['rank']}. ${categoryNames[categoryKey] ?? categoryKey}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Score: ${res['score']} | ${res['percentage']}% | Level: ${res['level']}",
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // Summary table (NCAE-style)
  Widget _buildSummaryTable() {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
      columns: const [
        DataColumn(label: Text("Category")),
        DataColumn(label: Text("Score")),
        DataColumn(label: Text("%")),
        DataColumn(label: Text("Rank")),
      ],
      rows:
          results.map((res) {
            final categoryKey = res['category'].toString();
            return DataRow(
              cells: [
                DataCell(Text(categoryNames[categoryKey] ?? categoryKey)),
                DataCell(Text(res['score'].toString())),
                DataCell(Text("${res['percentage']}%")),
                DataCell(Text(res['rank'].toString())),
              ],
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3EB6FF),
        elevation: 0,
        title: const Text(
          'Your Assessment Results',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTop3Preferences(),
            const SizedBox(height: 24),
            const Text(
              'Top Strengths (Chart View)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 24),
            const Text(
              'Summary Table (All Categories)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: _buildSummaryTable())),
          ],
        ),
      ),
    );
  }
}
