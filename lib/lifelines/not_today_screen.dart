import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:anxiety_anchor/widgets/emergency_crisis_sheet.dart';
import 'package:anxiety_anchor/widgets/not_today_bridge.dart';
import 'package:anxiety_anchor/widgets/not_today_sheet.dart';
import 'package:anxiety_anchor/lifelines/lifeline_registry.dart';

class _ScriptGroup {
  const _ScriptGroup({required this.title, required this.scripts});
  final String title;
  final List<String> scripts;
}

/// RESOURCES_SURFACE: ASMR / External / Boundary / Knowledge (operational IA).
class NotTodayScreen extends StatefulWidget {
  const NotTodayScreen({super.key});

  @override
  State<NotTodayScreen> createState() => _NotTodayScreenState();
}

class _NotTodayScreenState extends State<NotTodayScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _quickScriptsKey = GlobalKey();
  final GlobalKey _fullScriptsKey = GlobalKey();

  static const List<String> _quickRefusalScripts = [
    "Hi [Name],\n\nI need to step away today and won't be available. I'll follow up when I can.\n\nBest,\n[Your Name]",
    "Hi [Name],\n\nI'm not able to join or respond right now. Thank you for understanding.\n\nBest,\n[Your Name]",
    "Hi [Name],\n\nI'm at capacity and need to prioritize recovery. I'll reconnect when I'm steady.\n\nBest,\n[Your Name]",
  ];

  static const List<_ScriptGroup> _scriptGroups = [
    _ScriptGroup(
      title: '💼 Work & Professional',
      scripts: [
        "Hi [Name],\n\nI am feeling unwell today and need to step away from my desk. I will check in when I'm able.\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nI'm at capacity and need to prioritize my health right now. I won't be able to join the meeting.\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nI need to take a personal health day today. I'll be back as soon as I can.\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nI'm currently unavailable due to a health matter. I'll respond to urgent items when I return.\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nI need to step away for the remainder of the day. Thank you for understanding.\n\nBest,\n[Your Name]",
      ],
    ),
    _ScriptGroup(
      title: '🤝 Friends & Perimeter',
      scripts: [
        "Hi [Name],\n\nI'm hitting a wall and need to go dark for a bit to reset. I'm safe, just offline. Catch you when I'm back.\n\nBest,\n[Your Name]",
        'Hi [Name],\n\nI\'m having a hard time today and need some space to recharge. Let\'s catch up another time.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m offline today, but I appreciate you reaching out. I\'ll text you soon.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI need to take a raincheck on our plans. I\'m just not feeling up to it right now.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nMy interaction capacity is low today. I\'m going to stay in and rest.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m focusing on some self-care today, so I\'ll be off my phone for a bit.\n\nBest,\n[Your Name]',
      ],
    ),
    _ScriptGroup(
      title: '🏠 Family',
      scripts: [
        "Hi [Name],\n\nJust a heads up that I'm activating my recovery protocol. I won't be checking my phone for the next few hours. I'll check in once I'm stabilized.\n\nBest,\n[Your Name]",
        'Hi [Name],\n\nI need a quiet day today. I\'ll call you when I\'m feeling a bit more up to talking.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m taking a mental health break today. I\'m safe, just need some alone time.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m not up for visitors or long calls today. I\'ll check in with you tomorrow.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m feeling a bit overwhelmed and need to rest. I love you, talk soon.\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m staying off the grid today to clear my head. Talk soon!\n\nBest,\n[Your Name]',
      ],
    ),
    _ScriptGroup(
      title: '🗓️ Non-Work Engagements',
      scripts: [
        "Hi [Name],\n\nI won't be able to make the event today. I need to focus on resting and recovering.\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nSomething came up and I need to prioritize my health, so I can't attend.\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nI'm not able to participate in today's plans. I hope you all have a great time!\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nI need to cancel my attendance for today. My apologies for the short notice.\n\nBest,\n[Your Name]",
        "Hi [Name],\n\nI can't make it today. I'm taking some time for myself.\n\nBest,\n[Your Name]",
      ],
    ),
    _ScriptGroup(
      title: '🆘 Seeking Help',
      scripts: [
        'Hi [Name],\n\nI am having a panic attack right now. Can you please check in on me or just stay on the line?\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m really struggling today. Are you free to talk for a few minutes?\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI don\'t feel like myself and I\'m a bit scared. Could you come over or call me?\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m having a hard time grounding myself. Could you help me through a breathing exercise?\n\nBest,\n[Your Name]',
        'Hi [Name],\n\nI\'m feeling very overwhelmed. I just need someone to know I\'m struggling right now.\n\nBest,\n[Your Name]',
      ],
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) ok = await launchUrl(uri);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'NOT TODAY',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          physics: const ClampingScrollPhysics(),
          children: [
            _buildSectionHeader('EXTERNAL LINKS'),
            const SizedBox(height: 8),
            _buildExternalCard(context),
            const SizedBox(height: 24),
            _buildSectionHeader('BOUNDARY SYSTEMS'),
            const SizedBox(height: 8),
            _buildBoundaryTocRow(
              context,
              title: 'NOT TODAY',
              subtitle: 'Quick refusal scripts',
              onTap: () => _scrollTo(_quickScriptsKey),
            ),
            _buildBoundaryTocRow(
              context,
              title: 'REFUSAL SCRIPTS',
              subtitle: 'HR / Insurance / Work templates',
              onTap: () => _scrollTo(_fullScriptsKey),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: _quickScriptsKey,
              child: _buildQuickScriptsBlock(context),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _fullScriptsKey,
              child: _buildFullScriptsSection(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'RobotoMono',
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildExternalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => EmergencyCrisisSheet.show(context),
            icon: const Icon(Icons.emergency, size: 20),
            label: const Text('OPEN ALL CRISIS CHANNELS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          ...LifelineRegistry.externalLinks.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(entry.icon, color: Colors.white70),
              title: Text(entry.label, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                entry.subtitle,
                style: const TextStyle(color: Colors.white60),
              ),
              trailing: const Icon(Icons.open_in_new, color: Colors.white38),
              onTap: () => _launchExternal(Uri.parse(entry.uri)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundaryTocRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
      trailing: const Icon(Icons.vertical_align_bottom, color: Colors.white38),
      onTap: onTap,
    );
  }

  Widget _buildQuickScriptsBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1408),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOT TODAY — QUICK SCRIPTS',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontFamily: 'RobotoMono',
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to open deployment sheet: recipient, preview, copy, send.',
            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...List.generate(_quickRefusalScripts.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => NotTodaySheet.show(
                  context,
                  scriptTemplate: _quickRefusalScripts[i],
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.orange.withOpacity(0.4)),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(12),
                ),
                child: Text(
                  _quickRefusalScripts[i].split('\n').first,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFullScriptsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REFUSAL SCRIPTS',
            style: TextStyle(
              color: Colors.redAccent,
              fontFamily: 'RobotoMono',
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a script to open deployment sheet (inject names, copy, send).',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const NotTodayInsuranceHeader(),
          const SizedBox(height: 8),
          ..._scriptGroups.map((g) => _buildScriptGroup(context, g.title, g.scripts)),
        ],
      ),
    );
  }

  Widget _buildScriptGroup(BuildContext context, String title, List<String> scripts) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ...scripts.map((script) => _buildScriptTile(context, script)),
        ],
      ),
    );
  }

  Widget _buildScriptTile(BuildContext context, String text) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      trailing: const Icon(Icons.open_in_new, color: Colors.orangeAccent, size: 18),
      onTap: () => NotTodaySheet.show(context, scriptTemplate: text),
    );
  }
}
