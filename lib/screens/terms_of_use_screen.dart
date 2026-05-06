import 'package:flutter/material.dart';

/// Operator-facing terms; not clinical or legal advice — replace body copy with counsel-approved text if required.
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  static const TextStyle _bodyStyle = TextStyle(
    color: Colors.white70,
    fontFamily: 'RobotoMono',
    fontSize: 12,
    height: 1.45,
  );

  static const TextStyle _headingStyle = TextStyle(
    color: Colors.white,
    fontFamily: 'RobotoMono',
    fontSize: 11,
    letterSpacing: 1.0,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'TERMS OF USE',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: const [
            Text('ACCEPTANCE', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'By using this application you agree to these terms. If you do not agree, do not use the app.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('STABILIZATION ONLY', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'This software is a self-directed stabilization and logging instrument. It is not medical care, '
              'therapy, diagnosis, or treatment. It does not replace a licensed professional or emergency services.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('USE OF THE APP', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'You are responsible for how you use audio, haptics, and exercises. Stop if you experience pain, '
              'severe dizziness, or other adverse effects. For emergencies, contact local emergency services.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('DATA & PRIVACY', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'Local data stays on your device unless you export or share it. You control what is stored and printed.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('LIMITATION OF LIABILITY', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'To the maximum extent permitted by law, the authors and distributors of this app are not liable for '
              'any damages arising from use or inability to use the software.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('CHANGES', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'These terms may be updated. Continued use after changes constitutes acceptance of the revised terms.',
              style: _bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}
