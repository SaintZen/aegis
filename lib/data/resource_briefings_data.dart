import 'package:flutter/material.dart';

import 'package:anxiety_anchor/models/resource_article.dart';
import 'package:anxiety_anchor/models/resource_briefing.dart';

import 'package:anxiety_anchor/data/clinical_intelligence.dart';

/// Static Intelligence Briefings. Add new briefings here.
final List<ResourceBriefing> resourceBriefings = [
  ClinicalIntelligence.foundationBriefing,
  ResourceBriefing(
    id: 'tactical_matrix',
    title: 'Tactical Matrix',
    subtitle: 'Signal-to-Tool Mapping',
    icon: Icons.grid_on_outlined,
    articles: [
      const ResourceArticle(
        title: 'Signal-to-Tool Mapping',
        body:
            'Match your current state to the appropriate tool. Users have '
            'reported that this helps with rapid stabilization.',
        quickActions: [
          QuickActionRow(
            state: 'Physical Heat / Rapid Pulse',
            tool: 'The Frost: Triggers the \'Dive Reflex\' to force heart rate reduction.',
          ),
          QuickActionRow(
            state: 'Heavy Limbs / \'Ghost\' Sensations',
            tool: 'The Hollow: Uses 60 BPM entrainment to overwrite somatic echoes.',
          ),
          QuickActionRow(
            state: 'Mental Static / Looping Thoughts',
            tool: 'The Void: Offloads working memory to clear the prefrontal cortex.',
          ),
          QuickActionRow(
            state: 'Complete Disconnection (Dissociation)',
            tool: 'Anchor Me Now: Provides a high-contrast visual and rhythmic pillar to pull you back to the present.',
          ),
        ],
      ),
    ],
  ),
  ResourceBriefing(
    id: 'institutional',
    title: 'Institutional Protocol',
    subtitle: 'System Framework for organizations',
    icon: Icons.shield_outlined,
    articles: [
      const ResourceArticle(
        title: 'System Framework Overview',
        body:
            'This framework is offered as an organizational lens—not a technical '
            'requirement. Use it to structure team support and policy, not to '
            'diagnose or treat individuals.',
      ),
      const ResourceArticle(
        title: 'Executive Function Brownout',
        body:
            'The theory: Acute stress can trigger an Amygdala Hijack that '
            'shuts down the Prefrontal Cortex. Organizations have reported this '
            'creates poor decision-making, communication breakdowns, and '
            'liability exposure in critical moments.',
      ),
      const ResourceArticle(
        title: 'Tactical Sovereignty',
        body:
            'Users have reported that somatic resets, visual anchors, and '
            'administrative defense help return to an operational baseline. These '
            'tools are offered as a framework—not a biometric or technical protocol.',
      ),
      const ResourceArticle(
        title: 'The Black Box Privacy',
        body:
            'Zero-Knowledge Architecture and local-only encryption keep activity '
            'invisible to IT, HR, and Management. This framework emphasizes '
            'surveillance reduction and user sovereignty.',
      ),
    ],
  ),
  ResourceBriefing(
    id: 'glossary',
    title: 'Glossary',
    subtitle: 'Signal Management Reference',
    icon: Icons.menu_book_outlined,
    articles: [
      const ResourceArticle(
        title: 'The Signal Processing Model',
        body:
            'The premise: Anxiety may reflect a misfiring of the '
            'signal-to-receptor pathway—not a shortage of chemicals. The brain '
            'sends messages that can get amplified or distorted before they '
            'reach their target.',
      ),
      const ResourceArticle(
        title: 'The Somatic Echo (1972 Protocol)',
        body:
            'A non-linear event where the nervous system triggers a '
            'high-fidelity physical sensation (warmth, heaviness, or '
            'longing) tied to a distant temporal coordinate.',
      ),
      const ResourceArticle(
        title: 'The Mechanism',
        body:
            'The theory: The brain bypasses the visual cortex (the "mental '
            'image") and goes straight to the amygdala and gut. You don\'t '
            '"see" the past; you wear it.',
      ),
      const ResourceArticle(
        title: 'The Price',
        body:
            'The weight of what was lost, or the static of a future '
            'that feels unwritten.',
      ),
      const ResourceArticle(
        title: 'Operator Action',
        body:
            'If the Echo feels like a "Scrape," use the Void. '
            'If the Echo feels like "Gravity," engage the Phantom '
            'Scan to anchor the sensation in the present.',
      ),
      const ResourceArticle(
        title: 'The Phantom',
        body: 'Body echoes of stress (tight chest, tremors).',
      ),
      const ResourceArticle(
        title: 'The Hollow',
        body: 'Looping thoughts that won\'t stop.',
      ),
      const ResourceArticle(
        title: 'The Hold',
        body: 'Slow the body on purpose to calm the system.',
      ),
      const ResourceArticle(
        title: 'The Scraper',
        body: 'Pull away from intrusive thoughts.',
      ),
      const ResourceArticle(
        title: 'The Shield',
        body: 'Words and steps for HR/insurance pressure.',
      ),
      const ResourceArticle(
        title: 'The Frost',
        body: 'Long-term stress buildup in the body.',
      ),
      const ResourceArticle(
        title: 'Field Use',
        body: 'Trash Dump → Cognitive Defusion',
      ),
      const ResourceArticle(
        title: 'Emergency',
        body: 'The Hold → Vagal Nerve Entrainment',
      ),
      const ResourceArticle(
        title: 'Professional Audit',
        body: 'Status → Psychophysiological Metrics',
      ),
    ],
  ),
  ResourceBriefing(
    id: 'lab_tools',
    title: 'Grounding Lab',
    subtitle: 'Why each tool works',
    icon: Icons.science_outlined,
    dialogTitle: 'Grounding Lab — Why It Works',
    articles: [
      const ResourceArticle(
        title: 'The Void',
        body:
            'The premise: Discarding thoughts may reduce cognitive load. '
            'Users have reported that when you release a worry into the Void, '
            'you\'re offloading it from working memory so the prefrontal '
            'cortex can breathe.',
      ),
      const ResourceArticle(
        title: 'The Frost',
        body:
            'The theory: Cold exposure may help reset the Vagus Nerve. Users '
            'have reported that the scrape triggers the dive reflex, slowing '
            'heart rate and shifting the nervous system from fight-or-flight '
            'to rest-and-digest.',
      ),
      const ResourceArticle(
        title: 'The Hollow',
        body:
            'Users have reported that 60 BPM thrums help stabilize somatic '
            'echoes. The steady 1 Hz tactile pulse may entrain the body\'s '
            'rhythm, grounding looping thoughts and phantom sensations in '
            'the present moment.',
      ),
    ],
  ),
  ResourceBriefing(
    id: 'dmn_briefing',
    title: 'The Default Mode Network',
    subtitle: 'The "Mind-Wandering" Circuit',
    icon: Icons.psychology_outlined,
    articles: [
      const ResourceArticle(
        title: 'The Ghost in the Machine',
        body:
            'The DMN is a network of brain regions that becomes active when '
            'you aren\'t focused on the outside world. It is the home of '
            '"time travel"—where the brain ruminates on the past or worries '
            'about the future.',
      ),
      const ResourceArticle(
        title: 'Decoupling the DMN',
        body:
            'The theory: The Lab tools (Frost, Hollow, Void) may help '
            '"decouple" the DMN by directing the brain toward Intense Sensory '
            'Input. Users have reported this can switch attention back into the '
            'Task-Positive Network.',
      ),
    ],
  ),
  ResourceBriefing(
    id: 'silent_alerts',
    title: 'Silent Alerts',
    subtitle: 'Intel cues for vaults and scrapers',
    icon: Icons.notifications_off_outlined,
    articles: [
      const ResourceArticle(
        title: 'The Tight Jaw',
        body:
            "Users have reported that the Frost Scraper helps focus on somatic release.",
      ),
      const ResourceArticle(
        title: 'Indecision Paralysis',
        body:
            "Users have reported that the Worry Vault helps store choices for "
            "4 hours, reducing decision load.",
      ),
      const ResourceArticle(
        title: 'Sensory Overload',
        body:
            "Users have reported that the Pulse with headphones helps drown "
            "out external noise.",
      ),
    ],
  ),
  ResourceBriefing(
    id: 'crisis_resources',
    title: 'Emergency Support',
    subtitle: 'Professional Human Assistance',
    icon: Icons.emergency_outlined,
    articles: [
      const ResourceArticle(
        title: 'When the Anchor isn\'t enough',
        body:
            'When the Anchor isn\'t enough, reach out to a professional.\n\n'
            '• US: 988 — Suicide & Crisis Lifeline (call or text)\n'
            '• UK: 111 — NHS non-emergency; option 2 for mental health crisis\n'
            '• UK: 116 123 — Samaritans (24/7)\n'
            '• Global: https://findahelpline.com — Crisis helplines by country',
      ),
    ],
  ),
];
