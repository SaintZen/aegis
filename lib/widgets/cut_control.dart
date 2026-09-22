import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anxiety_anchor/scripts/cut_deck.dart';

/// Session memory so sequential CUTs do not land on the same domain.
class CutMemory {
  static String? lastId;
}

Future<void> fireCut(
  BuildContext context, {
  String? currentId,
}) async {
  final target = pickCut(previousId: currentId ?? CutMemory.lastId);
  CutMemory.lastId = target.id;
  HapticFeedback.heavyImpact();
  if (!context.mounted) return;
  await Navigator.of(context).pushNamed(
    target.route,
    arguments: target.arguments,
  );
}

/// High-contrast loop cut. First use and continuous use.
class CutControl extends StatelessWidget {
  const CutControl({
    super.key,
    this.currentId,
    this.compact = false,
  });

  final String? currentId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(vertical: 12);
    return GestureDetector(
      key: const Key('aegis_cut'),
      onTap: () => fireCut(context, currentId: currentId),
      child: Container(
        width: compact ? null : double.infinity,
        padding: pad,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: compact ? 1 : 2),
        ),
        child: Text(
          '[ CUT ]',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 12 : 16,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 1.4 : 2.2,
            fontFamily: 'RobotoMono',
          ),
        ),
      ),
    );
  }
}
