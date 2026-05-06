import 'package:flutter/material.dart';

import 'package:anxiety_anchor/screens/calibration_screen.dart';

const Color _aegisOrange = Color(0xFFFF8C00);

/// Under the Maintenance / Ledger header strip: disclaimer + link to full text.
Widget _buildMaintenanceDisclaimer(BuildContext ctx) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'This is a maintenance console, not a clinical service. Data here is technical and may be retained for audit.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontFamily: 'RobotoMono',
                      height: 1.35,
                    ) ??
                    const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'RobotoMono',
                      fontSize: 12,
                      height: 1.35,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _showMaintenanceModal(ctx),
              style: TextButton.styleFrom(
                foregroundColor: _aegisOrange,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Read full disclaimer',
                style: TextStyle(
                  color: _aegisOrange,
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}

void _showMaintenanceModal(BuildContext ctx) {
  showDialog<void>(
    context: ctx,
    builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Maintenance and Audit Disclaimer',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'RobotoMono',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          'This Maintenance / Ledger area is a technical operations console for system calibration, diagnostics, and audit exports. '
          'It is not intended to provide medical, mental‑health, legal, or clinical advice. Content and actions in this area are primarily technical and may be retained in system logs for compliance and troubleshooting. '
          'By using these tools you acknowledge that: \n\n'
          '- This interface does not replace professional care.\n'
          '- Any notes, exports, or ledger entries created here may be included in technical audit artifacts.\n'
          '- Some actions are irreversible; review prompts carefully before confirming.\n\n'
          'If you need clinical or emergency help, contact a licensed provider or emergency services. For privacy questions, see our Privacy Policy.',
          style: Theme.of(c).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontFamily: 'RobotoMono',
                height: 1.4,
              ) ??
              const TextStyle(
                color: Colors.white70,
                fontFamily: 'RobotoMono',
                fontSize: 12,
                height: 1.4,
              ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(),
          child: const Text(
            'Close',
            style: TextStyle(
              color: _aegisOrange,
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
      ],
    ),
  );
}

/// Maintenance / Ledger: calibration only (haptics, audio, PDF, safety).
/// Not Today, ASMR, Dictionary, and Advocacy live on [BridgeScreen].
class BridgeMaintenanceLedgerScreen extends StatelessWidget {
  const BridgeMaintenanceLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        // Title lives on the orange strip below — avoids duplicate with [CalibrationScreen] (embedded has no app bar).
        title: const SizedBox.shrink(),
        toolbarHeight: kToolbarHeight,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: _aegisOrange,
            elevation: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              child: const Text(
                'MAINTENANCE / LEDGER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          _buildMaintenanceDisclaimer(context),
          const Expanded(
            child: CalibrationScreen(embedded: true),
          ),
        ],
      ),
    );
  }
}
