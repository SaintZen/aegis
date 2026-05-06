import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

enum SystemClearResult { yes, no, timeout }

class SystemClearPopup extends StatefulWidget {
  const SystemClearPopup({super.key});

  @override
  State<SystemClearPopup> createState() => _SystemClearPopupState();
}

class _SystemClearPopupState extends State<SystemClearPopup> {
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.of(context).pop(SystemClearResult.timeout);
      }
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SYSTEM CLEAR?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'YES',
                        glow: const Color(0xFF00FFFF),
                        onTap: () => Navigator.of(context).pop(
                          SystemClearResult.yes,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: 'NO',
                        glow: const Color(0xFFFFBF00),
                        onTap: () => Navigator.of(context).pop(
                          SystemClearResult.no,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color glow,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glow.withOpacity(0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }
}
