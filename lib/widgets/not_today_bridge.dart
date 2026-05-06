import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotTodayInsuranceHeader extends StatelessWidget {
  const NotTodayInsuranceHeader({super.key});

  static final Uri _commissionerUrl =
      Uri.parse('https://content.naic.org/state-insurance-departments');

  Future<void> _openCommissionerSite() async {
    await launchUrl(_commissionerUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧾 HR / Insurance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Note: Insurance laws vary by state. Consult your State '
            'Insurance Commissioner for local statutory requirements.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _openCommissionerSite,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF738678),
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(letterSpacing: 0.3),
            ),
            child: const Text('Find My State Commissioner'),
          ),
        ],
      ),
    );
  }
}
