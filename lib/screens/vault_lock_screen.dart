import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class VaultLockScreen extends StatelessWidget {
  const VaultLockScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  Future<void> _checkBiometrics(BuildContext context) async {
    final auth = LocalAuthentication();
    try {
      final canAuthenticate = await auth.canCheckBiometrics;
      if (canAuthenticate) {
        final didAuthenticate = await auth.authenticate(
          localizedReason: 'AUTHENTICATE TO ACCESS VAULT',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (didAuthenticate) {
          onAuthenticated();
        }
      }
    } catch (e) {
      // TODO: add PIN/passcode fallback if needed.
    }
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
              color: Color(0xFF738678),
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'THE VAULT IS SECURE',
              style: TextStyle(letterSpacing: 4, color: Colors.white),
            ),
            TextButton(
              onPressed: () => _checkBiometrics(context),
              child: const Text(
                'UNLOCK',
                style: TextStyle(color: Color(0xFF738678)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
