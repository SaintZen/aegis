import 'package:flutter/material.dart';

import 'package:anxiety_anchor/services/local_sovereignty.dart';
import 'package:anxiety_anchor/widgets/branded_anchor.dart';

/// Full-screen cover shown while the app is not in the foreground so
/// App Switcher / snapshot previews cannot capture Hollow, Vault, or
/// Four Gates surfaces.
class SovereigntyVeil extends StatelessWidget {
  const SovereigntyVeil({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return const ColoredBox(
      color: Color(0xFF000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandedAnchor(size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'AEGIS',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'RobotoMono',
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Observes lifecycle, reseals iOS backup exclusion on resume, and
/// paints [SovereigntyVeil] while inactive / paused / hidden.
class SovereigntyShell extends StatefulWidget {
  const SovereigntyShell({super.key, required this.child});

  final Widget child;

  @override
  State<SovereigntyShell> createState() => _SovereigntyShellState();
}

class _SovereigntyShellState extends State<SovereigntyShell>
    with WidgetsBindingObserver {
  bool _veiled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sync(WidgetsBinding.instance.lifecycleState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sync(state);
    if (state == AppLifecycleState.resumed) {
      LocalSovereignty.seal();
    }
  }

  void _sync(AppLifecycleState? state) {
    final hide = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    if (hide == _veiled) return;
    setState(() => _veiled = hide);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        SovereigntyVeil(visible: _veiled),
      ],
    );
  }
}

/// Scheduler binding helper so tests can drive lifecycle without a
/// full [WidgetsBindingObserver] pump. Not used in production.
@visibleForTesting
bool sovereigntyVeilForState(AppLifecycleState state) {
  return state == AppLifecycleState.inactive ||
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.hidden;
}
