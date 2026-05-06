import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LaunchCallback = Future<void> Function(BuildContext context, String url);

const Set<String> _allowedSchemes = {'http', 'https', 'tel', 'sms'};

/// Opens [url] in an external handler (browser, dialer, or SMS app).
///
/// Accepted schemes: `http`, `https`, `tel`, `sms`. Any other scheme is a no-op.
/// Shows a generic snackbar on failure.
Future<void> launchUrlHelper(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !_allowedSchemes.contains(uri.scheme)) {
    return;
  }
  try {
    var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }
}
