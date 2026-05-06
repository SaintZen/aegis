import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openMail(BuildContext context, String address) async {
  final uri = Uri(scheme: 'mailto', path: address);
  try {
    var ok = await launchUrl(uri);
    if (!ok) ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open mail client for $address'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open mail: $address'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.mailto,
  });

  final String title;
  final String subtitle;
  final String? mailto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: mailto != null,
      label: mailto != null ? '$title, tap to email' : title,
      child: InkWell(
        onTap: mailto != null ? () => _openMail(context, mailto!) : null,
        splashColor: Colors.white10,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'RobotoMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
