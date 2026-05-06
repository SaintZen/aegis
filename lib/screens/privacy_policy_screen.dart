import 'package:flutter/material.dart';

/// Operator-facing privacy summary — replace with counsel-approved policy if required.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'PRIVACY',
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
            Text('OVERVIEW', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'This application is designed to keep operational and personal data on your device by default. '
              'Review each section below for how information may be stored, exported, or shared when you choose.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('LOCAL STORAGE', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'Logs, vault entries, calibration preferences, and similar data are stored locally using device '
              'storage (e.g. shared preferences, files). They are not uploaded to our servers by the app itself.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('EXPORTS & SHARING', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'When you print, export PDFs, share files, or open external links, data leaves the app under your '
              'control. You decide what to send and to whom.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('THIRD PARTIES', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'Opening websites or crisis hotlines uses your system browser or dialer. Those services have their '
              'own privacy practices. The app does not embed third-party analytics in this build unless you add them.',
              style: _bodyStyle,
            ),
            SizedBox(height: 20),
            Text('CHANGES', style: _headingStyle),
            SizedBox(height: 8),
            Text(
              'This summary may be updated. Check the in-app privacy screen after app updates for the latest text.',
              style: _bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}
