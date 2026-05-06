import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/models/vault_model.dart';

/// Pre-timer intake: full signal capture before seal. Aegis industrial layout.
const Color _aegisOrange = Color(0xFFFF8C00);

class VaultIntakePanel extends StatelessWidget {
  const VaultIntakePanel({
    super.key,
    required this.controller,
    required this.onSeal,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSeal;
  final bool enabled;

  static int get _lockHours =>
      VaultEntry.defaultLockDuration.inHours > 0
          ? VaultEntry.defaultLockDuration.inHours
          : 24;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF001220),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                color: _aegisOrange,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VAULT INTAKE',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'RobotoMono',
                        fontSize: 11,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'What are you locking away?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontFamily: 'RobotoMono',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Signal input · ${_lockHours}h seal · 8h reflection before audit retention',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontFamily: 'RobotoMono',
                        fontSize: 10,
                        letterSpacing: 0.3,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 6,
            minLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              fontSize: 14,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText:
                  'Type the full signal here. Text is preserved verbatim for the vault record.',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.28),
                fontFamily: 'RobotoMono',
                fontSize: 13,
                height: 1.4,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.45),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFF2A3A48)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFF2A3A48)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: enabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      onSeal();
                    }
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: _aegisOrange,
                disabledForegroundColor: Colors.black38,
                disabledBackgroundColor: Colors.white12,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'SEAL VAULT',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 13,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
