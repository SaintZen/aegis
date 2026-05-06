import 'package:flutter/material.dart';

import 'package:anxiety_anchor/widgets/affirmations_library.dart';

class AffirmationsScreen extends StatelessWidget {
  const AffirmationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: AffirmationsLibraryScreen()),
    );
  }
}
