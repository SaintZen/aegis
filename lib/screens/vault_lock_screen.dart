import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Soft privacy gate for THE VAULT. The vault is local-only, so biometrics are
/// a convenience lock, not a security boundary. This screen must never
/// dead-end: if the platform cannot check biometrics (no enrolment, web /
/// desktop, hardware disabled) or authentication throws, the operator is given
/// an explicit fall-through so the vault can still be reached.
class VaultLockScreen extends StatefulWidget {
  const VaultLockScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  static const Color _aegisSlate = Color(0xFF738678);

  final LocalAuthentication _auth = LocalAuthentication();

  bool _checking = false;
  bool _biometricsUsable = true;
  String? _statusLine;

  @override
  void initState() {
    super.initState();
    // Probe support up front so the fall-through control is offered when the
    // platform can never satisfy a biometric prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) => _probeSupport());
  }

  Future<void> _probeSupport() async {
    final usable = await _biometricsAvailable();
    if (!mounted) return;
    setState(() {
      _biometricsUsable = usable;
      if (!usable) {
        _statusLine = 'Biometrics unavailable on this device.';
      }
    });
  }

  Future<bool> _biometricsAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      // MissingPluginException on web / unsupported platforms lands here.
      return false;
    }
  }

  Future<void> _authenticate() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _statusLine = null;
    });

    if (!await _biometricsAvailable()) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _biometricsUsable = false;
        _statusLine = 'Biometrics unavailable on this device.';
      });
      return;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'AUTHENTICATE TO ACCESS VAULT',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!mounted) return;
      if (didAuthenticate) {
        widget.onAuthenticated();
        return;
      }
      setState(() {
        _checking = false;
        _biometricsUsable = false;
        _statusLine = 'Authentication cancelled.';
      });
    } catch (e) {
      // Surface the failure and expose the fall-through instead of silently
      // stranding the operator behind a lock that can never open.
      if (!mounted) return;
      setState(() {
        _checking = false;
        _biometricsUsable = false;
        _statusLine = 'Biometric lock unavailable.';
      });
    }
  }

  void _proceedWithoutBiometrics() {
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              color: _aegisSlate,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'THE VAULT IS SECURE',
              style: TextStyle(letterSpacing: 4, color: Colors.white),
            ),
            const SizedBox(height: 8),
            if (_checking)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _aegisSlate,
                  ),
                ),
              )
            else ...[
              TextButton(
                onPressed: _authenticate,
                child: const Text(
                  'UNLOCK',
                  style: TextStyle(color: _aegisSlate, letterSpacing: 2),
                ),
              ),
              // Never a dead-end: when biometrics cannot be used, offer an
              // explicit way into the (local-only) vault.
              if (!_biometricsUsable)
                TextButton(
                  onPressed: _proceedWithoutBiometrics,
                  child: const Text(
                    'CONTINUE WITHOUT BIOMETRICS',
                    style: TextStyle(
                      color: Colors.white54,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            if (_statusLine != null) ...[
              const SizedBox(height: 6),
              Text(
                _statusLine!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
