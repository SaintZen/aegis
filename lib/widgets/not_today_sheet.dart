import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:anxiety_anchor/services/boundary_identity_service.dart';

/// NOT_TODAY_SHEET — Aegis-flat bottom surface; name editable only in Settings (Bridge).
class NotTodaySheet {
  NotTodaySheet._();

  static Future<void> show(
    BuildContext context, {
    required String scriptTemplate,
  }) async {
    final yourName = await BoundaryIdentityService.getDisplayName();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: const Color(0xDD000000),
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      builder: (ctx) {
        final viewInsets = MediaQuery.viewInsetsOf(ctx).bottom;
        final h = MediaQuery.sizeOf(ctx).height * 0.6;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: h,
              width: double.infinity,
              child: Material(
                color: const Color(0xFF0A0A0A),
                elevation: 0,
                shadowColor: Colors.transparent,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
                    ),
                  ),
                  child: _NotTodaySheetBody(
                    scriptTemplate: scriptTemplate,
                    yourName: yourName,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String injectScript(
    String template,
    String recipient,
    String yourName,
  ) {
    final r = recipient.trim().isEmpty ? '[Name]' : recipient.trim();
    final y = yourName.trim().isEmpty ? '[Your Name]' : yourName.trim();
    return template.replaceAll('[Name]', r).replaceAll('[Your Name]', y);
  }
}

class _NotTodaySheetBody extends StatefulWidget {
  const _NotTodaySheetBody({
    required this.scriptTemplate,
    required this.yourName,
  });

  final String scriptTemplate;
  final String yourName;

  @override
  State<_NotTodaySheetBody> createState() => _NotTodaySheetBodyState();
}

class _NotTodaySheetBodyState extends State<_NotTodaySheetBody> {
  final TextEditingController _recipient = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recipient.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recipient.dispose();
    super.dispose();
  }

  bool get _recipientOk => _recipient.text.trim().isNotEmpty;

  String get _preview => NotTodaySheet.injectScript(
        widget.scriptTemplate,
        _recipient.text,
        widget.yourName,
      );

  Future<void> _copy() async {
    if (!_recipientOk) return;
    await Clipboard.setData(ClipboardData(text: _preview));
    HapticFeedback.lightImpact();
  }

  Future<void> _share() async {
    if (!_recipientOk) return;
    await Share.share(_preview);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NOT TODAY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Boundary script deployment',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontFamily: 'RobotoMono',
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'RECIPIENT NAME',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'RobotoMono',
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _recipient,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Enter name',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontFamily: 'RobotoMono',
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3A3A3A)),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3A3A3A)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF5A5A5A)),
              ),
              contentPadding: const EdgeInsets.only(bottom: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'YOUR NAME',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'RobotoMono',
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.yourName.isEmpty ? '— not set in Settings —' : widget.yourName,
            style: TextStyle(
              color: widget.yourName.isEmpty
                  ? Colors.white38
                  : Colors.white70,
              fontFamily: 'RobotoMono',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'SCRIPT PREVIEW',
            style: TextStyle(
              color: Colors.white38,
              fontFamily: 'RobotoMono',
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _preview,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'RobotoMono',
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _recipientOk ? _copy : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001220),
                disabledBackgroundColor: const Color(0xFF001220),
                disabledForegroundColor: Colors.white30,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(
                'COPY',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: _recipientOk ? _share : null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60,
              ),
              child: const Text(
                'SEND VIA…',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
