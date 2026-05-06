import 'package:flutter/material.dart';

import 'package:anxiety_anchor/models/resource_article.dart';

/// An Intelligence Briefing: a collection of articles with a card entry.
class ResourceBriefing {
  const ResourceBriefing({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.articles,
    this.dialogTitle,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<ResourceArticle> articles;
  /// Optional: use when dialog title should differ from card title.
  final String? dialogTitle;
}
