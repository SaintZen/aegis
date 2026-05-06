import 'package:flutter/material.dart';

/// Lifeline registry for recovered ASMR, audio, and external contact pathways.
class LifelineRegistry {
  LifelineRegistry._();

  static const List<LifelineRoute> asmrAndAudioRoutes = [
    LifelineRoute(
      label: 'ASMR PHARMACY',
      subtitle: 'Immediate sensory triggers',
      icon: Icons.graphic_eq,
      route: '/pharmacy',
    ),
    LifelineRoute(
      label: 'AUDIO LIBRARY',
      subtitle: 'Ambient regulation tracks',
      icon: Icons.library_music_outlined,
      route: '/audio-library',
    ),
    LifelineRoute(
      label: 'KINETIC VOICE',
      subtitle: 'Guided body-intervention drills',
      icon: Icons.record_voice_over_outlined,
      route: '/kinetic-voice',
    ),
  ];

  static const List<LifelineLink> externalLinks = [
    LifelineLink(
      label: 'CALL 988',
      subtitle: 'US Crisis Lifeline',
      uri: 'tel:988',
      icon: Icons.phone_in_talk,
    ),
    LifelineLink(
      label: 'TEXT 741741',
      subtitle: 'Crisis Text Line',
      uri: 'sms:741741?body=HOME',
      icon: Icons.sms_outlined,
    ),
    LifelineLink(
      label: 'NEAREST ER',
      subtitle: 'Locate emergency room',
      uri: 'https://www.google.com/maps/search/er+near+me',
      icon: Icons.local_hospital_outlined,
    ),
  ];
}

class LifelineRoute {
  const LifelineRoute({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
}

class LifelineLink {
  const LifelineLink({
    required this.label,
    required this.subtitle,
    required this.uri,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final String uri;
  final IconData icon;
}
