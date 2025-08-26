import 'package:flutter/material.dart';
import 'questionnaire_screen.dart';

class QuestionnaireIntroScreen extends StatelessWidget {
  const QuestionnaireIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFF),
      body: Column(
        children: [
          // Custom rounded header
          Container(
            padding: const EdgeInsets.only(
              top: 40, // status bar + some breathing room
              left: 16,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF3EB6FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Title
                const Text(
                  'Assessment Intro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Body content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    height: 80,
                    color: const Color(0xFF3EB6FF), // tinted to match
                    colorBlendMode: BlendMode.srcIn,
                  ),

                  const SizedBox(height: 30),

                  // Heading
                  const Text(
                    'Welcome to the Pre-Assessment!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'TT Rounds Neue Bold',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Before we get started, we’ll ask you a few short questions to better understand your background and readiness for the NCAE. This should only take a few minutes.',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'TT Rounds Neue Regular',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuestionnaireScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3EB6FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Assessment',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
