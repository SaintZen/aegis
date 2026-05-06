import 'package:flutter/material.dart';

import 'package:anxiety_anchor/models/resource_article.dart';
import 'package:anxiety_anchor/models/resource_briefing.dart';

/// Foundation content: The Hardware, The Ghost Signal, The Aegis.
/// User-manual tone: System Calibration and Signal Management.
class ClinicalIntelligence {
  ClinicalIntelligence._();

  static const _section01 = ResourceArticle(
    title: '01: The Hardware → [The Engine]',
    body:
        'Neuro-Chemical Signal Processing. Managing the input/output of the '
        'nervous system to prevent signal-flooding.',
  );

  static const _section02 = ResourceArticle(
    title: '02: The Ghost → [Somatic Echoes]',
    body:
        'Somatic Echoes. Latent physical responses to historical stressors that '
        'bypass cognitive filters.',
  );

  static const _section03 = ResourceArticle(
    title: '03: The Aegis → [The Protocol]',
    body:
        'Intervention Protocols. Direct sensory overrides for specific autonomic '
        'states.\n\n'
        'The Void: Purges working memory to lower cognitive heat.\n\n'
        'The Frost: Triggers a thermal override of the Vagus nerve.\n\n'
        'The Hollow: Uses frequency entrainment to stabilize a racing pulse.',
    quickActions: [
      QuickActionRow(
        state: 'Racing Heart/Heat',
        tool: 'The Frost (Vagal Recalibration)',
      ),
      QuickActionRow(
        state: 'Looping Memories/Phantom Weight',
        tool: 'The Hollow (Somatic Entrainment)',
      ),
      QuickActionRow(
        state: 'Signal Noise/Crowded Thought',
        tool: 'The Void (Cognitive Offload)',
      ),
      QuickActionRow(
        state: 'Panic/Loss of Center',
        tool: 'Anchor Me Now (Stabilization Pillar)',
      ),
    ],
  );

  /// Foundation articles. Add Section 04 here.
  static List<ResourceArticle> get foundationArticles => [
        _section01,
        _section02,
        _section03,
      ];

  static ResourceBriefing get foundationBriefing => ResourceBriefing(
        id: 'foundation',
        title: 'Foundation',
        subtitle: 'System Calibration & Signal Management',
        icon: Icons.layers_outlined,
        articles: foundationArticles,
      );
}
